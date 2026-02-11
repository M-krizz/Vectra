import 'package:flutter/material.dart';

/// Screen for managing payment methods
class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  String _selectedMethod = 'cash';

  final List<PaymentMethod> _paymentMethods = [
    const PaymentMethod(
      id: 'cash',
      name: 'Cash',
      icon: Icons.money,
      description: 'Pay with cash after your ride',
      type: PaymentType.cash,
    ),
    const PaymentMethod(
      id: 'upi_gpay',
      name: 'Google Pay',
      icon: Icons.account_balance_wallet,
      description: 'user@okaxis',
      type: PaymentType.upi,
    ),
    const PaymentMethod(
      id: 'card_1',
      name: '•••• •••• •••• 4242',
      icon: Icons.credit_card,
      description: 'Visa • Expires 12/26',
      type: PaymentType.card,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Payment Methods'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Default payment method
          Text(
            'DEFAULT PAYMENT',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: _paymentMethods
                  .map((method) => _buildPaymentMethodTile(method))
                  .toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Add new payment method
          Text(
            'ADD PAYMENT METHOD',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildAddMethodTile(
                  icon: Icons.credit_card,
                  title: 'Add Credit/Debit Card',
                  onTap: _addCard,
                ),
                const Divider(height: 1),
                _buildAddMethodTile(
                  icon: Icons.account_balance,
                  title: 'Add UPI ID',
                  onTap: _addUpi,
                ),
                const Divider(height: 1),
                _buildAddMethodTile(
                  icon: Icons.account_balance_wallet,
                  title: 'Link Wallet',
                  subtitle: 'Paytm, PhonePe, Amazon Pay',
                  onTap: _linkWallet,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Promo code
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.local_offer, color: Colors.green.shade700),
              ),
              title: const Text('Add Promo Code'),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: _addPromoCode,
            ),
          ),

          const SizedBox(height: 32),

          // Info text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Your payment information is stored securely. We do not store your full card details.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method) {
    final isSelected = _selectedMethod == method.id;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _getMethodColor(method.type).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(method.icon, color: _getMethodColor(method.type)),
      ),
      title: Text(
        method.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        method.description,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.green)
          : Radio<String>(
              value: method.id,
              groupValue: _selectedMethod,
              onChanged: (value) {
                setState(() => _selectedMethod = value!);
              },
            ),
      onTap: () {
        setState(() => _selectedMethod = method.id);
      },
    );
  }

  Widget _buildAddMethodTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.grey.shade700),
      ),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            )
          : null,
      trailing: const Icon(Icons.add, color: Colors.grey),
      onTap: onTap,
    );
  }

  Color _getMethodColor(PaymentType type) {
    switch (type) {
      case PaymentType.cash:
        return Colors.green;
      case PaymentType.upi:
        return Colors.purple;
      case PaymentType.card:
        return Colors.blue;
      case PaymentType.wallet:
        return Colors.orange;
    }
  }

  void _addCard() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const _AddCardSheet(),
    );
  }

  void _addUpi() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _AddUpiSheet(
        onSave: (upiId) {
          setState(() {
            _paymentMethods.add(
              PaymentMethod(
                id: 'upi_${DateTime.now().millisecondsSinceEpoch}',
                name: 'UPI',
                icon: Icons.account_balance,
                description: upiId,
                type: PaymentType.upi,
              ),
            );
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('UPI added successfully')),
          );
        },
      ),
    );
  }

  void _linkWallet() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Wallet linking coming soon')));
  }

  void _addPromoCode() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _PromoCodeSheet(
        onApply: (code) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Promo code "$code" applied!')),
          );
        },
      ),
    );
  }
}

class _AddCardSheet extends StatefulWidget {
  const _AddCardSheet();

  @override
  State<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<_AddCardSheet> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Card',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _cardNumberController,
              decoration: _inputDecoration('Card Number'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expiryController,
                    decoration: _inputDecoration('MM/YY'),
                    keyboardType: TextInputType.datetime,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _cvvController,
                    decoration: _inputDecoration('CVV'),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _nameController,
              decoration: _inputDecoration('Name on Card'),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Card added successfully')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Add Card'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _AddUpiSheet extends StatefulWidget {
  final void Function(String) onSave;

  const _AddUpiSheet({required this.onSave});

  @override
  State<_AddUpiSheet> createState() => _AddUpiSheetState();
}

class _AddUpiSheetState extends State<_AddUpiSheet> {
  final _upiController = TextEditingController();

  @override
  void dispose() {
    _upiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add UPI ID',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _upiController,
              decoration: InputDecoration(
                hintText: 'yourname@upi',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_upiController.text.isNotEmpty) {
                    widget.onSave(_upiController.text);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Verify & Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoCodeSheet extends StatefulWidget {
  final void Function(String) onApply;

  const _PromoCodeSheet({required this.onApply});

  @override
  State<_PromoCodeSheet> createState() => _PromoCodeSheetState();
}

class _PromoCodeSheetState extends State<_PromoCodeSheet> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Promo Code',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: 'Enter code',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_codeController.text.isNotEmpty) {
                    widget.onApply(_codeController.text);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum PaymentType { cash, upi, card, wallet }

class PaymentMethod {
  final String id;
  final String name;
  final IconData icon;
  final String description;
  final PaymentType type;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.type,
  });
}
