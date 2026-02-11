import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/wallet_repository.dart';
import '../../data/models/transaction.dart';
import '../../data/models/rate_card.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';

// Repository provider
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return WalletRepository(apiClient, storage);
});

// Balance provider
final walletBalanceProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(walletRepositoryProvider);
  return await repository.getBalance();
});

// Transactions provider
final transactionsProvider = FutureProvider.family<List<Transaction>, TransactionFilter>(
  (ref, filter) async {
    final repository = ref.watch(walletRepositoryProvider);
    return await repository.getTransactions(
      page: filter.page,
      limit: filter.limit,
      type: filter.type,
      startDate: filter.startDate,
      endDate: filter.endDate,
    );
  },
);

// Rate cards provider
final rateCardsProvider = FutureProvider<List<RateCard>>((ref) async {
  final repository = ref.watch(walletRepositoryProvider);
  return await repository.getRateCards();
});

// Transaction filter model
class TransactionFilter {
  final int page;
  final int limit;
  final TransactionType? type;
  final DateTime? startDate;
  final DateTime? endDate;

  const TransactionFilter({
    this.page = 1,
    this.limit = 20,
    this.type,
    this.startDate,
    this.endDate,
  });

  TransactionFilter copyWith({
    int? page,
    int? limit,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
    bool clearType = false,
    bool clearDates = false,
  }) {
    return TransactionFilter(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      type: clearType ? null : (type ?? this.type),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionFilter &&
          runtimeType == other.runtimeType &&
          page == other.page &&
          limit == other.limit &&
          type == other.type &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode =>
      page.hashCode ^
      limit.hashCode ^
      type.hashCode ^
      startDate.hashCode ^
      endDate.hashCode;
}
