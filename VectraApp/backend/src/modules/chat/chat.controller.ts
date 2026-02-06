import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { ChatService } from './chat.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('chat')
// @UseGuards(JwtAuthGuard) // Uncomment when token handling in frontend is robust
export class ChatController {
    constructor(private readonly chatService: ChatService) { }

    @Get(':tripId/messages')
    async getMessages(@Param('tripId') tripId: string) {
        return await this.chatService.getMessagesForTrip(tripId);
    }
}
