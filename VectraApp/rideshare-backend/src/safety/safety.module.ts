import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Incident } from './entities/incident.entity';
import { SafetyService } from './safety.service';
import { SafetyController } from './safety.controller';

@Module({
    imports: [
        TypeOrmModule.forFeature([Incident]),
    ],
    providers: [SafetyService],
    controllers: [SafetyController],
    exports: [SafetyService],
})
export class SafetyModule { }
