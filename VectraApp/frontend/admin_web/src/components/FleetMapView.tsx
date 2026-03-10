import React, { useMemo } from 'react';
import { GoogleMap, useLoadScript, Marker, InfoWindow } from '@react-google-maps/api';
import { DriverPin } from '../hooks/useFleetData';
import { Navigation } from 'lucide-react';

const libraries: ("places" | "geometry" | "drawing" | "visualization")[] = ['places'];
const mapContainerStyle = {
    width: '100%',
    height: '100%',
    borderRadius: '16px'
};

// Map options to match the dark glassmorphism theme
const options = {
    disableDefaultUI: true,
    zoomControl: true,
    styles: [
        { elementType: "geometry", stylers: [{ color: "#242f3e" }] },
        { elementType: "labels.text.stroke", stylers: [{ color: "#242f3e" }] },
        { elementType: "labels.text.fill", stylers: [{ color: "#746855" }] },
        {
            featureType: "water",
            elementType: "geometry",
            stylers: [{ color: "#17263c" }],
        },
        // Very dark theme for vectra dashboard
    ]
};

const API_KEY = (import.meta as any).env.VITE_GOOGLE_MAPS_API_KEY ?? '';

export function FleetMapView({ drivers }: { drivers: DriverPin[] }) {
    if (!API_KEY) {
        return <div className="fleet-view">Missing VITE_GOOGLE_MAPS_API_KEY</div>;
    }

    const { isLoaded, loadError } = useLoadScript({
        googleMapsApiKey: API_KEY,
        libraries,
    });

    // Default center to Bangalore since that maps to our seeded data
    const center = useMemo(() => ({ lat: 12.9716, lng: 77.5946 }), []);

    if (loadError) return <div className="fleet-view">Error loading maps</div>;
    if (!isLoaded) return <div className="fleet-view">Loading Maps...</div>;

    return (
        <div className="fleet-view" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
            <h3>Live Fleet — {drivers.length} Active Drivers</h3>
            <div className="glass" style={{ flex: 1, position: 'relative', marginTop: 16, padding: 8 }}>
                <GoogleMap
                    mapContainerStyle={mapContainerStyle}
                    zoom={12}
                    center={center}
                    options={options}
                >
                    {drivers.map(driver => (
                        <Marker
                            key={driver.driverId}
                            position={{ lat: driver.lat, lng: driver.lng }}
                            icon={{
                                path: window.google.maps.SymbolPath.FORWARD_CLOSED_ARROW,
                                scale: 5,
                                fillColor: '#4285F4',
                                fillOpacity: 0.9,
                                strokeWeight: 2,
                                strokeColor: '#ffffff',
                                rotation: driver.heading,
                            }}
                        />
                    ))}
                </GoogleMap>
            </div>
        </div>
    );
}
