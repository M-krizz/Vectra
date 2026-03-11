import 'package:flutter/material.dart';
import '../../../../config/app_theme.dart';

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({super.key});

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  String? _category;
  final _descController = TextEditingController();
  bool _submitted = false;

  static const _categories = [
    'Rude / aggressive driver',
    'Unsafe driving behaviour',
    'Route deviation',
    'Driver asked for more money',
    'Vehicle was not clean',
    'Driver was using phone',
    'Other',
  ];

  void _submit() {
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an incident category')),
      );
      return;
    }
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text('Report Issue',
            style: TextStyle(fontWeight: FontWeight.w700, color: colors.onSurface)),
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: colors.outline.withValues(alpha: 0.2)),
        ),
      ),
      body: _submitted
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('\u2705', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 20),
                  Text('Report Submitted',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colors.onSurface)),
                  const SizedBox(height: 8),
                  Text(
                    'Our team will review and follow up within 24 hours.',
                    style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ]),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('What happened?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.onSurface)),
                const SizedBox(height: 4),
                Text('Select the category that best describes the issue.',
                    style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant)),
                const SizedBox(height: 16),
                RadioGroup<String>(
                  groupValue: _category,
                  onChanged: (value) => setState(() => _category = value),
                  child: Column(
                    children: _categories
                        .map(
                          (c) => RadioListTile<String>(
                            value: c,
                            title: Text(
                              c,
                              style: TextStyle(fontSize: 14, color: colors.onSurface),
                            ),
                            activeColor: colors.primary,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        )
                        .toList(),
                  ),
                ),

                const SizedBox(height: 20),

                Text('Describe the incident',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.onSurface)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.outline.withValues(alpha: 0.3)),
                  ),
                  child: TextField(
                    controller: _descController,
                    maxLines: 5,
                    style: TextStyle(fontSize: 14, color: colors.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Provide as much detail as possible\u2026',
                      hintStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),

                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Submit Report',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }
}
