import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'models/incentive.dart';

class IncentivesRepository {
  final ApiClient _apiClient;

  IncentivesRepository(this._apiClient);

  Future<List<Incentive>> getActiveIncentives() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return []; // Return empty list or mock data
  }

  Future<List<Incentive>> getCompletedIncentives() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return []; 
  }
}
