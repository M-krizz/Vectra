import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_colors.dart';
import '../../models/signup_data.dart';
import '../../models/ride_request.dart';
import 'profile_screen.dart';
import '../utils/notification_overlay.dart';
import '../services/legacy_driver_status_service.dart';
import '../services/legacy_rides_service.dart';
import '../services/legacy_safety_service.dart';
import 'profile/emergency_contacts_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final SignUpData? signUpData;

  const HomeScreen({super.key, required this.userName, this.signUpData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const List<String> _cancelReasons = [
    'Rider no-show',
    'Rider requested cancellation',
    'Wrong pickup location',
    'Vehicle issue',
    'Safety concern',
    'Traffic or road blocked',
  ];

  int _selectedIndex = 0;
  bool _isOnline = false;
  bool _isStatusUpdating = false;
  bool _isRideActionLoading = false;
  RideStatus _rideStatus = RideStatus.idle;
  RideRequest? _currentRide;
  Timer? _requestTimer;
  double _requestProgress = 1.0;

  // Map Controller
  final MapController _mapController = MapController();

  // Dummy Location Data (Bangalore coordinates for demo)
  final LatLng _currentLocation = const LatLng(12.9716, 77.5946);

  // Analytics State
  double _totalEarnings = 0.0;
  int _totalRides = 0;
  final List<RideRequest> _completedRides = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncOnlineStateFromBackend();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _forceOfflineOnBackground();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _requestTimer?.cancel();
    LegacyRidesService.disconnect();
    super.dispose();
  }

  Future<void> _syncOnlineStateFromBackend() async {
    try {
      final profile = await LegacyDriverStatusService.getDriverProfile();
      if (!mounted) return;
      setState(() {
        _isOnline = profile.onlineStatus;
        _rideStatus = profile.onlineStatus ? RideStatus.searching : RideStatus.idle;
      });
      if (profile.onlineStatus) {
        _startSearching();
      } else {
        LegacyRidesService.disconnect();
      }
    } catch (_) {
      // Keep local fallback state when profile fetch fails.
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  Future<void> _toggleOnlineStatus() async {
    if (_isStatusUpdating) return;
    if (_rideStatus != RideStatus.idle && _rideStatus != RideStatus.searching) {
      return;
    }

    final targetOnline = !_isOnline;
    setState(() => _isStatusUpdating = true);

    try {
      if (targetOnline) {
        final eligibility = await LegacyDriverStatusService.validateOnlineEligibility();
        if (eligibility['canGoOnline'] != true) {
          if (!mounted) return;
          NotificationOverlay.showMessage(
            context,
            (eligibility['reason'] as String?) ??
                'You are not eligible to go online right now.',
            backgroundColor: AppColors.error,
          );
          return;
        }
      }

      final updated = await LegacyDriverStatusService.updateOnlineStatus(targetOnline);
      if (!updated) {
        if (!mounted) return;
        NotificationOverlay.showMessage(
          context,
          'Failed to update online status. Please try again.',
          backgroundColor: AppColors.error,
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _isOnline = targetOnline;
        if (_isOnline) {
          _rideStatus = RideStatus.searching;
          _startSearching();
        } else {
          _rideStatus = RideStatus.idle;
          _requestTimer?.cancel();
          NotificationOverlay.hide();
          _currentRide = null;
          LegacyRidesService.disconnect();
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isStatusUpdating = false);
      }
    }
  }

  Future<void> _forceOfflineOnBackground() async {
    if (!_isOnline || _isStatusUpdating) return;
    final updated = await LegacyDriverStatusService.updateOnlineStatus(false);
    if (!mounted || !updated) return;
    setState(() {
      _isOnline = false;
      _rideStatus = RideStatus.idle;
      _requestTimer?.cancel();
      NotificationOverlay.hide();
      _currentRide = null;
    });
    LegacyRidesService.disconnect();
  }

  void _startSearching() async {
    if (!_isOnline) return;

    try {
      await LegacyRidesService.connect();
      _bindTripStatusUpdates();
      LegacyRidesService.listenRideOffers((request) {
        if (!mounted || !_isOnline || _rideStatus != RideStatus.searching) {
          return;
        }
        _handleIncomingRequest(request);
      });
    } catch (_) {
      if (!mounted) return;
      NotificationOverlay.showMessage(
        context,
        'Unable to connect to ride offers. Please try again.',
        backgroundColor: AppColors.error,
      );
    }
  }

  void _bindTripStatusUpdates() {
    LegacyRidesService.listenTripStatusUpdates(({
      required String tripId,
      required String status,
    }) {
      if (!mounted) return;

      final activeTripId = _currentRide?.id;
      if (activeTripId == null || activeTripId != tripId) return;

      switch (status) {
        case 'ASSIGNED':
        case 'ARRIVING':
          setState(() => _rideStatus = RideStatus.goingToPickup);
          break;
        case 'IN_PROGRESS':
          setState(() => _rideStatus = RideStatus.inProgress);
          break;
        case 'COMPLETED':
          if (_rideStatus != RideStatus.completed) {
            _completeRideFromServer();
          }
          break;
        case 'CANCELLED':
          _handleTripCancelledFromServer();
          break;
      }
    });
  }

  void _completeRideFromServer() {
    final trip = _currentRide;
    if (trip == null) return;

    setState(() {
      _rideStatus = RideStatus.completed;
      _totalEarnings += trip.fare;
      _totalRides += 1;
      _completedRides.insert(0, trip);
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ride Completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            Text(
              'You earned Rs ${trip.fare.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _rideStatus = RideStatus.searching;
                _currentRide = null;
              });
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _handleTripCancelledFromServer() {
    setState(() {
      _rideStatus = RideStatus.searching;
      _currentRide = null;
    });
    NotificationOverlay.showMessage(
      context,
      'Trip was cancelled.',
      backgroundColor: AppColors.error,
    );
  }

  void _handleIncomingRequest(RideRequest request) {
    setState(() {
      _rideStatus = RideStatus.requestReceived;
      _currentRide = request;
      _requestProgress = 1.0;
    });

    _showRequestBottomSheet(request);
  }

  void _showRequestBottomSheet(RideRequest request) {
    // 30 Seconds Timer
    int timeLeft = 30;
    _requestTimer?.cancel();
    _requestTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        timeLeft--;
        _requestProgress = timeLeft / 30.0;
      });

      if (timeLeft <= 0) {
        timer.cancel();
        NotificationOverlay.hide();
        _rejectRide();
      }
    });

    NotificationOverlay.show(
      context,
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: AppColors.grey.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NEW RIDE REQUEST',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.passengerName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (request.isPooling)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.group, size: 14, color: Colors.purple),
                        SizedBox(width: 4),
                        Text(
                          'Pooling',
                          style: TextStyle(
                            color: Colors.purple,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person, size: 14, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Normal',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    size: 14,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    request.pickupAddress,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    size: 14,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    request.dropAddress,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Progress Bar
            Stack(
              children: [
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  height: 4,
                  width:
                      (MediaQuery.of(context).size.width - 64) *
                      _requestProgress,
                  decoration: BoxDecoration(
                    color: _requestProgress > 0.3
                        ? AppColors.primary
                        : AppColors.error,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _requestTimer?.cancel();
                      NotificationOverlay.hide();
                      _rejectRide();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.error),
                      foregroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _requestTimer?.cancel();
                      NotificationOverlay.hide();
                      _acceptRide();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _acceptRide() async {
    if (_currentRide == null || _isRideActionLoading) return;
    _requestTimer?.cancel();

    setState(() => _isRideActionLoading = true);
    try {
      await LegacyRidesService.acceptRide(_currentRide!.id);
      if (!mounted) return;
      setState(() {
        _rideStatus = RideStatus.goingToPickup;
      });
    } catch (_) {
      if (!mounted) return;
      NotificationOverlay.showMessage(
        context,
        'Failed to accept ride. Try again.',
        backgroundColor: AppColors.error,
      );
      setState(() {
        _rideStatus = RideStatus.searching;
        _currentRide = null;
      });
    } finally {
      if (mounted) {
        setState(() => _isRideActionLoading = false);
      }
    }
  }

  void _rejectRide() async {
    if (_currentRide == null || _isRideActionLoading) return;
    _requestTimer?.cancel();

    setState(() => _isRideActionLoading = true);
    try {
      await LegacyRidesService.rejectRide(_currentRide!.id);
    } catch (_) {
      // Keep UI flowing even if reject event fails.
    } finally {
      if (mounted) {
        setState(() {
          _rideStatus = RideStatus.searching;
          _currentRide = null;
          _isRideActionLoading = false;
        });
      }
    }
  }

  void _arrivedAtPickup() {
    setState(() {
      _rideStatus = RideStatus.arrivedAtPickup;
    });
    _showOTPDialog();
  }

  void _showOTPDialog() {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Enter OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ask ${_currentRide?.passengerName} for the OTP to start the ride.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: 'Enter trip OTP',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (otpController.text.isNotEmpty) {
                final trip = _currentRide;
                if (trip == null) {
                  Navigator.of(context).pop();
                  return;
                }

                final isValid = await LegacyRidesService.verifyTripOtp(
                  tripId: trip.id,
                  riderId: trip.riderId,
                  otp: otpController.text.trim(),
                );

                if (!mounted) return;
                if (!isValid) {
                  NotificationOverlay.showMessage(
                    context,
                    'Invalid OTP. Cannot start trip.',
                    backgroundColor: AppColors.error,
                  );
                  return;
                }

                Navigator.of(context).pop();
                _startRide();
              } else {
                NotificationOverlay.showMessage(
                  context,
                  'Please enter OTP',
                  backgroundColor: AppColors.error,
                );
              }
            },
            child: const Text('Start Ride'),
          ),
        ],
      ),
    );
  }

  void _startRide() {
    final trip = _currentRide;
    if (trip == null) return;

    LegacyRidesService.startTrip(trip.id).then((_) {
      if (!mounted) return;
      setState(() {
        _rideStatus = RideStatus.inProgress;
      });
    }).catchError((_) {
      if (!mounted) return;
      NotificationOverlay.showMessage(
        context,
        'Failed to start trip. Please retry.',
        backgroundColor: AppColors.error,
      );
    });
  }

  void _showCancelRideDialog() {
    final trip = _currentRide;
    if (trip == null || _isRideActionLoading) return;

    String selectedReason = _cancelReasons.first;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Ride'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: _cancelReasons
                  .map(
                    (reason) => ListTile(
                      onTap: () => setDialogState(() => selectedReason = reason),
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        selectedReason == reason
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: selectedReason == reason
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      title: Text(reason),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Keep Ride'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              setState(() => _isRideActionLoading = true);

              try {
                await LegacyRidesService.cancelTrip(
                  tripId: trip.id,
                  reason: selectedReason,
                );
                if (!mounted) return;
                setState(() {
                  _rideStatus = RideStatus.searching;
                  _currentRide = null;
                });
                NotificationOverlay.showMessage(
                  context,
                  'Ride cancelled: $selectedReason',
                  backgroundColor: AppColors.success,
                );
              } catch (_) {
                if (!mounted) return;
                NotificationOverlay.showMessage(
                  context,
                  'Unable to cancel ride. Please retry.',
                  backgroundColor: AppColors.error,
                );
              } finally {
                if (mounted) {
                  setState(() => _isRideActionLoading = false);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cancel Ride'),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerSos() async {
    final tripId = _currentRide?.id;
    try {
      await LegacySafetyService.triggerSos(
        tripId: tripId,
        lat: _currentLocation.latitude,
        lng: _currentLocation.longitude,
      );
      if (!mounted) return;
      NotificationOverlay.showMessage(
        context,
        'SOS alert sent to safety team.',
        backgroundColor: AppColors.error,
      );
    } catch (_) {
      if (!mounted) return;
      NotificationOverlay.showMessage(
        context,
        'Unable to send SOS. Please retry.',
        backgroundColor: AppColors.error,
      );
    }
  }

  void _showIncidentReportDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report Safety Incident'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Describe what happened',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final description = controller.text.trim();
              if (description.isEmpty) return;
              Navigator.of(dialogContext).pop();
              try {
                await LegacySafetyService.reportIncident(
                  description: description,
                  rideId: _currentRide?.id,
                );
                if (!mounted) return;
                NotificationOverlay.showMessage(
                  context,
                  'Incident reported successfully.',
                  backgroundColor: AppColors.success,
                );
              } catch (_) {
                if (!mounted) return;
                NotificationOverlay.showMessage(
                  context,
                  'Failed to report incident.',
                  backgroundColor: AppColors.error,
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showSafetyActionsSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.sos, color: AppColors.error),
                  title: const Text('Trigger SOS'),
                  subtitle: const Text('Alerts admins immediately'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _triggerSos();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.report_problem, color: AppColors.warning),
                  title: const Text('Report Incident'),
                  subtitle: const Text('Send details to safety team'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showIncidentReportDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.contacts, color: AppColors.primary),
                  title: const Text('Emergency Contacts'),
                  subtitle: const Text('View and manage SOS contacts'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmergencyContactsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _completeRide() async {
    final trip = _currentRide;
    if (trip == null || _isRideActionLoading) return;

    setState(() => _isRideActionLoading = true);
    try {
      await LegacyRidesService.completeTrip(trip.id);
      if (!mounted) return;
      setState(() {
        _rideStatus = RideStatus.completed;
        _totalEarnings += trip.fare;
        _totalRides += 1;
        _completedRides.insert(0, trip);
      });
    } catch (_) {
      if (!mounted) return;
      NotificationOverlay.showMessage(
        context,
        'Failed to complete trip. Please retry.',
        backgroundColor: AppColors.error,
      );
      return;
    } finally {
      if (mounted) {
        setState(() => _isRideActionLoading = false);
      }
    }

    // Show Summary
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Ride Completed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            Text(
              'You earned ₹${_currentRide?.fare.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _rideStatus = RideStatus.searching; // Back to online
                _currentRide = null;
              });
              _startSearching();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If in ride flow (not idle/searching/request), show Map
    if (_rideStatus == RideStatus.goingToPickup ||
        _rideStatus == RideStatus.arrivedAtPickup ||
        _rideStatus == RideStatus.inProgress) {
      return _buildRideMapScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _selectedIndex == 0 ? _buildHomeBody() : _buildProfileBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildRideMapScreen() {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.driver_app',
              ),
              MarkerLayer(
                markers: [
                  // Pickup Marker
                  Marker(
                    point: _currentRide!.pickupLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.green,
                      size: 40,
                    ),
                  ),
                  // Drop Marker (Only show if in progress or map view shows both)
                  Marker(
                    point: _currentRide!.dropLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                  // Driver (Current) Marker - Simulated
                  Marker(
                    point: _currentLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.directions_car,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            top: 60,
            right: 16,
            child: Material(
              color: Colors.white,
              elevation: 6,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: _showSafetyActionsSheet,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.shield, color: AppColors.error),
                ),
              ),
            ),
          ),

          // Bottom Status Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_rideStatus == RideStatus.goingToPickup) ...[
                    const Text(
                      'Picking up',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    Text(
                      _currentRide!.passengerName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentRide!.pickupAddress,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _arrivedAtPickup,
                        child: const Text('Arrived at Location'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _showCancelRideDialog,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        child: const Text('Cancel Ride'),
                      ),
                    ),
                  ] else if (_rideStatus == RideStatus.arrivedAtPickup) ...[
                    const Text(
                      'Waiting for passenger...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ask passenger for OTP',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _showOTPDialog,
                        child: const Text('Enter OTP'),
                      ),
                    ),
                  ] else if (_rideStatus == RideStatus.inProgress) ...[
                    const Text(
                      'Heading to Destination',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentRide!.dropAddress,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _completeRide,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: const Text('End Ride'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _showCancelRideDialog,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        child: const Text('Cancel Ride'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          InkWell(
            onTap: () => setState(() => _selectedIndex = 0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.home,
                    color: _selectedIndex == 0
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Home',
                    style: TextStyle(
                      color: _selectedIndex == 0
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Online/Offline Button (Center)
          GestureDetector(
            onTap: _isStatusUpdating ? null : _toggleOnlineStatus,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color:
                    _rideStatus != RideStatus.idle &&
                        _rideStatus != RideStatus.searching
                    ? AppColors
                          .grey // Disable if in ride
                    : (_isOnline ? AppColors.success : AppColors.grey),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: (_isOnline ? AppColors.success : AppColors.grey)
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_rideStatus == RideStatus.searching || _isStatusUpdating)
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  Icon(
                    Icons.power_settings_new,
                    color: _isOnline ? Colors.white : AppColors.textPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isOnline
                    ? (_isStatusUpdating
                      ? 'UPDATING'
                      : (_rideStatus == RideStatus.searching
                              ? 'SEARCHING'
                      : 'ONLINE'))
                        : 'OFFLINE',
                    style: TextStyle(
                      color: _isOnline ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          InkWell(
            onTap: () => setState(() => _selectedIndex = 1),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person,
                    color: _selectedIndex == 1
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Profile',
                    style: TextStyle(
                      color: _selectedIndex == 1
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeBody() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, size: 28),
                      onPressed: () {},
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Status Message based on Online State
            if (!_isOnline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'You are currently Offline. Go Online to start receiving rides.',
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 24),

            // Analytics
            const Text(
              'Today\'s Analytics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildAnalyticsCard(
                  'Earnings',
                  '₹${_totalEarnings.toStringAsFixed(0)}',
                  Icons.account_balance_wallet,
                  AppColors.primary,
                ),
                const SizedBox(width: 16),
                _buildAnalyticsCard(
                  'Rides',
                  '$_totalRides',
                  Icons.directions_car,
                  AppColors.warning,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Ride History
            const Text(
              'Recent Rides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            if (_completedRides.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No recent rides',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _completedRides.length,
                itemBuilder: (context, index) {
                  return _buildRideHistoryItem(_completedRides[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideHistoryItem(RideRequest ride) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.grey.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trip to ${ride.dropAddress}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Completed just now', // Timestamp could be added to RideRequest
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${ride.fare.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Completed',
                style: TextStyle(fontSize: 12, color: AppColors.success),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileBody() {
    return ProfileScreen(
      userName: widget.userName,
      signUpData: widget.signUpData,
    );
  }
}
