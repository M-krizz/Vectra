import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/app_theme.dart';
import '../bloc/ride_bloc.dart';
import 'receipt_screen.dart';

class PaymentSelectionScreen extends StatefulWidget {
  const PaymentSelectionScreen({super.key});

  @override
  State<PaymentSelectionScreen> createState() => _PaymentSelectionScreenState();
}

class _PaymentSelectionScreenState extends State<PaymentSelectionScreen> {
  String _selected = 'upi';

  static const _methods = [
    _PayMethod(id: 'upi', label: 'UPI / Google Pay', icon: Icons.payment_rounded, desc: 'Pay via any UPI app'),
    _PayMethod(id: 'card', label: 'Debit / Credit Card', icon: Icons.credit_card_rounded, desc: '•••• •••• •••• 4242'),
    _PayMethod(id: 'wallet', label: 'Vectra Wallet', icon: Icons.account_balance_wallet_rounded, desc: 'Balance: ₹250'),
    _PayMethod(id: 'cash', label: 'Cash', icon: Icons.money_rounded, desc: 'Pay the driver directly'),
  ];

  void _pay() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ReceiptScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RideBloc, RideState>(
      builder: (context, state) {
        final total = (state.finalFare ?? state.selectedVehicle?.fare ?? 85.0) + 8.5;
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Select Payment',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppColors.border),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Amount header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Amount Due',
                            style: TextStyle(fontSize: 13, color: Colors.white70)),
                        SizedBox(height: 4),
                      ],
                    ),
                    Text('₹${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text('Payment Methods',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: _methods.asMap().entries.map((e) {
                    final m = e.value;
                    final selected = _selected == m.id;
                    return Column(children: [
                      InkWell(
                        onTap: () => setState(() => _selected = m.id),
                        borderRadius: e.key == 0
                            ? const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14))
                            : BorderRadius.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: selected ? const Color(0xFFE8F0FE) : const Color(0xFFF5F7FA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(m.icon,
                                  size: 22,
                                  color: selected ? AppColors.primary : AppColors.textSecondary),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(m.label,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: selected ? AppColors.primary : AppColors.textPrimary)),
                                Text(m.desc,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ]),
                            ),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: selected ? AppColors.primary : AppColors.border, width: 2),
                                color: selected ? AppColors.primary : Colors.transparent,
                              ),
                              child: selected
                                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                                  : null,
                            ),
                          ]),
                        ),
                      ),
                      if (e.key < _methods.length - 1)
                        const Divider(height: 1, indent: 74, endIndent: 0, color: AppColors.divider),
                    ]);
                  }).toList(),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _pay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Pay ₹${total.toStringAsFixed(0)} via ${_methods.firstWhere((m) => m.id == _selected).label}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PayMethod {
  final String id;
  final String label;
  final IconData icon;
  final String desc;
  const _PayMethod({required this.id, required this.label, required this.icon, required this.desc});
}
