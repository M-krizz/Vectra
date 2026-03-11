import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/app_theme.dart';
import '../bloc/ride_bloc.dart';

class PoolPreviewScreen extends StatefulWidget {
  const PoolPreviewScreen({super.key});

  @override
  State<PoolPreviewScreen> createState() => _PoolPreviewScreenState();
}

class _PoolPreviewScreenState extends State<PoolPreviewScreen> {
  String? _selectedRequestId;

  void _confirmPool() {
    final state = context.read<RideBloc>().state;
    if (_selectedRequestId == null && state.pooledRequests.isNotEmpty) {
      // Auto-select first
      setState(() => _selectedRequestId = state.pooledRequests[0].id);
    }
    
    if (_selectedRequestId == null) return;

    final rider = state.pooledRequests.firstWhere((r) => r.id == _selectedRequestId);

    context.read<RideBloc>().add(RidePooledRequestSelected(rider));

    // Navigate to searching screen — GoRouter route (don't use Navigator.pop)
    context.go('/home/searching');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RideBloc, RideState>(
      builder: (context, state) {
        final riders = state.pooledRequests;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(
              'Pool Preview',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () => context.go('/home'),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: Theme.of(context).colorScheme.outline),
            ),
          ),
          body: riders.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline_rounded, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No pool matches yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.isLoading
                            ? 'Searching for riders going your way...'
                            : 'No riders are heading in your direction right now. You can wait or go back to choose a solo ride.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      if (state.isLoading) ...[
                        const SizedBox(height: 20),
                        const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
                      ],
                      const SizedBox(height: 24),
                      if (!state.isLoading)
                        OutlinedButton(
                          onPressed: () => context.go('/home'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.onSurface,
                            side: BorderSide(color: Theme.of(context).colorScheme.outline),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Go Back'),
                        ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Pool benefit card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Text('💚', style: TextStyle(fontSize: 28)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You\'re saving 30%!',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Sharing a ride is better for your wallet and the environment.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF388E3C)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Fellow Riders',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll be matched with one of these riders going your way.',
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),

                  ...riders.map((rider) => _RiderCard(
                        rider: rider,
                        selected: _selectedRequestId == rider.id,
                        onTap: () =>
                            setState(() => _selectedRequestId = rider.id),
                      )),

                  const SizedBox(height: 100),
                ],
              ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: riders.isEmpty ? null : _confirmPool,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Confirm Pool Ride',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

// ─── Rider card ───────────────────────────────────────────────────────────

class _RiderCard extends StatelessWidget {
  final PooledRiderRequest rider;
  final bool selected;
  final VoidCallback onTap;

  const _RiderCard({required this.rider, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : Theme.of(context).colorScheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_rounded,
                  size: 26, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        rider.riderName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded,
                          size: 14, color: Color(0xFFFFA000)),
                      Text(
                        rider.rating.toString(),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.circle,
                          size: 8, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          rider.pickup.name,
                          style: TextStyle(
                              fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.circle,
                          size: 8, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          rider.destination.name,
                          style: TextStyle(
                              fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  size: 22, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
