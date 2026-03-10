import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/signin_screen.dart';
import 'features/map_home/presentation/screens/driver_dashboard_screen.dart';
import 'core/storage/secure_storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vectra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _AppRoot(),
    );
  }
}

/// Checks stored auth token and routes to the correct initial screen without
/// touching the Riverpod auth notifier (avoids circular dependency on startup).
class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  final SecureStorageService _storage = SecureStorageService();
  bool _checking = true;
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final token = await _storage.getAccessToken();
      final role = await _storage.getUserRole();
      // Only treat as authenticated when a DRIVER token exists
      if (token != null && token.isNotEmpty && role == 'DRIVER') {
        setState(() {
          _authenticated = true;
          _checking = false;
        });
        return;
      }
    } catch (_) {}
    setState(() {
      _authenticated = false;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _authenticated
        ? const DriverDashboardScreen()
        : const SignInScreen();
  }
}
