import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:rider_app/features/ride/bloc/ride_bloc.dart';
import 'package:rider_app/features/ride/models/place_model.dart';
import 'package:rider_app/features/ride/repository/places_repository.dart';
import 'package:rider_app/features/ride/repository/ride_repository.dart';
import 'package:rider_app/features/ride/services/trip_socket_service.dart';

// Mocks
class MockPlacesRepository extends Mock implements PlacesRepository {}
class MockRideRepository extends Mock implements RideRepository {}
class MockTripSocketService extends Mock implements TripSocketService {}

void main() {
  group('RideBloc Integration Flow', () {
    late RideBloc rideBloc;
    late MockPlacesRepository mockPlacesRepository;
    late MockRideRepository mockRideRepository;
    late MockTripSocketService mockTripSocketService;
    
    // Controllers to simulate socket streams
    late StreamController<TripStatusEvent> tripStatusController;
    late StreamController<LocationUpdateEvent> locationController;

    const mockPickup = PlaceModel(
      placeId: 'p1',
      name: 'Pickup Point',
      address: '123 Start St',
      location: LatLng(10.0, 20.0),
    );

    const mockDestination = PlaceModel(
      placeId: 'd1',
      name: 'Drop Point',
      address: '456 End St',
      location: LatLng(10.1, 20.1),
    );

    const mockVehicle = VehicleOption(
      id: 'auto',
      name: 'Auto',
      description: '3-wheeler',
      imageUrl: 'auto.png',
      fare: 50.0,
      etaMinutes: 2,
      capacity: 3,
    );

    setUpAll(() {
      registerFallbackValue(const PlaceModel(
        placeId: 'dummy',
        name: 'Dummy',
        address: 'Dummy Address',
      ));
    });

    setUp(() {
      mockPlacesRepository = MockPlacesRepository();
      mockRideRepository = MockRideRepository();
      mockTripSocketService = MockTripSocketService();

      tripStatusController = StreamController<TripStatusEvent>.broadcast();
      locationController = StreamController<LocationUpdateEvent>.broadcast();

      when(() => mockTripSocketService.tripStatusStream)
          .thenAnswer((_) => tripStatusController.stream);
      when(() => mockTripSocketService.locationStream)
          .thenAnswer((_) => locationController.stream);

      rideBloc = RideBloc(
        placesRepository: mockPlacesRepository,
        rideRepository: mockRideRepository,
        tripSocketService: mockTripSocketService,
      );
    });

    tearDown(() {
      rideBloc.close();
      tripStatusController.close();
      locationController.close();
    });

    blocTest<RideBloc, RideState>(
      'Simulates full booking flow with Socket Events',
      build: () {
        when(() => mockRideRepository.requestRide(
              pickup: any(named: 'pickup'),
              destination: any(named: 'destination'),
              rideType: any(named: 'rideType'),
              vehicleId: any(named: 'vehicleId'),
              estimatedFare: any(named: 'estimatedFare'),
              distanceMeters: any(named: 'distanceMeters'),
            )).thenAnswer((_) async => {'rideId': 'T123'});
        return rideBloc;
      },
      seed: () => const RideState(
        pickup: mockPickup,
        destination: mockDestination,
        rideType: 'solo',
        selectedVehicle: mockVehicle,
      ),
      act: (bloc) async {
        // 1. Request Ride via API
        bloc.add(const RideRequested());
        
        // Let event loop process
        await Future.delayed(Duration.zero);
        
        // 2. Simulate Backend emitting 'ASSIGNED' over sockets
        tripStatusController.add(TripStatusEvent(
          tripId: 'T123',
          status: 'ASSIGNED',
          payload: {'driverName': 'Test Driver'},
        ));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        // Emitted after RideRequested event triggers loading state
        isA<RideState>()
            .having((s) => s.status, 'status', RideStatus.searching)
            .having((s) => s.isLoading, 'isLoading', true),
        // Emitted after repository responds with successful ride ID
        isA<RideState>()
            .having((s) => s.status, 'status', RideStatus.searching)
            .having((s) => s.isLoading, 'isLoading', true)
            .having((s) => s.rideId, 'rideId', 'T123'),
        // Emitted when Socket stream emits 'ASSIGNED'
        isA<RideState>()
            .having((s) => s.status, 'status', RideStatus.driverFound)
            .having((s) => s.rideId, 'rideId', 'T123'),
      ],
      verify: (_) {
        verify(() => mockRideRepository.requestRide(
          pickup: mockPickup,
          destination: mockDestination,
          rideType: 'solo',
          vehicleId: 'auto',
          estimatedFare: 50.0,
          distanceMeters: 0.0,
        )).called(1);
      },
    );

    blocTest<RideBloc, RideState>(
      'Handles CANCELLED socket event correctly',
      build: () => rideBloc,
      seed: () => const RideState(
        pickup: mockPickup,
        destination: mockDestination,
        rideType: 'solo',
        selectedVehicle: mockVehicle,
        status: RideStatus.searching,
        rideId: 'T123',
      ),
      act: (bloc) {
        tripStatusController.add(TripStatusEvent(
          tripId: 'T123',
          status: 'CANCELLED',
          payload: {'reason': 'Driver cancelled'},
        ));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<RideState>()
            .having((s) => s.status, 'status', RideStatus.cancelled)
            .having((s) => s.cancellationReason, 'cancellationReason', 'Driver cancelled'),
      ],
    );
  });
}
