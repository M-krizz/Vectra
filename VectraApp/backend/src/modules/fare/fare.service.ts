import { Injectable } from '@nestjs/common';
import { VehicleType } from '../ride_requests/ride-request.enums';
import { RideType } from '../ride_requests/ride-request.enums';
import {
    FARE_CONFIG,
    SURGE_TIERS,
    FareBreakdown,
} from './fare.types';

@Injectable()
export class FareService {
    /**
     * Return simplified rate cards for driver-facing apps.
     */
    getRateCards() {
        const cards = Object.entries(FARE_CONFIG).map(([vehicleType, config]) => ({
            vehicleType: this.mapVehicleTypeForClient(vehicleType as VehicleType),
            baseFare: config.baseFare,
            distanceSlabs: [
                {
                    minDistance: 0,
                    maxDistance: null,
                    ratePerKm: config.perKmRate,
                },
            ],
            nightFareMultiplier: 1.2,
            nightStartTime: '22:00',
            nightEndTime: '06:00',
            surgeMultiplier: null,
            waitingChargePerMin: config.perMinRate,
            cancellationFee: 50,
        }));

        return { items: cards };
    }

    private mapVehicleTypeForClient(vehicleType: VehicleType): string {
        switch (vehicleType) {
            case VehicleType.BIKE:
                return 'bike';
            case VehicleType.AUTO:
                return 'auto';
            case VehicleType.CAB: 
                return 'mini';
            default:
                return 'mini';
        }
    }

    /**
     * Calculate fare breakdown for a trip.
     *
     * @param vehicleType  - Type of vehicle
     * @param rideType     - SOLO or POOL
     * @param distanceMeters - Trip distance in metres
     * @param durationSeconds - Trip duration in seconds
     * @param riderCount   - Number of riders sharing (pool)
     * @param demandRatio  - 0..1, current supply/demand ratio (for surge)
     */
    calculate(
        vehicleType: VehicleType,
        rideType: RideType,
        distanceMeters: number,
        durationSeconds: number,
        riderCount = 1,
        demandRatio = 0,
    ): FareBreakdown {
        const config = FARE_CONFIG[vehicleType];
        if (!config) throw new Error(`Unknown vehicleType: ${vehicleType}`);

        const distanceKm = distanceMeters / 1000;
        const durationMin = durationSeconds / 60;

        const baseFare = config.baseFare;
        const distanceFare = parseFloat((distanceKm * config.perKmRate).toFixed(2));
        const timeFare = parseFloat((durationMin * config.perMinRate).toFixed(2));

        // Surge
        const surgeEntry = [...SURGE_TIERS]
            .reverse()
            .find((t) => demandRatio >= t.threshold) ?? SURGE_TIERS[0];
        const surgeMultiplier = surgeEntry.multiplier;
        const preDiscountTotal = baseFare + distanceFare + timeFare;
        const surgeExtra = parseFloat(
            (preDiscountTotal * (surgeMultiplier - 1)).toFixed(2),
        );

        const totalBeforeDiscount = preDiscountTotal + surgeExtra;

        // Pool discount (only for POOL rides; bikes never pool)
        const poolDiscountAmount =
            rideType === RideType.POOL && riderCount > 1
                ? parseFloat((totalBeforeDiscount * config.poolDiscount).toFixed(2))
                : 0;

        const totalFare = parseFloat(
            (totalBeforeDiscount - poolDiscountAmount).toFixed(2),
        );

        // Per-rider split (further divided by rider count for pool)
        const perRiderFare =
            rideType === RideType.POOL && riderCount > 1
                ? parseFloat((totalFare / riderCount).toFixed(2))
                : totalFare;

        return {
            baseFare,
            distanceFare,
            timeFare,
            surgeMultiplier,
            surgeExtra,
            poolDiscount: poolDiscountAmount,
            totalFare,
            perRiderFare,
            currencyCode: 'INR',
        };
    }

    /**
     * Quick estimate (before trip starts) — uses speed assumption.
     * We don't know durationSeconds yet, so we estimate using 20 km/h average.
     */
    estimate(
        vehicleType: VehicleType,
        rideType: RideType,
        distanceMeters: number,
        demandRatio = 0,
    ): FareBreakdown {
        const AVERAGE_SPEED_KMH = 20;
        const estimatedDuration = (distanceMeters / 1000 / AVERAGE_SPEED_KMH) * 3600;
        return this.calculate(vehicleType, rideType, distanceMeters, estimatedDuration, 1, demandRatio);
    }
}
