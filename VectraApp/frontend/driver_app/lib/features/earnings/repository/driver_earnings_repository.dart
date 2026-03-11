import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../rides/data/models/trip.dart';

class DriverEarningsRepository {
  final ApiClient _apiClient;

  DriverEarningsRepository(this._apiClient);

  Future<Map<String, dynamic>> fetchEarningsData() async {
    try {
      // 1. Fetch wallet data
      double walletBalance = 0.0;
      try {
        final walletRes = await _apiClient.get(ApiEndpoints.walletBalance);
        if (walletRes.statusCode == 200) {
          walletBalance = double.parse(walletRes.data['balance']?.toString() ?? '0');
        }
      } catch (e) {
        debugPrint('Could not fetch wallet balance: $e');
      }

      // 2. Fetch trips
      List<Trip> allTrips = [];
      try {
        final tripRes = await _apiClient.get(ApiEndpoints.tripHistory);
        if (tripRes.statusCode == 200) {
          final List<dynamic> data = tripRes.data;
          allTrips = data.map((e) => Trip.fromJson(e)).toList();
        }
      } catch (e) {
        debugPrint('Could not fetch trips: $e');
      }

      // 3. Compute stats
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final weekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final monthStart = DateTime(now.year, now.month, 1);

      double todayEarnings = 0;
      double weekEarnings = 0;
      double monthEarnings = 0;
      int todayTrips = 0;
      int weekTrips = 0;
      int monthTrips = 0;

      for (var trip in allTrips) {
        if (trip.status == TripStatus.completed && trip.completedAt != null) {
          final completedAt = trip.completedAt!;
          
          if (completedAt.isAfter(monthStart) || completedAt.isAtSameMomentAs(monthStart)) {
            monthEarnings += trip.fare;
            monthTrips++;
          }
          
          if (completedAt.isAfter(weekStart) || completedAt.isAtSameMomentAs(weekStart)) {
            weekEarnings += trip.fare;
            weekTrips++;
          }
          
          if (completedAt.isAfter(today) || completedAt.isAtSameMomentAs(today)) {
            todayEarnings += trip.fare;
            todayTrips++;
          }
        }
      }

      return {
        'walletBalance': walletBalance,
        'todayEarnings': todayEarnings,
        'weekEarnings': weekEarnings,
        'monthEarnings': monthEarnings,
        'todayTrips': todayTrips,
        'weekTrips': weekTrips,
        'monthTrips': monthTrips,
        'totalTrips': allTrips.length,
      };
    } catch (e) {
      throw Exception('Failed to fetch earning data: $e');
    }
  }
}

final driverEarningsRepositoryProvider = Provider<DriverEarningsRepository>((ref) {
  return DriverEarningsRepository(ref.watch(apiClientProvider));
});
