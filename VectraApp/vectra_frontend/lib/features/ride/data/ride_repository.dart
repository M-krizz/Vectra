import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

final rideRepositoryProvider = Provider((ref) => RideRepository(DioClient()));

class RideRepository {
  final DioClient _client;

  RideRepository(this._client);

  Future<Map<String, dynamic>> createRequest(Map<String, dynamic> requestData) async {
    final response = await _client.dio.post('/ride-requests', data: requestData);
    return response.data;
  }

  Future<Map<String, dynamic>> getTrip(String tripId) async {
    final response = await _client.dio.get('/trips/$tripId');
    return response.data;
  }
}

// State for active trip polling
final activeTripProvider = StateNotifierProvider.autoDispose<ActiveTripNotifier, AsyncValue<Map<String, dynamic>?>>((ref) {
  return ActiveTripNotifier(ref);
});

class ActiveTripNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final Ref _ref;
  Timer? _timer;

  ActiveTripNotifier(this._ref) : super(const AsyncValue.data(null));

  void startPolling(String tripId) {
    _fetchTrip(tripId);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchTrip(tripId));
  }

  Future<void> _fetchTrip(String tripId) async {
    try {
      final trip = await _ref.read(rideRepositoryProvider).getTrip(tripId);
      state = AsyncValue.data(trip);
      
      if (trip['status'] == 'COMPLETED' || trip['status'] == 'CANCELLED') {
        _timer?.cancel();
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
