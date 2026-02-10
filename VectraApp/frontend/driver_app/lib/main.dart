import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/presentation/screens/phone_input_screen.dart';
import 'features/map_home/presentation/screens/driver_dashboard_screen.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/auth/data/models/auth_tokens.dart'; // For AuthState enum
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style for premium feel
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF080808),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const ProviderScope(child: VectraDriverApp()));
}

class VectraDriverApp extends ConsumerWidget {
  const VectraDriverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateData = ref.watch(authProvider);
    
    // Determine home screen based on auth state
    Widget homeScreen;
    if (authStateData.state == AuthState.authenticated) {
      homeScreen = const DriverDashboardScreen();
    } else if (authStateData.state == AuthState.loading || 
               authStateData.state == AuthState.initial) {
      homeScreen = const Scaffold(
        backgroundColor: AppColors.voidBlack,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.hyperLime),
        ),
      );
    } else {
      homeScreen = const PhoneInputScreen();
    }
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vectra Driver',
      theme: AppTheme.darkTheme,
      home: homeScreen,
    );
  }
}
