import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'models/transaction.dart';
import 'models/rate_card.dart';

class WalletRepository {
  final ApiClient _apiClient;

  WalletRepository(this._apiClient);

  Map<String, dynamic> _extractPayload(dynamic data) {
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is Map<String, dynamic>) return inner;
      return data;
    }
    return <String, dynamic>{};
  }

  String _mapTypeToBackend(TransactionType type) {
    switch (type) {
      case TransactionType.earning:
        return 'TRIP_FARE';
      case TransactionType.deduction:
        return 'WITHDRAWAL';
      case TransactionType.withdrawal:
        return 'WITHDRAWAL';
      case TransactionType.bonus:
        return 'WALLET_TOPUP';
      case TransactionType.refund:
        return 'REFUND';
    }
  }

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

  /// Get current wallet balance from GET /api/v1/payments/wallet
  Future<double> getBalance() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.wallet);
      final payload = _extractPayload(response.data);
      return (payload['balance'] as num?)?.toDouble() ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  Future<List<Transaction>> getTransactions({
    int page = 1,
    int limit = 20,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (type != null) queryParams['type'] = _mapTypeToBackend(type);
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await _apiClient.get(
        ApiEndpoints.walletTransactions,
        queryParameters: queryParams,
      );
      final list = _extractList(response.data);
      return list
          .whereType<Map<String, dynamic>>()
          .map(Transaction.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Request withdrawal (POST topup with negative or a dedicated endpoint)
  Future<void> requestWithdrawal(double amount) async {
    await _apiClient.post(
      ApiEndpoints.walletWithdraw,
      data: {'amount': amount},
    );
  }

  /// Get rate cards for all vehicle types
  Future<List<RateCard>> getRateCards() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.fareRateCards);
      final list = _extractList(response.data);
      return list.whereType<Map<String, dynamic>>().map(RateCard.fromJson).toList();
    } catch (_) {
      return [];
    }
  }
}
