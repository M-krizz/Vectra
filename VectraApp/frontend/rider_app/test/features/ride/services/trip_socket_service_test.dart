import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:rider_app/features/ride/services/trip_socket_service.dart';

// Mocks
class MockSocket extends Mock implements IO.Socket {}

void main() {
  group('TripSocketService', () {
    late TripSocketService socketService;
    late MockSocket mockSocket;

    setUp(() {
      mockSocket = MockSocket();
      
      // Override the builder to return our mock socket
      socketService = TripSocketService(
        baseUrl: 'http://localhost',
        socketBuilder: (_, __) => mockSocket,
      );
      
      // Setup mock behaviors for socket event listeners
      when(() => mockSocket.on(any(), any())).thenReturn(() {});
      when(() => mockSocket.onConnect(any())).thenReturn(() {});
      when(() => mockSocket.onDisconnect(any())).thenReturn(() {});
      when(() => mockSocket.onConnectError(any())).thenReturn(() {});

      // 'connect' and 'disconnect' usually return the socket itself or void
      when(() => mockSocket.connect()).thenReturn(mockSocket);
      when(() => mockSocket.disconnect()).thenReturn(mockSocket);
      // emit method doesn't return anything or returns void, we can omit thenReturn or stub it properly if needed
      // Actually, Mock automatically handles void returns if we don't stub it, or we can use:
    });

    tearDown(() {
      socketService.dispose();
    });

    test('connect() initializes socket and registers listeners', () {
      socketService.connect(token: 'dummy_token');

      verify(() => mockSocket.onConnect(any())).called(1);
      verify(() => mockSocket.onDisconnect(any())).called(1);
      verify(() => mockSocket.on('trip_status', any())).called(1);
      verify(() => mockSocket.on('location_update', any())).called(1);
      verify(() => mockSocket.connect()).called(1);
    });

    test('Streams incoming trip_status events', () async {
      socketService.connect(token: 'dummy_token');

      // Capture the callback registered for 'trip_status'
      final capturedCalls = verify(() => mockSocket.on('trip_status', captureAny())).captured;
      final Function tripStatusCallback = capturedCalls.first;

      // Expect specific stream output
      expectLater(
        socketService.tripStatusStream,
        emits(isA<TripStatusEvent>()
            .having((e) => e.tripId, 'tripId', 'T123')
            .having((e) => e.status, 'status', 'ASSIGNED')),
      );

      // Simulate the socket receiving a 'trip_status' event
      tripStatusCallback({
        'tripId': 'T123',
        'status': 'ASSIGNED',
        'payload': {'driverName': 'Test'}
      });
    });

    test('joinTripRoom emits join_trip_room to socket', () {
      socketService.connect(token: 'dummy_token');
      socketService.joinTripRoom('T123');

      verify(() => mockSocket.emit('join_trip_room', {'tripId': 'T123'})).called(1);
    });

    test('Socket disconnect updates connectionStream to false', () async {
      socketService.connect(token: 'dummy_token');

      // Capture the onDisconnect handler
      final capturedCalls = verify(() => mockSocket.onDisconnect(captureAny())).captured;
      final Function onDisconnectCallback = capturedCalls.first;

      // Expect specific stream output
      expectLater(
        socketService.connectionStream,
        emits(false),
      );

      // Trigger the disconnect callback
      onDisconnectCallback('transport close');
    });
  });
}
