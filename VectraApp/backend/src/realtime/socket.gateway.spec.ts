import { Test, TestingModule } from '@nestjs/testing';
import { SocketGateway } from './socket.gateway';

// ── Mock socket factory ────────────────────────────────────────────────────

const makeSocket = (id = 'client-socket-1') => ({
  id,
  emit: jest.fn(),
  join: jest.fn().mockResolvedValue(undefined),
  leave: jest.fn().mockResolvedValue(undefined),
});

// ── Mock Server ────────────────────────────────────────────────────────────

const makeServer = () => {
  const roomEmit = jest.fn();
  const toFn = jest.fn().mockReturnValue({ emit: roomEmit });
  return { to: toFn, _roomEmit: roomEmit };
};

// ═══════════════════════════════════════════════════════════════════════════

describe('SocketGateway', () => {
  let gateway: SocketGateway;
  let mockServer: ReturnType<typeof makeServer>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [SocketGateway],
    }).compile();

    gateway = module.get<SocketGateway>(SocketGateway);

    mockServer = makeServer();
    // Inject mock server
    (gateway as any).server = mockServer;
  });

  afterEach(() => jest.clearAllMocks());

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  describe('afterInit', () => {
    it('should log initialization without throwing', () => {
      expect(() => gateway.afterInit(mockServer as any)).not.toThrow();
    });
  });

  describe('handleConnection', () => {
    it('should log client connection without throwing', () => {
      const socket = makeSocket();
      expect(() => gateway.handleConnection(socket as any)).not.toThrow();
    });
  });

  describe('handleDisconnect', () => {
    it('should log client disconnection without throwing', () => {
      const socket = makeSocket();
      expect(() => gateway.handleDisconnect(socket as any)).not.toThrow();
    });
  });

  // ── handleAuthenticate ────────────────────────────────────────────────────

  describe('handleAuthenticate', () => {
    it('emits "authenticated" success back to the client', () => {
      const socket = makeSocket();
      gateway.handleAuthenticate({ token: 'valid.jwt.token' }, socket as any);
      expect(socket.emit).toHaveBeenCalledWith('authenticated', { status: 'success' });
    });

    it('does not throw even if token is empty string', () => {
      const socket = makeSocket();
      expect(() =>
        gateway.handleAuthenticate({ token: '' }, socket as any),
      ).not.toThrow();
      expect(socket.emit).toHaveBeenCalledWith('authenticated', { status: 'success' });
    });
  });

  // ── handleJoinTripRoom ────────────────────────────────────────────────────

  describe('handleJoinTripRoom', () => {
    it('calls socket.join with the correct room name', async () => {
      const socket = makeSocket();
      gateway.handleJoinTripRoom({ tripId: 'trip-abc' }, socket as any);
      // join is called asynchronously (void), wait tick
      await Promise.resolve();
      expect(socket.join).toHaveBeenCalledWith('trip_trip-abc');
    });

    it('does NOT call socket.join when tripId is empty string', async () => {
      const socket = makeSocket();
      gateway.handleJoinTripRoom({ tripId: '' }, socket as any);
      await Promise.resolve();
      expect(socket.join).not.toHaveBeenCalled();
    });

    it('does NOT throw when tripId is empty', () => {
      const socket = makeSocket();
      expect(() =>
        gateway.handleJoinTripRoom({ tripId: '' }, socket as any),
      ).not.toThrow();
    });
  });

  // ── handleLeaveTripRoom ───────────────────────────────────────────────────

  describe('handleLeaveTripRoom', () => {
    it('calls socket.leave with the correct room name', async () => {
      const socket = makeSocket();
      gateway.handleLeaveTripRoom({ tripId: 'trip-xyz' }, socket as any);
      await Promise.resolve();
      expect(socket.leave).toHaveBeenCalledWith('trip_trip-xyz');
    });

    it('does NOT call socket.leave when tripId is empty string', async () => {
      const socket = makeSocket();
      gateway.handleLeaveTripRoom({ tripId: '' }, socket as any);
      await Promise.resolve();
      expect(socket.leave).not.toHaveBeenCalled();
    });
  });

  // ── emitTripStatus ────────────────────────────────────────────────────────

  describe('emitTripStatus', () => {
    it('calls server.to(trip_<id>).emit("trip_status", ...) with correct payload', () => {
      gateway.emitTripStatus('trip-123', 'REQUESTED', { rideRequest: { id: 'req-1' } });

      expect(mockServer.to).toHaveBeenCalledWith('trip_trip-123');
      expect(mockServer._roomEmit).toHaveBeenCalledWith('trip_status', {
        tripId: 'trip-123',
        status: 'REQUESTED',
        rideRequest: { id: 'req-1' },
      });
    });

    it('uses default empty payload when no extra payload is provided', () => {
      gateway.emitTripStatus('trip-999', 'COMPLETED');

      expect(mockServer._roomEmit).toHaveBeenCalledWith('trip_status', {
        tripId: 'trip-999',
        status: 'COMPLETED',
      });
    });

    it('spreads extra payload into the emitted object', () => {
      gateway.emitTripStatus('trip-001', 'CANCELLED', { reason: 'rider cancelled' });

      expect(mockServer._roomEmit).toHaveBeenCalledWith(
        'trip_status',
        expect.objectContaining({ reason: 'rider cancelled', status: 'CANCELLED' }),
      );
    });

    it('works for all known trip statuses', () => {
      const statuses = ['REQUESTED', 'ACCEPTED', 'ARRIVING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'];
      for (const status of statuses) {
        jest.clearAllMocks();
        gateway.emitTripStatus('trip-all', status);
        expect(mockServer._roomEmit).toHaveBeenCalledWith(
          'trip_status',
          expect.objectContaining({ status }),
        );
      }
    });
  });

  // ── emitLocationUpdate ────────────────────────────────────────────────────

  describe('emitLocationUpdate', () => {
    it('calls server.to(trip_<id>).emit("location_update", ...) with lat/lng', () => {
      gateway.emitLocationUpdate('trip-123', 28.5, 77.5);

      expect(mockServer.to).toHaveBeenCalledWith('trip_trip-123');
      expect(mockServer._roomEmit).toHaveBeenCalledWith('location_update', {
        tripId: 'trip-123',
        lat: 28.5,
        lng: 77.5,
        etaSeconds: undefined,
      });
    });

    it('includes etaSeconds when provided', () => {
      gateway.emitLocationUpdate('trip-abc', 11.01, 76.95, 120);

      expect(mockServer._roomEmit).toHaveBeenCalledWith('location_update', {
        tripId: 'trip-abc',
        lat: 11.01,
        lng: 76.95,
        etaSeconds: 120,
      });
    });

    it('handles negative and zero coordinates (edge values)', () => {
      expect(() =>
        gateway.emitLocationUpdate('trip-edge', 0, 0),
      ).not.toThrow();

      expect(mockServer._roomEmit).toHaveBeenCalledWith(
        'location_update',
        expect.objectContaining({ lat: 0, lng: 0 }),
      );
    });
  });
});
