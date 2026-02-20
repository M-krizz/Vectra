import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/session_expired_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/history/screens/ride_history_screen.dart';
import '../features/history/screens/ride_detail_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/permissions/screens/permissions_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/settings_screen.dart';
import '../features/ride/bloc/ride_bloc.dart';
import '../features/ride/screens/driver_arriving_screen.dart';
import '../features/ride/screens/driver_assigned_screen.dart';
import '../features/ride/screens/fare_breakdown_screen.dart';
import '../features/ride/screens/in_trip_screen.dart';
import '../features/ride/screens/location_search_screen.dart';
import '../features/ride/screens/payment_selection_screen.dart';
import '../features/ride/screens/pool_preview_screen.dart';
import '../features/ride/screens/rating_screen.dart';
import '../features/ride/screens/receipt_screen.dart';
import '../features/ride/screens/ride_home_screen.dart';
import '../features/ride/screens/ride_options_screen.dart';
import '../features/ride/screens/searching_screen.dart';
import '../features/ride/screens/trip_cancelled_screen.dart';
import '../features/ride/screens/trip_completed_screen.dart';
import '../features/safety/screens/emergency_contacts_screen.dart';
import '../features/safety/screens/incident_report_screen.dart';
import '../features/safety/screens/safety_center_screen.dart';
import '../features/safety/screens/sos_screen.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppRouter — declarative, state-driven navigation
///
/// Structure:
///   /                        → SplashScreen (boot gate)
///   /auth/login              → LoginScreen
///   /auth/register           → RegisterScreen
///   /auth/session-expired    → SessionExpiredScreen
///   /onboarding              → OnboardingScreen (shown once, after first login)
///   /permissions             → PermissionsScreen
///
///   Shell (bottom-tab nav):
///     /home                  → RideHomeScreen (Tab A)
///     /trips                 → RideHistoryScreen (Tab B)
///     /trips/:tripId         → RideDetailScreen
///     /safety                → SafetyCenterScreen (Tab C)
///     /safety/sos            → SosScreen
///     /safety/incident       → IncidentReportScreen
///     /safety/contacts       → EmergencyContactsScreen
///     /profile               → ProfileScreen (Tab D)
///     /profile/settings      → SettingsScreen
///
///   Ride flow (full-screen, outside shell):
///     /home/location-select  → LocationSearchScreen
///     /home/ride-options     → RideOptionsScreen
///     /home/pool-preview     → PoolPreviewScreen
///     /home/searching        → SearchingScreen
///
///   Trip lifecycle (full-screen, with :tripId param):
///     /trip/:tripId/assigned    → DriverAssignedScreen
///     /trip/:tripId/arriving    → DriverArrivingScreen
///     /trip/:tripId/in-progress → InTripScreen
///     /trip/:tripId/completed   → TripCompletedScreen
///     /trip/:tripId/cancelled   → TripCancelledScreen
///     /trip/:tripId/fare        → FareBreakdownScreen
///     /trip/:tripId/payment     → PaymentSelectionScreen
///     /trip/:tripId/receipt     → ReceiptScreen
///     /trip/:tripId/rating      → RatingScreen
/// ─────────────────────────────────────────────────────────────────────────────
class AppRouter {
  AppRouter._();

