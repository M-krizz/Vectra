import { VehicleType } from '../ride_requests/ride-request.enums';

/** Per-vehicle pricing config */
export const FARE_CONFIG: Record<
    VehicleType,
    { baseFare: number; perKmRate: number; perMinRate: number; poolDiscount: number }
> = {
    [VehicleType.AUTO]: { baseFare: 25, perKmRate: 12, perMinRate: 0.5, poolDiscount: 0.25 },
    [VehicleType.CAB]: { baseFare: 40, perKmRate: 16, perMinRate: 0.8, poolDiscount: 0.20 },
    [VehicleType.BIKE]: { baseFare: 15, perKmRate: 8, perMinRate: 0.3, poolDiscount: 0.00 },
};

export const SURGE_TIERS = [
    { threshold: 0.00, multiplier: 1.0 },
    { threshold: 0.70, multiplier: 1.3 },
    { threshold: 0.85, multiplier: 1.6 },
    { threshold: 0.95, multiplier: 2.0 },
];

export interface FareBreakdown {
    baseFare: number;
    distanceFare: number;
    timeFare: number;
    surgeMultiplier: number;
    surgeExtra: number;
    poolDiscount: number;
    totalFare: number;
    perRiderFare: number;       // after pool split
    currencyCode: 'INR';
}
