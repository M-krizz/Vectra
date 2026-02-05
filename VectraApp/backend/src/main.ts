import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors(); // <--- Enable CORS for Web Frontend
  await app.listen(3000);
  console.log('🚀 Vectra Backend is running on http://localhost:3000');
}
void bootstrap();
