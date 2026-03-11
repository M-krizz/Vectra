import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/safety_bloc.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SafetyBloc>().add(LoadContactsRequested());
  }

  void _addContact() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relCtrl = TextEditingController();
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
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
            Text('Add Emergency Contact',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: colors.onSurface)),
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
                  context.read<SafetyBloc>().add(
                    AddContactRequested(
                      name: nameCtrl.text.trim(),
                      phoneNumber: phoneCtrl.text.trim(),
                      relationship: relCtrl.text.trim().isEmpty ? null : relCtrl.text.trim(),
                    )
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
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

  void _delete(String id) {
    context.read<SafetyBloc>().add(DeleteContactRequested(id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text('Emergency Contacts',
            style: TextStyle(fontWeight: FontWeight.w700, color: colors.onSurface)),
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: colors.primary, size: 28),
            onPressed: _addContact,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: colors.outline.withValues(alpha: 0.2)),
        ),
      ),
      body: BlocBuilder<SafetyBloc, SafetyState>(
        builder: (context, state) {
          if (state is SafetyContactsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SafetyError) {
            return Center(
              child: Text(state.message, style: TextStyle(color: colors.error)),
            );
          } else if (state is SafetyContactsLoaded) {
            final contacts = state.contacts;
            if (contacts.isEmpty) {
              return Center(
                child: Text('No emergency contacts added yet.',
                    style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14)),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: contacts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c = contacts[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? colors.surfaceContainerHighest : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.outline.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded, size: 24, color: Color(0xFF6A1B9A)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.name,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.onSurface)),
                        Text('${c.relationship ?? 'Contact'}  \u2022  ${c.phoneNumber}',
                            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
                      ]),
                    ),
                    IconButton(
                      onPressed: () => _delete(c.id),
                      icon: Icon(Icons.delete_outline_rounded,
                          size: 20, color: colors.error),
                    ),
                  ]),
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addContact,
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Contact', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? type;
  const _InputField({required this.controller, required this.hint, this.type});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceContainerHighest : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outline.withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: TextStyle(fontSize: 14, color: colors.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }
}
