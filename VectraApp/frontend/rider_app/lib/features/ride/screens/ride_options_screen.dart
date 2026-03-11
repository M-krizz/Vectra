import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/app_theme.dart';
import '../bloc/ride_bloc.dart';
import '../models/place_model.dart';

/// Combined: Ride Type Selector (Solo/Pool) + Vehicle Options + Promo Code
class RideOptionsScreen extends StatefulWidget {
  const RideOptionsScreen({super.key});

  @override
  State<RideOptionsScreen> createState() => _RideOptionsScreenState();
}

class _RideOptionsScreenState extends State<RideOptionsScreen> {
  String _rideType = 'solo';
  String? _selectedVehicleId;
  bool _promoApplied = false;
  final _promoController = TextEditingController();

  static const _vehicles = [
    _VehicleInfo(
      id: 'auto',
      label: 'Auto',
      emoji: '🛺',
      desc: '3 seats • Economical',
      baseFare: 45,
      perKm: 12,
      eta: 3,
    ),
    _VehicleInfo(
      id: 'bike',
      label: 'Bike',
      emoji: '🏍️',
      desc: '1 seat • Fastest',
      baseFare: 25,
      perKm: 8,
      eta: 2,
    ),
    _VehicleInfo(
      id: 'cab',
      label: 'Cab',
      emoji: '🚗',
      desc: '4 seats • AC',
      baseFare: 65,
      perKm: 15,
      eta: 5,
    ),
  ];

  int _fareFor(String vehicleId, RideState state) {
    final backendOption = state.vehicleOptions
        .where((option) => option.id == vehicleId)
        .cast<VehicleOption?>()
        .firstWhere((option) => option != null, orElse: () => null);

    if (backendOption != null) {
      var fare = backendOption.fare.round();
      if (_promoApplied) fare = (fare * 0.9).round();
      return fare;
    }

    final v = _vehicles.firstWhere((vehicle) => vehicle.id == vehicleId);
    final distKm = state.route?.distanceMeters != null
        ? state.route!.distanceMeters / 1000
        : 4.2;
    var fare = (v.baseFare + (v.perKm * distKm)).round();
    if (_rideType == 'pool') fare = (fare * 0.7).round();
    if (_promoApplied) fare = (fare * 0.9).round();
    return fare;
  }

  _VehicleInfo _resolveVehicleInfo(VehicleOption option) {
    for (final vehicle in _vehicles) {
      if (vehicle.id == option.id) return vehicle;
    }
    return _VehicleInfo(
      id: option.id,
      label: option.name,
      emoji: '🚗',
      desc: option.description,
      baseFare: 0,
      perKm: 0,
      eta: option.etaMinutes,
    );
  }

