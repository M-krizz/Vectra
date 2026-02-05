/**
 * GeoJSON Point type for use with PostGIS geography columns.
 *
 * IMPORTANT: GeoJSON uses [longitude, latitude] order, not [lat, lng]!
 *
 * @example
 * const pickup: GeoPoint = {
 *   type: "Point",
 *   coordinates: [77.5946, 12.9716] // [lng, lat] - Bangalore
 * };
 */
export type GeoPoint = {
  type: 'Point';
  coordinates: [number, number]; // [longitude, latitude]
};

/**
 * Helper to create a GeoPoint from latitude and longitude
 */
export function createGeoPoint(latitude: number, longitude: number): GeoPoint {
  return {
    type: 'Point',
    coordinates: [longitude, latitude], // GeoJSON: lng first, lat second
  };
}

/**
 * Extract latitude from a GeoPoint
 */
export function getLatitude(point: GeoPoint): number {
  return point.coordinates[1];
}

/**
 * Extract longitude from a GeoPoint
 */
export function getLongitude(point: GeoPoint): number {
  return point.coordinates[0];
}
