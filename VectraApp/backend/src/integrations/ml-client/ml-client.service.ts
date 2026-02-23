import { Injectable, Logger } from '@nestjs/common';
import axios from 'axios';

export interface PoolRider {
    id: string;
    lat: number;
    lng: number;
}

export interface PoolEvaluationRequest {
    vehicle_type: string;
    riders: PoolRider[];
}

export interface PoolEvaluationResponse {
    isValid: boolean;
    score: number;
    sequence: string[];
    detourOk: boolean;
}

@Injectable()
export class MlClientService {
    private readonly logger = new Logger(MlClientService.name);
    private readonly baseUrl: string;

    constructor() {
        this.baseUrl = process.env.ML_SERVICE_URL || 'http://localhost:8000';
    }

    async evaluatePool(data: PoolEvaluationRequest): Promise<PoolEvaluationResponse> {
        try {
            const response = await axios.post<PoolEvaluationResponse>(
                `${this.baseUrl}/evaluate-pool`,
                data,
            );
            return response.data;
        } catch (err) {
            this.logger.error('Failed to communicate with ML Service', err.message);
            // Fallback for reliability (Module 1.11: Never trust ML blindly)
            return {
                isValid: false,
                score: 0,
                sequence: data.riders.map(r => r.id),
                detourOk: false,
            };
        }
    }
}
