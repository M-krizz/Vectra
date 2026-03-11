import { Controller, Get, Query, HttpException, HttpStatus } from '@nestjs/common';
import { MapsService } from './maps.service';
import { createGeoPoint } from '../../common/types/geo-point.type';

@Controller('api/v1/maps')
export class MapsController {
    constructor(private readonly mapsService: MapsService) { }

    @Get('places/autocomplete')
    async autocomplete(
        @Query('input') input: string,
        @Query('location') location?: string,
        @Query('radius') radius?: string,
    ) {
        if (!input) {
            throw new HttpException('Input query is empty', HttpStatus.BAD_REQUEST);
        }
        return this.mapsService.placesAutocomplete(input, location, radius);
    }

    @Get('places/details')
    async placeDetails(@Query('place_id') placeId: string) {
        if (!placeId) {
            throw new HttpException('Place ID is missing', HttpStatus.BAD_REQUEST);
        }
        return this.mapsService.placeDetails(placeId);
    }

    @Get('directions')
    async getDirections(
        @Query('origin_lat') originLat: string,
        @Query('origin_lng') originLng: string,
        @Query('dest_lat') destLat: string,
        @Query('dest_lng') destLng: string,
    ) {
        if (!originLat || !originLng || !destLat || !destLng) {
            throw new HttpException(
                'Origin and destination coordinates are required',
                HttpStatus.BAD_REQUEST,
            );
        }
        const origin = createGeoPoint(Number(originLat), Number(originLng));
        const destination = createGeoPoint(Number(destLat), Number(destLng));
        const route = await this.mapsService.getDirections(origin, destination);
        if (!route) {
            throw new HttpException('No route found', HttpStatus.NOT_FOUND);
        }
        return route;
    }
}
