import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'models/incentive.dart';

class IncentivesRepository {
  final ApiClient _apiClient;

  IncentivesRepository(this._apiClient);

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is List) return inner;
      if (inner is Map<String, dynamic> && inner['items'] is List) {
        return inner['items'] as List;
      }
      if (data['items'] is List) return data['items'] as List;
    }
    return const [];
  }

  Future<List<Incentive>> getActiveIncentives() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.incentivesActive);
      return _extractList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(Incentive.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Incentive>> getCompletedIncentives() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.incentivesCompleted);
      return _extractList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(Incentive.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
