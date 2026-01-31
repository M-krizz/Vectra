import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import Redis from 'ioredis';
import { WeeklySchedule } from './entities/weekly-schedule.entity';
import { TimeOff } from './entities/timeoff.entity';
import { DriverProfile } from '../users/driver-profile.entity';
import { UsersService } from '../users/users.service';
import { parse } from 'date-fns';

@Injectable()
export class AvailabilityService {
  private redis: Redis;
  private readonly PRESENCE_TTL = 30; // seconds
  private readonly logger = new Logger(AvailabilityService.name);

  constructor(
    @InjectRepository(WeeklySchedule) private scheduleRepo: Repository<WeeklySchedule>,
    @InjectRepository(TimeOff) private timeOffRepo: Repository<TimeOff>,
    @InjectRepository(DriverProfile) private profileRepo: Repository<DriverProfile>,
    private usersService: UsersService,
  ) {
    this.redis = new Redis(process.env.REDIS_URL || 'redis://localhost:6379');
  }

  private presenceKey(driverUserId: string) {
    return `driver:presence:${driverUserId}`;
  }

  // Set online/offline (mobile toggles)
  async setOnline(userId: string, online: boolean, deviceInfo?: string) {
    // find driver profile
    const profile = await this.profileRepo.findOne({ where: { user: { id: userId } }, relations: ['user'] });
    if (!profile) throw new NotFoundException('Driver profile not found');

    const key = this.presenceKey(profile.user.id);
    if (online) {
      // set presence with TTL; mobile should keep sending heartbeats
      await this.redis.setex(key, this.PRESENCE_TTL, JSON.stringify({ ts: Date.now(), deviceInfo: deviceInfo ?? null }));
      return { online: true, ttl: this.PRESENCE_TTL };
    } else {
      await this.redis.del(key);
      return { online: false };
    }
  }

  // Heartbeat to keep presence alive
  async heartbeat(userId: string, deviceInfo?: string) {
    const profile = await this.profileRepo.findOne({ where: { user: { id: userId } }, relations: ['user'] });
    if (!profile) throw new NotFoundException('Driver profile not found');
    const key = this.presenceKey(profile.user.id);
    await this.redis.setex(key, this.PRESENCE_TTL, JSON.stringify({ ts: Date.now(), deviceInfo: deviceInfo ?? null }));
    return { ok: true, ttl: this.PRESENCE_TTL };
  }

  // Check if driver is currently online (redis presence && not suspended)
  async isOnline(userId: string) {
    const profile = await this.profileRepo.findOne({ where: { user: { id: userId } }, relations: ['user'] });
    if (!profile) throw new NotFoundException('Driver profile not found');
    const key = this.presenceKey(profile.user.id);
    const val = await this.redis.get(key);
    return !!val;
  }

  // Weekly schedule CRUD (replace windows for a given day)
  async setWeeklySchedule(userId: string, dayOfWeek: number, windows: {startTime: string, endTime: string}[]) {
    const profile = await this.profileRepo.findOne({ where: { user: { id: userId } }, relations: ['user'] });
    if (!profile) throw new NotFoundException('Driver profile not found');

    // validate windows non-overlapping & start < end
    const normalized = windows.map(w => ({
      startTime: w.startTime,
      endTime: w.endTime,
    })).sort((a,b) => a.startTime.localeCompare(b.startTime));

    for (let i = 0; i < normalized.length; i++) {
      const a = normalized[i];
      if (a.startTime >= a.endTime) throw new BadRequestException('startTime must be before endTime');
      if (i > 0) {
        const prev = normalized[i-1];
        if (a.startTime < prev.endTime) throw new BadRequestException('Time windows overlap');
      }
    }

    // delete existing for day
    await this.scheduleRepo.delete({ driverProfile: { id: profile.id }, dayOfWeek });
    // insert new
    const created: WeeklySchedule[] = [];
    for (const w of normalized) {
      const row = this.scheduleRepo.create({
        driverProfile: profile,
        dayOfWeek,
        startTime: w.startTime,
        endTime: w.endTime,
      });
      created.push(await this.scheduleRepo.save(row));
    }
    return created;
  }

  async getWeeklySchedules(userId: string) {
    const profile = await this.profileRepo.findOne({ where: { user: { id: userId } }, relations: ['user'] });
    if (!profile) throw new NotFoundException('Driver profile not found');
    const rows = await this.scheduleRepo.find({ where: { driverProfile: { id: profile.id } }});
    // group by day
    const out: Record<string, any[]> = {};
    for (const r of rows) {
      out[r.dayOfWeek] = out[r.dayOfWeek] ?? [];
      out[r.dayOfWeek].push({ id: r.id, startTime: r.startTime, endTime: r.endTime });
    }
    return out;
  }

