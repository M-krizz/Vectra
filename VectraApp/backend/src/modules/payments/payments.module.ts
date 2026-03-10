import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PaymentsController } from './payments.controller';
import { PaymentsService } from './payments.service';
import { PaymentEntity } from './entities/payment.entity';
import { WalletEntity } from './entities/wallet.entity';
import { TripEntity } from '../trips/trip.entity';
import { TripRiderEntity } from '../trips/trip-rider.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([
            PaymentEntity,
            WalletEntity,
            TripEntity,
            TripRiderEntity,
        ]),
    ],
    controllers: [PaymentsController],
    providers: [PaymentsService],
    exports: [PaymentsService],
})
export class PaymentsModule { }
