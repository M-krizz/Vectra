import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThanOrEqual, MoreThanOrEqual, IsNull } from 'typeorm';
import { IncentiveEntity } from './incentive.entity';

@Injectable()
export class IncentivesService {
    private readonly logger = new Logger(IncentivesService.name);

    constructor(
        @InjectRepository(IncentiveEntity)
        private readonly incentiveRepo: Repository<IncentiveEntity>,
    ) { }

    /** Get active (non-completed, non-expired) incentives for a driver */
    async getActiveIncentives(driverUserId: string): Promise<IncentiveEntity[]> {
        const now = new Date();
        return this.incentiveRepo
            .createQueryBuilder('i')
            .where('i.driverUserId = :driverUserId', { driverUserId })
            .andWhere('i.isCompleted = :completed', { completed: false })
            .andWhere('(i.expiresAt IS NULL OR i.expiresAt > :now)', { now })
            .orderBy('i.createdAt', 'DESC')
            .getMany();
    }

    /** Get completed incentives for a driver */
    async getCompletedIncentives(driverUserId: string): Promise<IncentiveEntity[]> {
        return this.incentiveRepo.find({
            where: { driverUserId, isCompleted: true },
            order: { updatedAt: 'DESC' },
        });
    }

    /** Get all incentives for a driver */
    async getAllIncentives(driverUserId: string): Promise<IncentiveEntity[]> {
        return this.incentiveRepo.find({
            where: { driverUserId },
            order: { createdAt: 'DESC' },
        });
    }
}
