import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';

import 'config/app_router.dart';
import 'config/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/ride/bloc/ride_bloc.dart';
import 'features/ride/repository/places_repository.dart';
import 'features/ride/repository/ride_repository.dart';
import 'core/socket/socket_service.dart';
import 'features/ride/services/trip_socket_service.dart';
import 'features/profile/repository/saved_places_repository.dart';
import 'features/profile/bloc/saved_places_bloc.dart';
import 'features/profile/bloc/saved_places_event.dart';

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
        RepositoryProvider<RideRepository>(
          create: (context) => RideRepository(apiClient: apiClient),
        ),
        RepositoryProvider<SocketService>(
          create: (context) => SocketService(storageService: storageService)..connect(),
        ),
        RepositoryProvider<TripSocketService>(
          create: (context) {
            final service = TripSocketService(baseUrl: ApiConstants.baseUrl);
            storageService.getAccessToken().then((token) {
              if (token != null) service.connect(token: token);
            });
            return service;
          },
        ),
        RepositoryProvider<SavedPlacesRepository>(
          create: (context) => SavedPlacesRepository(),
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
                RideBloc(
                  placesRepository: context.read<PlacesRepository>(),
                  rideRepository: context.read<RideRepository>(),
                  tripSocketService: context.read<TripSocketService>(),
                ),
          ),
          BlocProvider(
            create: (context) =>
                SavedPlacesBloc(repository: context.read<SavedPlacesRepository>())
                  ..add(LoadSavedPlaces()),
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
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router(context),
    );
  }
}
