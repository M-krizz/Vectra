import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import 'config/app_router.dart';
import 'config/app_theme.dart';
import 'config/theme_cubit.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/ride/bloc/ride_bloc.dart';
import 'features/ride/repository/places_repository.dart';
import 'features/ride/repository/ride_repository.dart';
import 'features/profile/repository/saved_places_repository.dart';
import 'features/profile/bloc/saved_places_bloc.dart';
import 'features/profile/bloc/saved_places_event.dart';
import 'features/ride/services/trip_socket_service.dart';
import 'features/safety/repository/safety_repository.dart';
import 'features/safety/bloc/safety_bloc.dart';
import 'features/history/repository/history_repository.dart';
import 'features/history/bloc/history_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final storageService = StorageService.getInstance();
  final apiClient = ApiClient.getInstance(storageService);
  final tripSocketService = TripSocketService(baseUrl: ApiConstants.baseUrl);
  runApp(VectraRiderApp(
    storageService: storageService,
    apiClient: apiClient,
    tripSocketService: tripSocketService,
  ));
}

class VectraRiderApp extends StatelessWidget {
  final StorageService storageService;
  final ApiClient apiClient;
  final TripSocketService tripSocketService;

  const VectraRiderApp({
    super.key,  
    required this.storageService,
    required this.apiClient,
    required this.tripSocketService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<StorageService>.value(value: storageService),
        RepositoryProvider<ApiClient>.value(value: apiClient),
        RepositoryProvider<TripSocketService>.value(value: tripSocketService),
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
        RepositoryProvider<SavedPlacesRepository>(
          create: (context) => SavedPlacesRepository(),
        ),
        RepositoryProvider<SafetyRepository>(
          create: (context) => SafetyRepository(apiClient: apiClient),
        ),
        RepositoryProvider<HistoryRepository>(
          create: (context) => HistoryRepository(apiClient: apiClient),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit()),
          BlocProvider(
            create: (context) =>
                AuthBloc(authRepository: context.read<AuthRepository>())
                  ..add(AuthCheckRequested()),
          ),
          BlocProvider(
            create: (context) => RideBloc(
              placesRepository: context.read<PlacesRepository>(),
              rideRepository: context.read<RideRepository>(),
              tripSocketService: context.read<TripSocketService>(),
              storageService: context.read<StorageService>(),
            ),
          ),
          BlocProvider(
            create: (context) =>
                SavedPlacesBloc(repository: context.read<SavedPlacesRepository>())
                  ..add(LoadSavedPlaces()),
          ),
          BlocProvider(
            create: (context) =>
                SafetyBloc(repository: context.read<SafetyRepository>())
                  ..add(LoadContactsRequested()),
          ),
          BlocProvider(
            create: (context) =>
                HistoryBloc(repository: context.read<HistoryRepository>())
                  ..add(LoadHistoryRequested()),
          ),
        ],
        child: const _AppView(),
      ),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.router(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp.router(
          title: 'Vectra Rider',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: _router,
        );
      },
    );
  }
}
