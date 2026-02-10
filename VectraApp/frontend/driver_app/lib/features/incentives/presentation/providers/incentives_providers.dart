import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/incentives_repository.dart';
import '../../data/models/incentive.dart';
import '../../../../core/api/api_client.dart';

final incentivesRepositoryProvider = Provider<IncentivesRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return IncentivesRepository(apiClient);
});

final activeIncentivesProvider = FutureProvider<List<Incentive>>((ref) async {
  final repository = ref.watch(incentivesRepositoryProvider);
  return await repository.getActiveIncentives();
});

final completedIncentivesProvider = FutureProvider<List<Incentive>>((ref) async {
  final repository = ref.watch(incentivesRepositoryProvider);
  return await repository.getCompletedIncentives();
});
