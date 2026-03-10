import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  UseGuards,
  Req,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import * as fs from 'fs';
import { DriversService } from './drivers.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../common/roles.decorator';
import { RolesGuard } from '../common/roles.guard';
import { UserRole } from '../users/user.entity';
import { VehicleEntity } from './vehicle.entity';

@Controller('api/v1/drivers')
@UseGuards(JwtAuthGuard)
export class DriversController {
  constructor(private readonly driversService: DriversService) { }

  @Get('profile')
  @Roles(UserRole.DRIVER)
  @UseGuards(RolesGuard)
  getProfile(@Req() req: { user: { userId: string } }) {
    return this.driversService.getProfile(req.user.userId);
  }

  @Post('documents/upload')
  @Roles(UserRole.DRIVER)
  @UseGuards(RolesGuard)
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: (req, file, cb) => {
          const uploadPath = './uploads/drivers';
          if (!fs.existsSync(uploadPath)) {
            fs.mkdirSync(uploadPath, { recursive: true });
          }
          cb(null, uploadPath);
        },
        filename: (req, file, cb) => {
          const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
          const ext = extname(file.originalname);
          const userId = (req as any).user?.userId || 'unknown';
          cb(null, `${userId}-${uniqueSuffix}${ext}`);
        },
      }),
    }),
  )
  uploadDocument(
    @Req() req: { user: { userId: string } },
    @UploadedFile() file: Express.Multer.File,
    @Body('docType') docType: 'LICENSE' | 'RC',
  ) {
    if (!file) throw new BadRequestException('File is required');
    if (docType !== 'LICENSE' && docType !== 'RC') {
      throw new BadRequestException('docType must be LICENSE or RC');
    }
    return this.driversService.uploadDocument(
      req.user.userId,
      docType,
      file.filename,
    );
  }

  @Post('online')
  @Roles(UserRole.DRIVER)
  @UseGuards(RolesGuard)
  setOnline(
    @Req() req: { user: { userId: string } },
    @Body() dto: { online: boolean },
  ) {
    return this.driversService.setOnlineStatus(req.user.userId, dto.online);
  }

  @Get('vehicles')
  @Roles(UserRole.DRIVER)
  @UseGuards(RolesGuard)
  getVehicles(@Req() req: { user: { userId: string } }) {
    return this.driversService.getVehicles(req.user.userId);
  }

  @Post('vehicles')
  @Roles(UserRole.DRIVER)
  @UseGuards(RolesGuard)
  addVehicle(
    @Req() req: { user: { userId: string } },
    @Body() dto: Partial<VehicleEntity>,
  ) {
    return this.driversService.addVehicle(req.user.userId, dto);
  }
}
