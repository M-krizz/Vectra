import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../services/wallet_service.dart';
import '../utils/notification_overlay.dart';
import 'wallet_transactions_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WalletService().initialize();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Wallet',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Balance',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<double>(
                    valueListenable: WalletService().balanceNotifier,
                    builder: (context, balance, _) {
                      return Text(
                        '₹${balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          context,
                          icon: Icons.add,
                          label: 'Add Money',
                          onTap: () => _showAddMoneyDialog(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          context,
                          icon: Icons.arrow_outward,
                          label: 'Withdraw',
                          onTap: () => _showWithdrawDialog(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Transaction History Header with View All
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WalletTransactionsScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            ValueListenableBuilder<bool>(
              valueListenable: WalletService().transactionsLoadingNotifier,
              builder: (context, loading, _) {
                if (loading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return ValueListenableBuilder<List<WalletTransaction>>(
                  valueListenable: WalletService().transactionsNotifier,
                  builder: (context, transactions, _) {
                    if (transactions.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'No transactions yet',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }

                    return Column(
                      children: transactions
                          .map(
                            (tx) => _buildTransactionItem(
                              title: tx.description,
                              date: DateFormat('MMM dd, hh:mm a').format(tx.timestamp),
                              amount:
                                  '${_isCreditType(tx.type) ? '+' : '-'}₹${tx.amount.toStringAsFixed(2)}',
                              isCredit: _isCreditType(tx.type),
                            ),
                          )
                          .toList(),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            const Text(
              'Rate Card',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 16),

            ValueListenableBuilder<bool>(
              valueListenable: WalletService().rateCardsLoadingNotifier,
              builder: (context, loading, _) {
                if (loading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return ValueListenableBuilder<List<WalletRateCard>>(
                  valueListenable: WalletService().rateCardsNotifier,
                  builder: (context, cards, _) {
                    if (cards.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Rate card unavailable',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }

                    return Column(
                      children: cards
                          .map(
                            (card) => _buildRateCardItem(card),
                          )
                          .toList(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateCardItem(WalletRateCard card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatVehicleType(card.vehicleType),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Base Fare: ₹${card.baseFare.toStringAsFixed(0)}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            'Per Km: ₹${card.perKmRate.toStringAsFixed(2)}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            'Waiting / min: ₹${card.waitingChargePerMin.toStringAsFixed(2)}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            'Cancellation: ₹${card.cancellationFee.toStringAsFixed(0)}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _formatVehicleType(String value) {
    if (value.isEmpty) return 'Vehicle';
    final normalized = value.replaceAll('_', ' ').toLowerCase();
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  bool _isCreditType(String type) {
    const creditTypes = {'earning', 'bonus', 'refund'};
    return creditTypes.contains(type.toLowerCase());
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem({
    required String title,
    required String date,
    required String amount,
    required bool isCredit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCredit
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ? AppColors.success : AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isCredit ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMoneyDialog(BuildContext context) {
    _amountController.clear();
    final screenContext = this.context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [100, 500, 1000].map((amount) {
                return ActionChip(
                  label: Text('₹$amount'),
                  onPressed: () {
                    _amountController.text = amount.toString();
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amountStr = _amountController.text;
              final amount = double.tryParse(amountStr);

              if (amount != null && amount > 0) {
                final success = await WalletService().addMoney(amount);
                if (!mounted || !dialogContext.mounted || !screenContext.mounted) {
                  return;
                }

                if (success) {
                  Navigator.pop(dialogContext);
                  NotificationOverlay.showMessage(
                    screenContext,
                    'Rs $amount added to wallet.',
                    backgroundColor: AppColors.success,
                  );
                } else {
                  NotificationOverlay.showMessage(
                    screenContext,
                    'Top-up failed. Check your amount and try again.',
                    backgroundColor: AppColors.error,
                  );
                }
              } else {
                NotificationOverlay.showMessage(
                  screenContext,
                  'Please enter a valid amount',
                  backgroundColor: AppColors.error,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Money'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context) {
    _amountController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<double>(
              valueListenable: WalletService().balanceNotifier,
              builder: (context, balance, _) {
                return Text(
                  'Available Balance: ₹${balance.toStringAsFixed(2)}',
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount to Withdraw',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amountStr = _amountController.text;
              final amount = double.tryParse(amountStr);

              if (amount == null || amount <= 0) {
                NotificationOverlay.showMessage(
                  context,
                  'Please enter a valid amount',
                  backgroundColor: AppColors.error,
                );
                return;
              }

              if (amount > WalletService().balance) {
                NotificationOverlay.showMessage(
                  context,
                  'Insufficient balance',
                  backgroundColor: AppColors.error,
                );
                return;
              }

              final success = await WalletService().withdrawMoney(amount);
              if (!mounted || !context.mounted) return;

              if (success) {
                Navigator.pop(context);
                NotificationOverlay.showMessage(
                  this.context,
                  'Rs $amount withdrawn successfully.',
                  backgroundColor: AppColors.success,
                );
              } else {
                NotificationOverlay.showMessage(
                  this.context,
                  'Withdrawal failed. Please retry.',
                  backgroundColor: AppColors.error,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }
}