  // Time-off CRUD with conflict detection
  async addTimeOff(userId: string, startAtIso: string, endAtIso: string, reason?: string) {
    const profile = await this.profileRepo.findOne({ where: { user: { id: userId } }, relations: ['user'] });
    if (!profile) throw new NotFoundException('Driver profile not found');

    const startAt = new Date(startAtIso);
    const endAt = new Date(endAtIso);
    if (isNaN(startAt.getTime()) || isNaN(endAt.getTime()) || startAt >= endAt) {
      throw new BadRequestException('Invalid start/end times');
    }

    // conflict with existing timeoffs?
    const conflicts = await this.timeOffRepo.find({
      where: [
        { driverProfile: { id: profile.id }, startAt: Between(startAt, endAt) },
        { driverProfile: { id: profile.id }, endAt: Between(startAt, endAt) },
      ],
    });
    if (conflicts.length > 0) {
      throw new BadRequestException('Time-off conflicts with existing time-off');
    }

    // also check if time-off covers entire day and conflicts with scheduled shifts? (optional)
    // For now allow time-off but you can warn if it overlaps scheduled windows.

    const to = this.timeOffRepo.create({
      driverProfile: profile,
      startAt,
      endAt,
      status: 'APPROVED',
      reason: reason ?? null,
    });
    const saved = await this.timeOffRepo.save(to);
    return saved;
  }

  async listTimeOffs(userId: string) {
    const profile = await this.profileRepo.findOne({ where: { user: { id: userId } }, relations: ['user'] });
    if (!profile) throw new NotFoundException('Driver profile not found');
    return await this.timeOffRepo.find({ where: { driverProfile: { id: profile.id } }, order: { startAt: 'DESC' }});
  }

  async removeTimeOff(userId: string, timeOffId: string) {
    const profile = await this.profileRepo.findOne({ where: { user: { id: userId } }, relations: ['user'] });
    if (!profile) throw new NotFoundException('Driver profile not found');
    const rec = await this.timeOffRepo.findOne({ where: { id: timeOffId, driverProfile: { id: profile.id } }});
    if (!rec) throw new NotFoundException('Time off entry not found');
    await this.timeOffRepo.remove(rec);
    return { ok: true };
  }

  /**
   * isDriverAvailableAt: checks whether a driver should be available at given Date/time
   * Combines:
   *  - driver presence (online in Redis)
   *  - weekly schedule for the day
   *  - time-offs that exclude the time
   *
   * Returns { available: boolean, reasons: [] }
   */
  async isDriverAvailableAt(userId: string, at: Date = new Date()) {
    const profile = await this.profileRepo.findOne({ where: { user: { id: userId } }, relations: ['user'] });
    if (!profile) throw new NotFoundException('Driver profile not found');

    const reasons: string[] = [];

    // presence check
    const isPresent = await this.isOnline(userId);
    if (!isPresent) reasons.push('offline');

    // time-off check
    const overlappingTimeoffs = await this.timeOffRepo.find({
      where: [
        { driverProfile: { id: profile.id }, startAt: Between(new Date(at.getTime()), new Date(at.getTime())) },
      ],
    });
    // Simpler: query time-offs where startAt <= at <= endAt
    const timeoffs = await this.timeOffRepo.createQueryBuilder('t')
      .where('t.driverProfileId = :pid', { pid: profile.id })
      .andWhere('t.startAt <= :at AND t.endAt >= :at', { at: at.toISOString() })
      .getMany();

    if (timeoffs.length > 0) reasons.push('timeoff');

    // weekly schedule check
    const day = at.getDay(); // 0..6
    const hhmm = `${String(at.getHours()).padStart(2,'0')}:${String(at.getMinutes()).padStart(2,'0')}`;
    const schedules = await this.scheduleRepo.find({ where: { driverProfile: { id: profile.id }, dayOfWeek: day }});
    let inWindow = false;
    for (const s of schedules) {
      if (s.startTime <= hhmm && hhmm < s.endTime) {
        inWindow = true; break;
      }
    }
    if (!inWindow) reasons.push('outside_schedule');

    const available = (isPresent && timeoffs.length === 0 && inWindow);
    return { available, reasons };
  }
}
