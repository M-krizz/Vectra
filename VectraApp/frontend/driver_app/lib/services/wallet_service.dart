import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/storage/secure_storage_service.dart';

class WalletTransaction {
  final String id;
  final String type;
  final double amount;
  final String description;
  final DateTime timestamp;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.timestamp,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? 'earning').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: (json['description'] ?? 'Wallet transaction').toString(),
      timestamp: DateTime.tryParse((json['timestamp'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class WalletRateCard {
  final String vehicleType;
  final double baseFare;
  final double perKmRate;
  final double waitingChargePerMin;
  final double cancellationFee;

  WalletRateCard({
    required this.vehicleType,
    required this.baseFare,
    required this.perKmRate,
    required this.waitingChargePerMin,
    required this.cancellationFee,
  });

  factory WalletRateCard.fromJson(Map<String, dynamic> json) {
    final slabs = json['distanceSlabs'] as List?;
    final firstSlab =
        (slabs != null && slabs.isNotEmpty) ? slabs.first as Map? : null;

    return WalletRateCard(
      vehicleType: (json['vehicleType'] ?? 'mini').toString(),
      baseFare: (json['baseFare'] as num?)?.toDouble() ?? 0.0,
      perKmRate: (firstSlab?['ratePerKm'] as num?)?.toDouble() ?? 0.0,
      waitingChargePerMin:
          (json['waitingChargePerMin'] as num?)?.toDouble() ?? 0.0,
      cancellationFee: (json['cancellationFee'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WalletService {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  final SecureStorageService _storage = SecureStorageService();
  late final ApiClient _apiClient = ApiClient(storage: _storage);

  final ValueNotifier<double> balanceNotifier = ValueNotifier(0.0);
  final ValueNotifier<List<WalletTransaction>> transactionsNotifier =
      ValueNotifier<List<WalletTransaction>>([]);
  final ValueNotifier<bool> transactionsLoadingNotifier =
      ValueNotifier<bool>(false);
  final ValueNotifier<List<WalletRateCard>> rateCardsNotifier =
      ValueNotifier<List<WalletRateCard>>([]);
  final ValueNotifier<bool> rateCardsLoadingNotifier =
      ValueNotifier<bool>(false);
  bool _initialized = false;

  double get balance => balanceNotifier.value;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await Future.wait([
      refreshBalance(),
      refreshTransactions(),
      refreshRateCards(),
    ]);
  }

  Future<void> refreshBalance() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.walletBalance);
      final data = response.data;
      final payload = data is Map<String, dynamic>
          ? (data['data'] is Map<String, dynamic>
                ? data['data'] as Map<String, dynamic>
                : data)
          : <String, dynamic>{};

      final balance = (payload['balance'] as num?)?.toDouble() ?? 0.0;
      balanceNotifier.value = balance;
    } catch (_) {
      // Keep previous value when refresh fails.
    }
  }

  Future<bool> addMoney(double amount) async {
    try {
      await _apiClient.post(
        ApiEndpoints.walletTopup,
        data: {'amount': amount},
      );
      await Future.wait([refreshBalance(), refreshTransactions()]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> withdrawMoney(double amount) async {
    try {
      await _apiClient.post(
        ApiEndpoints.walletWithdraw,
        data: {'amount': amount},
      );
      await Future.wait([refreshBalance(), refreshTransactions()]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> refreshTransactions({int limit = 10}) async {
    transactionsLoadingNotifier.value = true;
    try {
      transactionsNotifier.value = await fetchTransactions(limit: limit);
    } catch (_) {
      // Keep previous transactions on failure.
    } finally {
      transactionsLoadingNotifier.value = false;
    }
  }

  Future<List<WalletTransaction>> fetchTransactions({
    int page = 1,
    int limit = 20,
    String? type,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (type != null && type.isNotEmpty) {
      query['type'] = _mapTypeToBackend(type);
    }

    final response = await _apiClient.get(
      ApiEndpoints.walletTransactions,
      queryParameters: query,
    );

    final data = response.data;
    final payload = data is Map<String, dynamic>
        ? (data['data'] is Map<String, dynamic>
              ? data['data'] as Map<String, dynamic>
              : data)
        : <String, dynamic>{};

    final rawItems = payload['items'] is List ? payload['items'] as List : const [];
    return rawItems
        .whereType<Map>()
        .map((e) => WalletTransaction.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  String _mapTypeToBackend(String type) {
    switch (type.toLowerCase()) {
      case 'earning':
        return 'TRIP_FARE';
      case 'bonus':
        return 'WALLET_TOPUP';
      case 'withdrawal':
        return 'WITHDRAWAL';
      case 'refund':
        return 'REFUND';
      default:
        return type;
    }
  }

  Future<void> refreshRateCards() async {
    rateCardsLoadingNotifier.value = true;
    try {
      final response = await _apiClient.get(ApiEndpoints.fareRateCards);
      final data = response.data;
      final payload = data is Map<String, dynamic>
          ? (data['data'] is Map<String, dynamic>
                ? data['data'] as Map<String, dynamic>
                : data)
          : <String, dynamic>{};

      final rawItems = payload['items'] is List ? payload['items'] as List : const [];
      rateCardsNotifier.value = rawItems
          .whereType<Map>()
          .map((e) => WalletRateCard.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      // Keep previous rate cards on failure.
    } finally {
      rateCardsLoadingNotifier.value = false;
    }
  }
}
