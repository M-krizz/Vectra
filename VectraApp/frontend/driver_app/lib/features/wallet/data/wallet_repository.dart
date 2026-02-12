import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/storage/secure_storage_service.dart';
import 'models/transaction.dart';
import 'models/rate_card.dart';

class WalletRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  WalletRepository(this._apiClient, this._storage);

  /// Get current wallet balance
  Future<double> getBalance() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 1250.75;
  }

  Future<List<Transaction>> getTransactions({
    int page = 1,
    int limit = 20,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [];
  }

  /// Request withdrawal
  Future<void> requestWithdrawal(double amount) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  /// Get rate cards for all vehicle types
  Future<List<RateCard>> getRateCards() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }
}
