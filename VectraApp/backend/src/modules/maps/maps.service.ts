import { Injectable, Logger, HttpException, HttpStatus } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { lastValueFrom } from 'rxjs';
import { GeoPoint } from '../../common/types/geo-point.type';
import { getLatitude, getLongitude } from '../../common/types/geo-point.type';

@Injectable()
export class MapsService {
    private readonly logger = new Logger(MapsService.name);
    private readonly accessToken: string;

    constructor(private readonly httpService: HttpService) {
        this.accessToken = process.env.MAPBOX_ACCESS_TOKEN || '';
        if (!this.accessToken) {
            this.logger.warn('MAPBOX_ACCESS_TOKEN is not defined. Maps integration will fail.');
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Mapbox Geocoding API v5 – Forward Geocoding (replaces Google Places Autocomplete)
    // GET https://api.mapbox.com/geocoding/v5/mapbox.places/{search_text}.json
    // ─────────────────────────────────────────────────────────────────────────
    async placesAutocomplete(input: string, location?: string, radius?: string): Promise<any> {
        if (!this.accessToken) return { status: 'ZERO_RESULTS', predictions: [] };

        const params: Record<string, string> = {
            access_token: this.accessToken,
            country: 'in',
            autocomplete: 'true',
            limit: '5',
            types: 'poi,address,place,locality',
        };

        // location format from frontend: "lat,lng" – Mapbox proximity needs "lng,lat"
        if (location) {
            const [lat, lng] = location.split(',').map(Number);
            if (!isNaN(lat) && !isNaN(lng)) {
                params.proximity = `${lng},${lat}`;
            }
        }

        try {
            const encodedInput = encodeURIComponent(input);
            const response = await lastValueFrom(
                this.httpService.get(
                    `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodedInput}.json`,
                    { params },
                ),
            );

            const data = response.data;

            if (!data.features || data.features.length === 0) {
                return { status: 'ZERO_RESULTS', predictions: [] };
            }

            // Map Mapbox features to a Google-like prediction format for frontend compat
            const predictions = data.features.map((feature: any) => {
                const [lng, lat] = feature.center;
                const parts = (feature.place_name || '').split(', ');
                const mainText = parts[0] || feature.text || '';
                const secondaryText = parts.slice(1).join(', ');

                return {
                    place_id: feature.id,
                    description: feature.place_name,
                    structured_formatting: {
                        main_text: mainText,
                        secondary_text: secondaryText,
                    },
                    geometry: {
                        location: { lat, lng },
                    },
                };
            });

            return { status: 'OK', predictions };
        } catch (error: any) {
            this.logger.error(`Mapbox Geocoding failed: ${error.message}`);
            return { status: 'ZERO_RESULTS', predictions: [] };
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Mapbox Geocoding API v5 – Forward lookup by name (replaces Google Place Details)
    // Mapbox v5 does not support a direct place-ID retrieval like Google.
    // The autocomplete response already includes coordinates, so the frontend
    // should prefer using those directly.  This endpoint exists as a fallback.
    // ─────────────────────────────────────────────────────────────────────────
    async placeDetails(placeId: string): Promise<any> {
        if (!this.accessToken) return { status: 'ZERO_RESULTS', result: null };

        try {
            const encodedId = encodeURIComponent(placeId);
            const response = await lastValueFrom(
                this.httpService.get(
                    `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodedId}.json`,
                    {
                        params: {
                            access_token: this.accessToken,
                            country: 'in',
                            limit: '1',
                        },
                    },
                ),
            );

            const data = response.data;

            if (!data.features || data.features.length === 0) {
                return { status: 'ZERO_RESULTS', result: null };
            }

            const feature = data.features[0];
            const [lng, lat] = feature.center;

            return {
                status: 'OK',
                result: {
                    name: feature.text,
                    formatted_address: feature.place_name,
                    geometry: {
                        location: { lat, lng },
                    },
                },
            };
        } catch (error: any) {
            this.logger.error(`Mapbox Place Details failed: ${error.message}`);
            return { status: 'ZERO_RESULTS', result: null };
        }
    }

    /**
     * Calculate exact driving ETA and distance using Mapbox Directions API v5
     */
    async getEtaAndDistance(origin: GeoPoint, destination: GeoPoint): Promise<{ distanceMeters: number; durationSeconds: number }> {
        if (!this.accessToken) return { distanceMeters: 5000, durationSeconds: 600 };

        const originLng = getLongitude(origin);
        const originLat = getLatitude(origin);
        const destLng = getLongitude(destination);
        const destLat = getLatitude(destination);

        try {
            // Mapbox Directions: coordinates are lng,lat pairs separated by ;
            const coordinates = `${originLng},${originLat};${destLng},${destLat}`;
            const response = await lastValueFrom(
                this.httpService.get(
                    `https://api.mapbox.com/directions/v5/mapbox/driving/${coordinates}`,
                    {
                        params: {
                            access_token: this.accessToken,
                            overview: 'false',
                        },
                    },
                ),
            );

            const data = response.data;
            if (!data.routes || data.routes.length === 0) {
                throw new Error('No routes found');
            }

            const route = data.routes[0];
            return {
                distanceMeters: Math.round(route.distance),   // metres
                durationSeconds: Math.round(route.duration),   // seconds
            };
        } catch (error) {
            this.logger.error(`Failed to calculate ETA: ${(error as any).message}`);
            return { distanceMeters: 5000, durationSeconds: 600 };
        }
    }

    /**
     * Check if a driver's current location implies a significant route deviation.
     * Uses Mapbox Directions API to compute bounding box of the ideal route, then
     * checks whether the driver is outside the box + a configurable buffer.
     */
    async detectRouteDeviation(
        currentLocation: { lat: number; lng: number },
        origin: GeoPoint,
        destination: GeoPoint,
    ): Promise<boolean> {
        if (!this.accessToken) return false;

        try {
            const originLng = getLongitude(origin);
            const originLat = getLatitude(origin);
            const destLng = getLongitude(destination);
            const destLat = getLatitude(destination);

            const coordinates = `${originLng},${originLat};${destLng},${destLat}`;
            const response = await lastValueFrom(
                this.httpService.get(
                    `https://api.mapbox.com/directions/v5/mapbox/driving/${coordinates}`,
                    {
                        params: {
                            access_token: this.accessToken,
                            overview: 'full',
                            geometries: 'geojson',
                        },
                    },
                ),
            );

            const data = response.data;
            if (!data.routes || data.routes.length === 0) {
                return false;
            }

            // Compute bounding box from route geometry
            const coords: number[][] = data.routes[0].geometry.coordinates;
            let minLng = Infinity, maxLng = -Infinity;
            let minLat = Infinity, maxLat = -Infinity;
            for (const [lng, lat] of coords) {
                if (lng < minLng) minLng = lng;
                if (lng > maxLng) maxLng = lng;
                if (lat < minLat) minLat = lat;
                if (lat > maxLat) maxLat = lat;
            }

            const thresholdMeters = Number(process.env.ROUTE_DEVIATION_THRESHOLD_METERS || 500);
            const bufferDeg = thresholdMeters / 111000; // ~1° ≈ 111 km

            if (
                currentLocation.lat < minLat - bufferDeg ||
                currentLocation.lat > maxLat + bufferDeg ||
                currentLocation.lng < minLng - bufferDeg ||
                currentLocation.lng > maxLng + bufferDeg
            ) {
                this.logger.warn(
                    `Route deviation detected! Driver at ${currentLocation.lat},${currentLocation.lng} is outside safe bounds.`,
                );
                return true;
            }

            return false;
        } catch (error) {
            this.logger.error(`Deviation check failed: ${(error as any).message}`);
            return false;
        }
    }

    /**
     * Get full route directions with GeoJSON geometry for map display.
     * Used by the frontend to draw polylines without needing a client-side API key.
     */
    async getDirections(
        origin: GeoPoint,
        destination: GeoPoint,
    ): Promise<any> {
        if (!this.accessToken) return null;

        const originLng = getLongitude(origin);
        const originLat = getLatitude(origin);
        const destLng = getLongitude(destination);
        const destLat = getLatitude(destination);

        try {
            const coordinates = `${originLng},${originLat};${destLng},${destLat}`;
            const response = await lastValueFrom(
                this.httpService.get(
                    `https://api.mapbox.com/directions/v5/mapbox/driving/${coordinates}`,
                    {
                        params: {
                            access_token: this.accessToken,
                            overview: 'full',
                            geometries: 'geojson',
                            steps: 'true',
                        },
                    },
                ),
            );

            const data = response.data;
            if (!data.routes || data.routes.length === 0) {
                return null;
            }

            return data.routes[0];
        } catch (error) {
            this.logger.error(`Directions failed: ${(error as any).message}`);
            return null;
        }
    }
}