  void _applyPromo() {
    if (_promoController.text.trim().isEmpty) return;
    setState(() {
      _promoApplied = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Promo applied! 10% off'),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _requestRide(RideState state) {
    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle type')),
      );
      return;
    }

    final rideBloc = context.read<RideBloc>();
    final selectedVehicle = state.vehicleOptions
        .where((vehicle) => vehicle.id == _selectedVehicleId)
        .cast<VehicleOption?>()
        .firstWhere((vehicle) => vehicle != null, orElse: () => null);

    final fallbackVehicle = _vehicles.firstWhere((vehicle) => vehicle.id == _selectedVehicleId);

    rideBloc.add(RideTypeSelected(_rideType));
    rideBloc.add(RideVehicleSelected(
      selectedVehicle ??
          VehicleOption(
            id: fallbackVehicle.id,
            name: fallbackVehicle.label,
            imageUrl: '',
            fare: _fareFor(fallbackVehicle.id, state).toDouble(),
            etaMinutes: fallbackVehicle.eta,
            description: fallbackVehicle.desc,
            capacity: 4,
          ),
    ));
    rideBloc.add(const RideRequested());

    if (_rideType == 'pool') {
      rideBloc.add(const RidePooledRequestsRequested());
      context.go('/home/pool-preview');
    } else {
      context.go('/home/searching');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Choose Ride',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_rounded, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Theme.of(context).colorScheme.outline),
        ),
      ),
      body: BlocBuilder<RideBloc, RideState>(
        builder: (context, state) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              // Route summary
              _RouteSummary(state: state),

              // ── Ride type toggle ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Text(
                      'Ride Type',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _TypeTab(
                        label: '🚗  Solo',
                        selected: _rideType == 'solo',
                        onTap: () => setState(() => _rideType = 'solo'),
                      ),
                      _TypeTab(
                        label: '🚌  Pool',
                        selected: _rideType == 'pool',
                        onTap: () => setState(() => _rideType = 'pool'),
                      ),
                    ],
                  ),
                ),
              ),

              if (_rideType == 'pool')
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.people_alt_rounded,
                            size: 18, color: Color(0xFF2E7D32)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pool saves up to 30%! You may share your ride with others going the same way.',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF2E7D32)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Vehicle options ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  'Available Vehicles',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),

              ...(state.vehicleOptions.isNotEmpty
                      ? state.vehicleOptions
                          .map(
                            (vehicle) => _VehicleTile(
                              info: _resolveVehicleInfo(vehicle),
                              fare: _fareFor(vehicle.id, state),
                              rideType: _rideType,
                              selected: _selectedVehicleId == vehicle.id,
                              onTap: () => setState(() => _selectedVehicleId = vehicle.id),
                            ),
                          )
                          .toList()
                      : _vehicles
                          .map(
                            (vehicle) => _VehicleTile(
                              info: vehicle,
                              fare: _fareFor(vehicle.id, state),
                              rideType: _rideType,
                              selected: _selectedVehicleId == vehicle.id,
                              onTap: () => setState(() => _selectedVehicleId = vehicle.id),
                            ),
                          )
                          .toList()),

              // ── Promo code ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  'Promo Code',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).colorScheme.outline),
                        ),
                        child: TextField(
                          controller: _promoController,
                          enabled: !_promoApplied,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Enter promo code',
                            hintStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            suffixIcon: _promoApplied
                                ? const Icon(Icons.check_circle_rounded,
                                    color: Color(0xFF2E7D32), size: 20)
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _promoApplied ? null : _applyPromo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        minimumSize: const Size(80, 48),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          Text(_promoApplied ? 'Applied' : 'Apply'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: BlocBuilder<RideBloc, RideState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: () => _requestRide(state),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Request Ride',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }
}

// ─── Route summary at top ─────────────────────────────────────────────────

class _RouteSummary extends StatelessWidget {
  final RideState state;
  const _RouteSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
              ),
              Container(width: 1.5, height: 32, color: Colors.grey.shade300),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.pickup?.name ?? 'Pickup location',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 22),
                Text(
                  state.destination?.name ?? 'Destination',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(state.route?.distanceText ?? '--',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              Text(state.route?.durationText ?? '--',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Ride type tab ────────────────────────────────────────────────────────

class _TypeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? colors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? colors.onSurface
                    : colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Vehicle tile ─────────────────────────────────────────────────────────

class _VehicleTile extends StatelessWidget {
  final _VehicleInfo info;
  final int fare;
  final String rideType;
  final bool selected;
  final VoidCallback onTap;

  const _VehicleTile({
    required this.info,
    required this.fare,
    required this.rideType,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? colors.primary.withValues(alpha: 0.1) : colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colors.primary : colors.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(info.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${info.desc}  •  ${info.eta} min away',
                    style: TextStyle(
                        fontSize: 12, color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹$fare',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                if (rideType == 'pool')
                  const Text(
                    'POOLED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data class ───────────────────────────────────────────────────────────

class _VehicleInfo {
  final String id;
  final String label;
  final String emoji;
  final String desc;
  final int baseFare;
  final int perKm;
  final int eta;
  const _VehicleInfo({
    required this.id,
    required this.label,
    required this.emoji,
    required this.desc,
    required this.baseFare,
    required this.perKm,
    required this.eta,
  });
}
