import { Module } from '@nestjs/common';
import { FareService } from './fare.service';
import { FareController } from './fare.controller';

@Module({
    providers: [FareService],
    controllers: [FareController],
    exports: [FareService],
})
export class FareModule { }
