import { Injectable } from '@nestjs/common';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class S3Service {
  private client: S3Client;
  private bucket: string;
  private expirySeconds: number;

  constructor() {
    this.client = new S3Client({ region: process.env.AWS_REGION });
    this.bucket = process.env.S3_BUCKET;
    this.expirySeconds = Number(process.env.S3_UPLOAD_EXPIRY_SECONDS || 300);
  }

  async getPresignedUploadUrl(originalName: string, mimeType: string, driverId: string) {
    const key = `drivers/${driverId}/${Date.now()}-${uuidv4()}-${originalName}`;
    const cmd = new PutObjectCommand({
      Bucket: this.bucket,
      Key: key,
      ContentType: mimeType,
      ServerSideEncryption: 'AES256',
      ACL: 'private',
    });
    const url = await getSignedUrl(this.client, cmd, { expiresIn: this.expirySeconds });
    return { url, key, expiresIn: this.expirySeconds };
  }
}
