import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/app_theme.dart';
import '../bloc/ride_bloc.dart';
import 'payment_selection_screen.dart';

class FareBreakdownScreen extends StatelessWidget {
  const FareBreakdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RideBloc, RideState>(
      builder: (context, state) {
        final baseFare = state.selectedVehicle?.fare ?? 85.0;
        final isPool = state.rideType == 'pool';
        final poolDiscount = isPool ? baseFare * 0.3 : 0.0;
        final subtotal = baseFare - poolDiscount;
        const tax = 8.5;
        final total = subtotal + tax;

        final items = [
          _FareItem('Base fare', baseFare),
          _FareItem('Distance charge (4.2 km)', 18.0),
          _FareItem('Platform fee', 5.0),
          if (isPool) _FareItem('Pool discount', -poolDiscount, isDiscount: true),
          _FareItem('Taxes & charges', tax),
        ];

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Fare Breakdown',
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
              // Ride info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  Text(
                    isPool ? '🚌' : '🚗',
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        state.selectedVehicle?.name ?? 'Vehicle',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const Text(
                        '4.2 km  •  14 min',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ]),
                  ),
                  Text(
                    '₹${total.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                  ),
                ]),
              ),

              const SizedBox(height: 24),
              const Text('Fare Details',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 12),

              // Line items
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    ...items.asMap().entries.map((e) => Column(children: [
                      _FareRow(item: e.value),
                      if (e.key < items.length - 1)
                        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
                    ])),
                    Container(height: 1, color: AppColors.border),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          Text('₹${total.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ],
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
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaymentSelectionScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Proceed to Pay  ₹${85}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FareItem {
  final String label;
  final double amount;
  final bool isDiscount;
  const _FareItem(this.label, this.amount, {this.isDiscount = false});
}

class _FareRow extends StatelessWidget {
  final _FareItem item;
  const _FareRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(item.label,
              style: TextStyle(
                  fontSize: 14,
                  color: item.isDiscount ? const Color(0xFF2E7D32) : AppColors.textSecondary)),
          Text(
            '${item.isDiscount ? '-' : ''}₹${item.amount.abs().toStringAsFixed(0)}',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: item.isDiscount ? const Color(0xFF2E7D32) : AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
