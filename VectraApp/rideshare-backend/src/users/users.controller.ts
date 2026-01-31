import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { CreateRiderDto } from './dto/create-rider.dto';
import { UsersService } from './users.service';

@Controller('auth')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  /**
   * POST /auth/register/rider
   * Creates a Rider user. Returns the created user (sanitized).
   * Note: isVerified = false — OTP verification must follow (FR1.1.4).
   */
  @Post('register/rider')
  async registerRider(@Body() dto: CreateRiderDto) {
    const user = await this.usersService.createRider(dto);
    return {
      status: 'created',
      user,
    };
  }
}
