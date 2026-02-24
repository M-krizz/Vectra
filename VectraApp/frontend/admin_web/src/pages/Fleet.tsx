import React, { useEffect, useState, useRef } from 'react';
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet';
import L from 'leaflet';
import { adminApi } from '../api/endpoints';

// Custom marker icons
const createIcon = (color: string) =>
    L.divIcon({
        className: '',
        html: `<div style="
      width: 16px; height: 16px; border-radius: 50%;
      background: ${color}; border: 2px solid white;
      box-shadow: 0 2px 6px rgba(0,0,0,0.5);
    "></div>`,
        iconSize: [16, 16],
        iconAnchor: [8, 8],
    });

const onlineIcon = createIcon('#10b981');
const busyIcon = createIcon('#f59e0b');
const offlineIcon = createIcon('#64748b');

interface DriverLocation {
    id: string;
    name: string;
    role: string;
    lat: number;
    lng: number;
    status: 'online' | 'busy' | 'offline';
    rating?: number;
    vehicle?: string;
}

const Fleet: React.FC = () => {
    const [drivers, setDrivers] = useState<DriverLocation[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        // Fetch users and simulate driver positions for the fleet map
        adminApi.listUsers()
            .then((res) => {
                const users = Array.isArray(res.data) ? res.data : [];
                const driverUsers = users.filter((u: any) => u.role === 'DRIVER');

                // Generate demo positions centered around a default location
                const baseLat = 12.9716;
                const baseLng = 77.5946;
                const mapped: DriverLocation[] = driverUsers.map((d: any, i: number) => ({
                    id: d.id,
                    name: d.fullName || `Driver ${i + 1}`,
                    role: d.role,
                    lat: baseLat + (Math.random() - 0.5) * 0.08,
                    lng: baseLng + (Math.random() - 0.5) * 0.08,
                    status: d.driverProfile?.onlineStatus
                        ? 'online'
                        : d.status === 'ACTIVE'
                            ? 'offline'
                            : 'offline',
                    rating: d.driverProfile?.ratingAvg,
                    vehicle: d.driverProfile?.licenseNumber,
                }));
                setDrivers(mapped);
            })
            .catch(() => { })
            .finally(() => setLoading(false));
    }, []);

    const onlineCount = drivers.filter((d) => d.status === 'online').length;
    const busyCount = drivers.filter((d) => d.status === 'busy').length;
    const offlineCount = drivers.filter((d) => d.status === 'offline').length;

    const getIcon = (status: string) => {
        switch (status) {
            case 'online': return onlineIcon;
            case 'busy': return busyIcon;
            default: return offlineIcon;
        }
    };

    if (loading) {
        return <div className="loading-spinner"><div className="spinner" /></div>;
    }

    return (
        <div>
            <div className="page-header">
                <div>
                    <h1>Fleet Monitoring</h1>
                    <p>Real-time driver locations and status</p>
                </div>
            </div>

            {/* Summary Strip */}
            <div className="fleet-summary-strip">
                <div className="fleet-summary-item">
                    <div className="fleet-summary-dot" style={{ background: '#10b981' }} />
                    <div>
                        <div className="count">{onlineCount}</div>
                        <div className="label">Online</div>
                    </div>
                </div>
                <div className="fleet-summary-item">
                    <div className="fleet-summary-dot" style={{ background: '#f59e0b' }} />
                    <div>
                        <div className="count">{busyCount}</div>
                        <div className="label">On Trip</div>
                    </div>
                </div>
                <div className="fleet-summary-item">
                    <div className="fleet-summary-dot" style={{ background: '#64748b' }} />
                    <div>
                        <div className="count">{offlineCount}</div>
                        <div className="label">Offline</div>
                    </div>
                </div>
                <div className="fleet-summary-item">
                    <div className="fleet-summary-dot" style={{ background: '#6366f1' }} />
                    <div>
                        <div className="count">{drivers.length}</div>
                        <div className="label">Total Fleet</div>
                    </div>
                </div>
            </div>

            {/* Map */}
            <div className="fleet-map-container">
                <MapContainer
                    center={[12.9716, 77.5946]}
                    zoom={13}
                    style={{ height: '100%', width: '100%' }}
                    scrollWheelZoom
                >
                    <TileLayer
                        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
                        url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
                    />
                    {drivers.map((driver) => (
                        <Marker
                            key={driver.id}
                            position={[driver.lat, driver.lng]}
                            icon={getIcon(driver.status)}
                        >
                            <Popup>
                                <div style={{
                                    fontFamily: 'Inter, sans-serif',
                                    fontSize: '13px',
                                    lineHeight: 1.5,
                                    minWidth: 140,
                                }}>
                                    <strong>{driver.name}</strong>
                                    <br />
                                    <span style={{ textTransform: 'capitalize' }}>
                                        Status: {driver.status}
                                    </span>
                                    {driver.rating != null && (
                                        <>
                                            <br />
                                            Rating: {Number(driver.rating).toFixed(1)} ⭐
                                        </>
                                    )}
                                    {driver.vehicle && (
                                        <>
                                            <br />
                                            License: {driver.vehicle}
                                        </>
                                    )}
                                </div>
                            </Popup>
                        </Marker>
                    ))}
                </MapContainer>
            </div>
        </div>
    );
};

export default Fleet;
