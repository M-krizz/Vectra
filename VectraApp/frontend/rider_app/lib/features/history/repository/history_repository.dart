import 'package:shared/shared.dart';
import '../models/ride_history_model.dart';

class HistoryRepository {
  final ApiClient _apiClient;

  HistoryRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<RideHistoryModel>> getRideHistory() async {
    final response = await _apiClient.get('/api/v1/trips');
    final List data = response.data as List;
    return data.map((json) => RideHistoryModel.fromJson(json)).toList();
  }
}
