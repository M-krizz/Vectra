import 'package:flutter/material.dart';
import '../../../../config/app_theme.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final List<_Contact> _contacts = [
    _Contact(name: 'Amma', phone: '+91 98765 00001', relation: 'Mother'),
    _Contact(name: 'Sumesh', phone: '+91 98765 00002', relation: 'Friend'),
  ];

  void _addContact() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Emergency Contact',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            _InputField(controller: nameCtrl, hint: 'Full Name'),
            const SizedBox(height: 10),
            _InputField(controller: phoneCtrl, hint: 'Phone Number', type: TextInputType.phone),
            const SizedBox(height: 10),
            _InputField(controller: relCtrl, hint: 'Relation (e.g., Mother, Friend)'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
                  setState(() {
                    _contacts.add(_Contact(
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      relation: relCtrl.text.trim(),
                    ));
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Save Contact'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _delete(int index) {
    setState(() => _contacts.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Emergency Contacts',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 28),
            onPressed: _addContact,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: _contacts.isEmpty
          ? const Center(
              child: Text('No emergency contacts added yet.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _contacts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c = _contacts[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEDE7F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded, size: 24, color: Color(0xFF6A1B9A)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        Text('${c.relation}  •  ${c.phone}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ]),
                    ),
                    IconButton(
                      onPressed: () => _delete(i),
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 20, color: AppColors.error),
                    ),
                  ]),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addContact,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Contact', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _Contact {
  String name;
  String phone;
  String relation;
  _Contact({required this.name, required this.phone, required this.relation});
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? type;
  const _InputField({required this.controller, required this.hint, this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }
}
