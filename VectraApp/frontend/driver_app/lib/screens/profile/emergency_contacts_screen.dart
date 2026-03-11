import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../services/legacy_safety_service.dart';
import '../../utils/notification_overlay.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _contacts = const [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _loading = true);
    try {
      final contacts = await LegacySafetyService.getContacts();
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      NotificationOverlay.showMessage(
        context,
        'Failed to load contacts',
        backgroundColor: AppColors.error,
      );
    }
  }

  Future<void> _showAddDialog() async {
    final screenContext = context;
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relationController,
                decoration: const InputDecoration(
                  labelText: 'Relationship (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              final relation = relationController.text.trim();

              if (name.isEmpty || phone.isEmpty) {
                NotificationOverlay.showMessage(
                  context,
                  'Name and phone are required',
                  backgroundColor: AppColors.error,
                );
                return;
              }

              try {
                await LegacySafetyService.addContact(
                  name: name,
                  phoneNumber: phone,
                  relationship: relation.isEmpty ? null : relation,
                );
                if (!mounted || !dialogContext.mounted || !screenContext.mounted) {
                  return;
                }
                Navigator.of(dialogContext).pop();
                await _loadContacts();
                if (!mounted || !screenContext.mounted) return;
                NotificationOverlay.showMessage(
                  screenContext,
                  'Emergency contact added',
                  backgroundColor: AppColors.success,
                );
              } catch (_) {
                if (!mounted || !screenContext.mounted) return;
                NotificationOverlay.showMessage(
                  screenContext,
                  'Failed to add contact',
                  backgroundColor: AppColors.error,
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteContact(Map<String, dynamic> contact) async {
    final id = (contact['id'] ?? '').toString();
    if (id.isEmpty) {
      NotificationOverlay.showMessage(
        context,
        'Contact id missing',
        backgroundColor: AppColors.error,
      );
      return;
    }

    try {
      await LegacySafetyService.deleteContact(id);
      if (!mounted) return;
      await _loadContacts();
      if (!mounted) return;
      NotificationOverlay.showMessage(
        context,
        'Contact removed',
        backgroundColor: AppColors.success,
      );
    } catch (_) {
      if (!mounted) return;
      NotificationOverlay.showMessage(
        context,
        'Failed to remove contact',
        backgroundColor: AppColors.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? const Center(
                  child: Text(
                    'No emergency contacts yet',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _contacts.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    final name = (contact['name'] ?? 'Contact').toString();
                    final phone =
                        (contact['phoneNumber'] ?? contact['phone'] ?? '').toString();
                    final relation = (contact['relationship'] ?? '').toString();

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  phone,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (relation.isNotEmpty)
                                  Text(
                                    relation,
                                    style: const TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _deleteContact(contact),
                            icon: const Icon(Icons.delete_outline, color: AppColors.error),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
