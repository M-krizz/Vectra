import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThan } from 'typeorm';
import { Document } from './entities/document.entity';
import { DriverProfile, DriverStatus } from '../users/driver-profile.entity';
import { ComplianceEvent } from './entities/compliance-event.entity';
import { UsersService } from '../users/users.service'; // if you have convenience helpers
import { Cron, CronExpression, SchedulerRegistry } from '@nestjs/schedule';
import ms from 'ms';

@Injectable()
export class ComplianceService {
  private logger = new Logger(ComplianceService.name);
  // days before expiry to notify drivers
  private notifyDays = Number(process.env.DOCUMENT_EXPIRY_NOTIFICATION_DAYS || 30);

  constructor(
    @InjectRepository(Document) private docsRepo: Repository<Document>,
    @InjectRepository(DriverProfile) private profilesRepo: Repository<DriverProfile>,
    @InjectRepository(ComplianceEvent) private eventsRepo: Repository<ComplianceEvent>,
    private usersService: UsersService,
  ) {}

  // run daily cron to find expired docs and take action
  @Cron(process.env.DOCUMENT_CHECK_CRON || CronExpression.EVERY_DAY)
  async checkExpirations() {
    this.logger.log('Running compliance expiration check');

    // 1) find docs that are expired and not marked yet (expiresAt < now, and maybe isApproved was true earlier)
    const now = new Date();
    const expiredDocs = await this.docsRepo.find({ where: { expiresAt: LessThan(now), isApproved: true }, relations: ['driverProfile'] });

    for (const doc of expiredDocs) {
      // record event
      await this.eventsRepo.save({
        driverProfile: doc.driverProfile,
        eventType: 'DOCUMENT_EXPIRED',
        meta: { documentId: doc.id, docType: doc.docType },
      });

      // set driver profile to SUSPENDED (business rule). You could also set to UNDER_REVIEW.
      const profile = await this.profilesRepo.findOne({ where: { id: doc.driverProfile.id }, relations: ['user'] });
      if (profile) {
        profile.status = DriverStatus.SUSPENDED;
        await this.profilesRepo.save(profile);

        await this.eventsRepo.save({
          driverProfile: profile,
          eventType: 'DRIVER_SUSPENDED',
          meta: { reason: 'document_expired', documentId: doc.id },
        });

        // notify driver via push/sms/email - implement notifier in your app
        await this.notifyDriver(profile.user.id, `Your ${doc.docType} has expired. Please renew within ${this.notifyDays} days to avoid suspension.` );
      }
    }

    // 2) optionally: notify upcoming expirations (expires within notifyDays)
    const notifyUntil = new Date(Date.now() + this.notifyDays * 24 * 60 * 60 * 1000);
    const soonToExpire = await this.docsRepo.find({ where: { expiresAt: LessThan(notifyUntil), isApproved: true }, relations: ['driverProfile'] });

    for (const doc of soonToExpire) {
      // avoid duplicate notifications — check last event to see if a 'EXPIRY_NOTICE' exists recently. For brevity we always create.
      await this.eventsRepo.save({
        driverProfile: doc.driverProfile,
        eventType: 'EXPIRY_NOTICE',
        meta: { documentId: doc.id, docType: doc.docType, expiresAt: doc.expiresAt },
      });

      await this.notifyDriver(doc.driverProfile.user.id, `Your ${doc.docType} will expire on ${doc.expiresAt?.toISOString()}. Please renew soon.`);
    }

    this.logger.log('Compliance expiration check completed');
  }

  private async notifyDriver(userId: string, message: string) {
    // placeholder — integrate with notification service (FCM, Twilio, email)
    this.logger.warn(`notifyDriver(${userId}): ${message}`);
    // Save event as system notification if you have notifications table
  }
}
