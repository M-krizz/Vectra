import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  const isProduction = process.env.NODE_ENV === 'production';
  const allowedOriginsEnv = process.env.CORS_ALLOWED_ORIGINS;
  const allowedOrigins = allowedOriginsEnv
    ? allowedOriginsEnv.split(',').map(origin => origin.trim()).filter(origin => origin.length > 0)
    : [];

  app.enableCors({
    origin: isProduction
      ? (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => {
          // Allow same-origin requests without an Origin header (e.g., curl, server-to-server)
          if (!origin) {
            return callback(null, true);
          }

          if (allowedOrigins.includes(origin)) {
            return callback(null, true);
          }

          return callback(new Error('Not allowed by CORS'), false);
        }
      : true,
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
  });
  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`🚀 Vectra Backend is running on http://localhost:${port}`);
}
void bootstrap();
