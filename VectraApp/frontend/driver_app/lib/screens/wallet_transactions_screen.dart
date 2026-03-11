import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/wallet_service.dart';
import '../theme/app_colors.dart';

class WalletTransactionsScreen extends StatefulWidget {
  const WalletTransactionsScreen({super.key});

  @override
  State<WalletTransactionsScreen> createState() =>
      _WalletTransactionsScreenState();
}

class _WalletTransactionsScreenState extends State<WalletTransactionsScreen> {
  final List<WalletTransaction> _transactions = [];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  int _page = 1;
  static const int _limit = 20;
  String? _selectedType;

  static const List<String> _filterTypes = [
    'all',
    'earning',
    'bonus',
    'withdrawal',
    'refund',
  ];

  @override
  void initState() {
    super.initState();
    _loadTransactions(reset: true);
  }

  Future<void> _loadTransactions({required bool reset}) async {
    if (_isLoadingMore) return;

    if (reset) {
      setState(() {
        _isLoading = true;
        _page = 1;
        _hasMore = true;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final data = await WalletService().fetchTransactions(
        page: _page,
        limit: _limit,
        type: _selectedType,
      );

      if (!mounted) return;

      setState(() {
        if (reset) {
          _transactions
            ..clear()
            ..addAll(data);
        } else {
          _transactions.addAll(data);
        }

        _hasMore = data.length >= _limit;
        if (_hasMore) _page += 1;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  bool _isCreditType(String type) {
    const creditTypes = {'earning', 'bonus', 'refund'};
    return creditTypes.contains(type.toLowerCase());
  }

  String _titleFor(WalletTransaction tx) {
    if (tx.description.trim().isNotEmpty) return tx.description;
    switch (tx.type.toLowerCase()) {
      case 'earning':
        return 'Trip Earning';
      case 'bonus':
        return 'Wallet Top-up';
      case 'withdrawal':
        return 'Withdrawal';
      case 'refund':
        return 'Refund';
      default:
        return 'Wallet Transaction';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'All Transactions',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final type = _filterTypes[index];
                final selected = (_selectedType ?? 'all') == type;
                return ChoiceChip(
                  selected: selected,
                  label: Text(type == 'all' ? 'All' : _capitalize(type)),
                  selectedColor: AppColors.primary.withValues(alpha: 0.18),
                  onSelected: (_) {
                    setState(() {
                      _selectedType = type == 'all' ? null : type;
                    });
                    _loadTransactions(reset: true);
                  },
                );
              },
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemCount: _filterTypes.length,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _loadTransactions(reset: true),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _transactions.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _transactions.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: _isLoadingMore
                                  ? const CircularProgressIndicator()
                                  : OutlinedButton(
                                      onPressed: () => _loadTransactions(reset: false),
                                      child: const Text('Load More'),
                                    ),
                            ),
                          );
                        }

                        final tx = _transactions[index];
                        final credit = _isCreditType(tx.type);
                        return _buildTransactionTile(tx, credit);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(WalletTransaction tx, bool isCredit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isCredit ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ? AppColors.success : AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleFor(tx),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(tx.timestamp),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}₹${tx.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCredit ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