  static GoRouter router(BuildContext context) {
    return GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: false,
      refreshListenable: GoRouterRefreshStream(context.read<AuthBloc>().stream),
      redirect: (ctx, state) async {
        final authState = ctx.read<AuthBloc>().state;
        final loc = state.matchedLocation;

        // ── Always let these through ────────────────────────────────────
        const openPaths = [
          '/auth/login',
          '/auth/register',
          '/auth/session-expired',
        ];
        final isOpen = openPaths.any((p) => loc.startsWith(p));

        // ── Auth loading → stay on splash ──────────────────────────────
        if (authState is AuthInitial || authState is AuthLoading) {
          return loc == '/' ? null : '/';
        }

        // ── Unauthenticated ────────────────────────────────────────────
        if (authState is AuthUnauthenticated) {
          if (isOpen) return null;
          return '/auth/login';
        }

        // ── Authenticated ──────────────────────────────────────────────
        if (authState is AuthAuthenticated) {
          // Redirect away from auth screens
          final isAuthScreen = isOpen || loc == '/';
          if (isAuthScreen) {
            final prefs = await SharedPreferences.getInstance();
            final onboardingDone = prefs.getBool('onboarding_done') ?? false;
            if (!onboardingDone) return '/onboarding';
            return '/home';
          }
          return null; // Allow wherever they are
        }

        return null;
      },

      // ─────────────────────────────────────────────────────────────────
      routes: [
        // ── Boot ───────────────────────────────────────────────────────
        GoRoute(
          path: '/',
          name: 'splash',
          builder: (ctx, state) => const SplashScreen(),
        ),

        // ── Onboarding / Permissions ───────────────────────────────────
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (ctx, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/permissions',
          name: 'permissions',
          builder: (ctx, state) => const PermissionsScreen(),
        ),

        // ── Auth stack ─────────────────────────────────────────────────
        GoRoute(
          path: '/auth/login',
          name: 'login',
          builder: (ctx, state) => const LoginScreen(),
          routes: [
            GoRoute(
              path: 'register',
              name: 'register',
              builder: (ctx, state) => const RegisterScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/auth/register',
          name: 'register-standalone',
          builder: (ctx, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/auth/session-expired',
          name: 'session-expired',
          builder: (ctx, state) => const SessionExpiredScreen(),
        ),

        // ── Main shell (bottom tabs) ───────────────────────────────────
        ShellRoute(
          builder: (ctx, state, child) => _AppShell(child: child),
          routes: [
            // Tab A: Home (map + request entry)
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (ctx, state) => const RideHomeScreen(),
            ),

            // Tab B: Trips
            GoRoute(
              path: '/trips',
              name: 'trips',
              builder: (ctx, state) => const RideHistoryScreen(),
              routes: [
                GoRoute(
                  path: ':tripId',
                  name: 'trip-detail',
                  builder: (ctx, state) {
                    // RideHistoryModel is passed via GoRouter extra
                    final ride = state.extra as dynamic;
                    if (ride == null) {
                      return const Scaffold(
                        body: Center(child: Text('Ride not found')),
                      );
                    }
                    return RideDetailScreen(ride: ride);
                  },
                ),
              ],
            ),

            // Tab C: Safety
            GoRoute(
              path: '/safety',
              name: 'safety',
              builder: (ctx, state) => const SafetyCenterScreen(),
              routes: [
                GoRoute(
                  path: 'sos',
                  name: 'sos',
                  builder: (ctx, state) => const SosScreen(),
                ),
                GoRoute(
                  path: 'incident',
                  name: 'incident',
                  builder: (ctx, state) => const IncidentReportScreen(),
                ),
                GoRoute(
                  path: 'contacts',
                  name: 'emergency-contacts',
                  builder: (ctx, state) => const EmergencyContactsScreen(),
                ),
              ],
            ),

            // Tab D: Profile
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (ctx, state) => const ProfileScreen(),
              routes: [
                GoRoute(
                  path: 'settings',
                  name: 'settings',
                  builder: (ctx, state) => const SettingsScreen(),
                ),
              ],
            ),
          ],
        ),

        // ── Ride request flow (full-screen, outside shell) ─────────────
        GoRoute(
          path: '/home/location-select',
          name: 'location-select',
          builder: (ctx, state) => const LocationSearchScreen(),
        ),
        GoRoute(
          path: '/home/ride-options',
          name: 'ride-options',
          builder: (ctx, state) => const RideOptionsScreen(),
        ),
        GoRoute(
          path: '/home/pool-preview',
          name: 'pool-preview',
          builder: (ctx, state) => const PoolPreviewScreen(),
        ),
        GoRoute(
          path: '/home/searching',
          name: 'searching',
          builder: (ctx, state) => const SearchingScreen(),
        ),

        // ── Trip lifecycle (full-screen) ───────────────────────────────
        GoRoute(
          path: '/trip/:tripId/assigned',
          name: 'trip-assigned',
          builder: (ctx, state) => const DriverAssignedScreen(),
        ),
        GoRoute(
          path: '/trip/:tripId/arriving',
          name: 'trip-arriving',
          builder: (ctx, state) => const DriverArrivingScreen(),
        ),
        GoRoute(
          path: '/trip/:tripId/in-progress',
          name: 'trip-in-progress',
          builder: (ctx, state) => const InTripScreen(),
        ),
        GoRoute(
          path: '/trip/:tripId/completed',
          name: 'trip-completed',
          builder: (ctx, state) => const TripCompletedScreen(),
        ),
        GoRoute(
          path: '/trip/:tripId/cancelled',
          name: 'trip-cancelled',
          builder: (ctx, state) => const TripCancelledScreen(),
        ),

        // ── Fare / Payment / Rating ────────────────────────────────────
        GoRoute(
          path: '/trip/:tripId/fare',
          name: 'trip-fare',
          builder: (ctx, state) => const FareBreakdownScreen(),
        ),
        GoRoute(
          path: '/trip/:tripId/payment',
          name: 'trip-payment',
          builder: (ctx, state) => const PaymentSelectionScreen(),
        ),
        GoRoute(
          path: '/trip/:tripId/receipt',
          name: 'trip-receipt',
          builder: (ctx, state) => const ReceiptScreen(),
        ),
        GoRoute(
          path: '/trip/:tripId/rating',
          name: 'trip-rating',
          builder: (ctx, state) => const RatingScreen(),
        ),
      ],

      errorBuilder: (ctx, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                'Page not found',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('${state.uri}',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ctx.go('/home'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shell with bottom navigation ─────────────────────────────────────────

/// Persistent bottom-tab navigator shell.
/// All tab children are lazily built; switching tabs does NOT rebuild them.
class _AppShell extends StatefulWidget {
  final Widget child;
  const _AppShell({required this.child});

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  // Ordered to match GoRouter route declaration
  static const _tabs = ['/home', '/trips', '/safety', '/profile'];
  static const _labels = ['Ride', 'Trips', 'Safety', 'Profile'];
  static const _activeIcons = [
    Icons.home_rounded,
    Icons.receipt_long_rounded,
    Icons.security_rounded,
    Icons.person_rounded,
  ];
  static const _inactiveIcons = [
    Icons.home_outlined,
    Icons.receipt_long_outlined,
    Icons.security_outlined,
    Icons.person_outline_rounded,
  ];

  int _currentIndex = 0;

  String _locationToIndex(String location) {
    for (int i = _tabs.length - 1; i >= 0; i--) {
      if (location.startsWith(_tabs[i])) return _tabs[i];
    }
    return _tabs[0];
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    _currentIndex =
        _tabs.indexOf(_locationToIndex(location)).clamp(0, _tabs.length - 1);

    return BlocListener<RideBloc, RideState>(
      // ── State-driven navigation bridge ──────────────────────────────
      // This listener receives every RideBloc state change (anywhere in the app)
      // and navigates to the correct full-screen route.
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (ctx, state) {
        final tripId = state.rideId ?? 'current';
        switch (state.status) {
          case RideStatus.driverFound:
            ctx.push('/trip/$tripId/assigned');
          case RideStatus.arrived:
            ctx.push('/trip/$tripId/arriving');
          case RideStatus.inProgress:
            ctx.push('/trip/$tripId/in-progress');
          case RideStatus.completed:
            ctx.push('/trip/$tripId/completed');
          case RideStatus.cancelled:
            ctx.push('/trip/$tripId/cancelled');
          case RideStatus.noDriversFound:
            break; // SearchingScreen's own BlocListener handles this
          default:
            break;
        }
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) {
                if (i != _currentIndex) {
                  context.go(_tabs[i]);
                }
              },
              backgroundColor: const Color(0xFF1A1A2E),
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white54,
              selectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              items: List.generate(
                _tabs.length,
                (i) => BottomNavigationBarItem(
                  icon: Icon(
                    _currentIndex == i
                        ? _activeIcons[i]
                        : _inactiveIcons[i],
                  ),
                  label: _labels[i],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── GoRouter refresh helper ───────────────────────────────────────────────

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
