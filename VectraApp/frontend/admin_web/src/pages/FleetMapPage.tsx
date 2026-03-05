import { useEffect, useState } from 'react';
import Map, { Marker, NavigationControl } from 'react-map-gl/mapbox';
import 'mapbox-gl/dist/mapbox-gl.css';

const MAPBOX_TOKEN = import.meta.env.VITE_MAPBOX_TOKEN || '';

// SF Coordinates
const INITIAL_VIEW_STATE = {
    longitude: -122.4194,
    latitude: 37.7749,
    zoom: 12,
    pitch: 40,
    bearing: 0
};

interface DriverMarker {
    id: string;
    longitude: number;
    latitude: number;
    status: 'ONLINE' | 'IN_TRIP';
}

function generateRandomDrivers(count: number, centerLat: number, centerLng: number): DriverMarker[] {
    return Array.from({ length: count }).map((_, i) => ({
        id: `driver-mock-${i}`,
        latitude: centerLat + (Math.random() - 0.5) * 0.05,
        longitude: centerLng + (Math.random() - 0.5) * 0.05,
        status: Math.random() > 0.5 ? 'ONLINE' : 'IN_TRIP'
    }));
}

export default function FleetMapPage() {
    const [drivers, setDrivers] = useState<DriverMarker[]>([]);

    useEffect(() => {
        // Initialize mock drivers
        const initialDrivers = generateRandomDrivers(8, INITIAL_VIEW_STATE.latitude, INITIAL_VIEW_STATE.longitude);
        setDrivers(initialDrivers);

        // Simulate movement
        const interval = setInterval(() => {
            setDrivers(prev => prev.map(d => ({
                ...d,
                latitude: d.latitude + (Math.random() - 0.5) * 0.001,
                longitude: d.longitude + (Math.random() - 0.5) * 0.001,
                status: Math.random() > 0.95 ? (d.status === 'ONLINE' ? 'IN_TRIP' : 'ONLINE') : d.status
            })));
        }, 3000);

        return () => clearInterval(interval);
    }, []);

    const onlineCount = drivers.filter(d => d.status === 'ONLINE').length;
    const inTripCount = drivers.filter(d => d.status === 'IN_TRIP').length;

    return (
        <div className="fade-in" style={{ height: 'calc(100vh - 140px)', display: 'flex', flexDirection: 'column' }}>
            <div className="page-header" style={{ marginBottom: 16 }}>
                <div>
                    <h2>Live Fleet Map</h2>
                    <p>Real-time vehicle positioning and status</p>
                </div>
                <div style={{ display: 'flex', gap: 16, alignItems: 'center' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                        <div style={{ width: 12, height: 12, borderRadius: '50%', backgroundColor: '#10b981' }}></div>
                        <span style={{ fontSize: '0.9rem', color: 'var(--text-secondary)' }}>{onlineCount} Available</span>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                        <div style={{ width: 12, height: 12, borderRadius: '50%', backgroundColor: '#f59e0b' }}></div>
                        <span style={{ fontSize: '0.9rem', color: 'var(--text-secondary)' }}>{inTripCount} In Trip</span>
                    </div>
                </div>
            </div>

            <div className="card" style={{ flex: 1, padding: 0, overflow: 'hidden', position: 'relative' }}>
                <Map
                    initialViewState={INITIAL_VIEW_STATE}
                    mapStyle="mapbox://styles/mapbox/dark-v11"
                    mapboxAccessToken={MAPBOX_TOKEN}
                    attributionControl={false}
                >
                    <NavigationControl position="top-right" />

                    {drivers.map(d => (
                        <Marker key={d.id} longitude={d.longitude} latitude={d.latitude} anchor="bottom">
                            <div
                                style={{
                                    width: 24,
                                    height: 24,
                                    backgroundColor: d.status === 'ONLINE' ? '#10b981' : '#f59e0b',
                                    borderRadius: '50%',
                                    border: '3px solid #1e2532',
                                    boxShadow: '0 4px 6px rgba(0,0,0,0.3)',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    color: 'white',
                                    fontSize: '10px'
                                }}
                            >
                                🚗
                            </div>
                        </Marker>
                    ))}
                </Map>
            </div>
        </div>
    );
}
