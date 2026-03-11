import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/bloc/auth_bloc.dart';
import 'payment_methods_screen.dart';
import 'profile_details_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        final displayName = user?.fullName ?? 'Vectra User';
        final phone = user?.phone ?? '';

        return Scaffold(
          backgroundColor: colors.surface,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: colors.surface,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(height: 1, color: colors.outline.withValues(alpha: 0.3)),
                ),
              ),

              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // User card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? colors.surfaceContainerHighest : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileDetailsScreen())),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52, height: 52,
                                    decoration: BoxDecoration(
                                      color: colors.primary.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'V',
                                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colors.primary),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(displayName, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: colors.onSurface)),
                                        if (phone.isNotEmpty) Text(phone, style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
                                ],
                              ),
                            ),
                          ),
                          Divider(height: 1, color: colors.outline.withValues(alpha: 0.2)),
                          InkWell(
                            onTap: () {},
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 22),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text('5.0  My Rating', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.onSurface))),
                                  Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Menu items
                    _MenuSection(items: [
                      _MenuItem(icon: Icons.account_balance_wallet_outlined, label: 'Payment', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()))),
                      _MenuItem(icon: Icons.history_rounded, label: 'My Rides', onTap: () => context.go('/trips')),
                      _MenuItem(icon: Icons.shield_outlined, label: 'Safety', onTap: () => context.go('/safety')),
                      _MenuItem(icon: Icons.card_giftcard_rounded, label: 'Refer and Earn', subtitle: 'Get ?50', onTap: () => _showReferSheet(context)),
                      _MenuItem(icon: Icons.settings_outlined, label: 'Settings', showDivider: false, onTap: () => context.push('/profile/settings')),
                    ]),

                    const SizedBox(height: 20),

                    // Driver promo banner
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2D2B1F) : const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? const Color(0xFF5C5833) : const Color(0xFFFFE082), width: 1),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Earn money with Vectra', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.onSurface)),
                                const SizedBox(height: 4),
                                Text('Become a Captain!', style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                            child: Icon(Icons.directions_car_rounded, color: colors.primary, size: 32),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReferSheet(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: colors.outline.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            Icon(Icons.card_giftcard_rounded, size: 48, color: colors.primary),
            const SizedBox(height: 16),
            Text('Refer & Earn ?50', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.onSurface)),
            const SizedBox(height: 8),
            Text('Share your referral code with friends.\nBoth get ?50 on their first ride!', textAlign: TextAlign.center, style: TextStyle(color: colors.onSurfaceVariant)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('VECTRA2025', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2, color: colors.onSurface)),
                  GestureDetector(
                    onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied!'))); },
                    child: Text('COPY', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: items),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showDivider;
  const _MenuItem({required this.icon, required this.label, this.subtitle, required this.onTap, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 22, color: colors.onSurfaceVariant),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.onSurface)),
                  if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant))],
                ])),
                Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant, size: 20),
              ],
            ),
          ),
        ),
        if (showDivider) Divider(height: 1, indent: 54, endIndent: 0, color: colors.outline.withValues(alpha: 0.2)),
      ],
    );
  }
}
