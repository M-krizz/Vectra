import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';

import 'config/app_router.dart';
import 'config/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/ride/bloc/ride_bloc.dart';
import 'features/ride/repository/places_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final storageService = StorageService.getInstance();
  final apiClient = ApiClient.getInstance(storageService);

  runApp(VectraRiderApp(storageService: storageService, apiClient: apiClient));
}

class VectraRiderApp extends StatelessWidget {
  final StorageService storageService;
  final ApiClient apiClient;

  const VectraRiderApp({
    super.key,
    required this.storageService,
    required this.apiClient,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<StorageService>.value(value: storageService),
        RepositoryProvider<ApiClient>.value(value: apiClient),
        RepositoryProvider<AuthRepository>(
          create: (context) => AuthRepository(
            apiClient: apiClient,
            storageService: storageService,
          ),
        ),
        RepositoryProvider<PlacesRepository>(
          create: (context) => PlacesRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AuthBloc(authRepository: context.read<AuthRepository>())
                  ..add(AuthCheckRequested()),
          ),
          BlocProvider(
            create: (context) =>
                RideBloc(placesRepository: context.read<PlacesRepository>()),
          ),
        ],
        child: const _AppView(),
      ),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vectra Rider',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router(context),
    );
  }
}
