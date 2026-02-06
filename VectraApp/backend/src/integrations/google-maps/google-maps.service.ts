import { Injectable } from '@nestjs/common';
import { Client } from '@googlemaps/google-maps-services-js';

@Injectable()
export class GoogleMapsService {
    private client: Client;

    constructor() {
        this.client = new Client({});
    }

    async geocode(address: string) {
        if (!process.env.GOOGLE_MAPS_API_KEY) {
            throw new Error('Google Maps API Key not configured');
        }
        const response = await this.client.geocode({
            params: {
                address,
                key: process.env.GOOGLE_MAPS_API_KEY,
            },
        });
        return response.data.results[0];
    }

    async reverseGeocode(lat: number, lng: number) {
        if (!process.env.GOOGLE_MAPS_API_KEY) {
            throw new Error('Google Maps API Key not configured');
        }
        const response = await this.client.reverseGeocode({
            params: {
                latlng: [lat, lng],
                key: process.env.GOOGLE_MAPS_API_KEY,
            },
        });
        return response.data.results[0];
    }
}
