import { Controller, Post, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { CreateDriverDto } from './dto/create-driver.dto';
import { DriversService } from './drivers.service';

@Controller('drivers')
export class DriversController {
  constructor(private driversService: DriversService) {}

  /**
   * POST /drivers/register
   * Create driver account (creates User + DriverProfile + Vehicles)
   */
  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  async register(@Body() dto: CreateDriverDto) {
    const result = await this.driversService.registerDriver(dto);
    return { status: 'created', ...result };
  }
}
