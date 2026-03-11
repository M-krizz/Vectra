import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { IncentiveEntity } from './incentive.entity';
import { IncentivesService } from './incentives.service';
import { IncentivesController } from './incentives.controller';

@Module({
    imports: [TypeOrmModule.forFeature([IncentiveEntity])],
    controllers: [IncentivesController],
    providers: [IncentivesService],
    exports: [IncentivesService],
})
export class IncentivesModule { }
