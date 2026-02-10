import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors(); // <--- Enable CORS for Web Frontend
  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`🚀 Vectra Backend is running on http://localhost:${port}`);
}
void bootstrap();
