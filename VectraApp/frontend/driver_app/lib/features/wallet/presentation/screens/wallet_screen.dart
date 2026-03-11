import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_colors.dart';
import '../../data/models/transaction.dart';
import '../providers/wallet_providers.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  TransactionFilter _filter = const TransactionFilter();

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(walletBalanceProvider);
    final transactionsAsync = ref.watch(transactionsProvider(_filter));
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.carbonGrey : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Wallet',
          style: GoogleFonts.outfit(
            color: colors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: colors.onSurface),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletBalanceProvider);
          ref.invalidate(transactionsProvider(_filter));
        },
        color: isDark ? AppColors.hyperLime : colors.primary,
        backgroundColor: isDark ? AppColors.carbonGrey : Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              balanceAsync.when(
                data: (balance) => _buildBalanceCard(balance, colors, isDark),
                loading: () => _buildBalanceCardLoading(colors, isDark),
                error: (error, stack) => _buildBalanceCardError(),
              ),
              const SizedBox(height: 24),
              _buildFilterChips(colors, isDark),
              const SizedBox(height: 16),
              transactionsAsync.when(
                data: (transactions) => _buildTransactionsList(transactions, colors, isDark),
                loading: () => _buildTransactionsLoading(colors, isDark),
                error: (error, stack) => _buildTransactionsError(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance, ColorScheme colors, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.hyperLime, AppColors.neonGreen]
              : [colors.primary, colors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.hyperLime : colors.primary).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Balance',
            style: GoogleFonts.dmSans(
              color: isDark ? Colors.black87 : Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\u20B9${balance.toStringAsFixed(2)}',
            style: GoogleFonts.outfit(
              color: isDark ? Colors.black : Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              // TODO: Implement withdrawal
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance, color: isDark ? AppColors.hyperLime : colors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Withdraw',
                    style: GoogleFonts.dmSans(
                      color: isDark ? AppColors.hyperLime : colors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2);
  }

  Widget _buildBalanceCardLoading(ColorScheme colors, bool isDark) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: isDark ? AppColors.carbonGrey : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Center(
        child: CircularProgressIndicator(color: isDark ? AppColors.hyperLime : colors.primary),
      ),
    );
  }

  Widget _buildBalanceCardError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.errorRed),
      ),
      child: Text(
        'Failed to load balance',
        style: GoogleFonts.dmSans(color: AppColors.errorRed),
      ),
    );
  }

  Widget _buildFilterChips(ColorScheme colors, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All', _filter.type == null, () {
            setState(() => _filter = _filter.copyWith(clearType: true));
          }, colors, isDark),
          const SizedBox(width: 8),
          _buildFilterChip('Earnings', _filter.type == TransactionType.earning, () {
            setState(() => _filter = _filter.copyWith(type: TransactionType.earning));
          }, colors, isDark),
          const SizedBox(width: 8),
          _buildFilterChip('Deductions', _filter.type == TransactionType.deduction, () {
            setState(() => _filter = _filter.copyWith(type: TransactionType.deduction));
          }, colors, isDark),
          const SizedBox(width: 8),
          _buildFilterChip('Withdrawals', _filter.type == TransactionType.withdrawal, () {
            setState(() => _filter = _filter.copyWith(type: TransactionType.withdrawal));
          }, colors, isDark),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, ColorScheme colors, bool isDark) {
    final accent = isDark ? AppColors.hyperLime : colors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accent : (isDark ? AppColors.carbonGrey : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accent : (isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
          ),
          boxShadow: !isDark && !isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : colors.onSurface,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList(List<Transaction> transactions, ColorScheme colors, bool isDark) {
    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No transactions found',
            style: GoogleFonts.dmSans(color: colors.onSurfaceVariant),
          ),
        ),
      );
    }

    return Column(
      children: transactions.map((transaction) {
        return _buildTransactionCard(transaction, colors, isDark);
      }).toList(),
    );
  }

  Widget _buildTransactionCard(Transaction transaction, ColorScheme colors, bool isDark) {
    final isPositive = transaction.type == TransactionType.earning ||
        transaction.type == TransactionType.bonus ||
        transaction.type == TransactionType.refund;

    final color = isPositive ? AppColors.successGreen : AppColors.errorRed;
    final icon = _getTransactionIcon(transaction.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.carbonGrey : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.white10 : colors.outline.withValues(alpha: 0.2)),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: GoogleFonts.dmSans(
                    color: colors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy \u2022 hh:mm a').format(transaction.timestamp),
                  style: GoogleFonts.dmSans(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : '-'}\u20B9${transaction.amount.toStringAsFixed(2)}',
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1);
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.earning:
        return Icons.trending_up;
      case TransactionType.deduction:
        return Icons.trending_down;
      case TransactionType.withdrawal:
        return Icons.account_balance;
      case TransactionType.bonus:
        return Icons.card_giftcard;
      case TransactionType.refund:
        return Icons.refresh;
    }
  }

  Widget _buildTransactionsLoading(ColorScheme colors, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: CircularProgressIndicator(color: isDark ? AppColors.hyperLime : colors.primary),
      ),
    );
  }

  Widget _buildTransactionsError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Failed to load transactions',
          style: GoogleFonts.dmSans(color: AppColors.errorRed),
        ),
      ),
    );
  }
}