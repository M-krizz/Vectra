import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/socket/socket_service.dart';
import '../../../../core/api/api_client.dart';

/// Heatmap hexagon data
class HeatmapHexagon {
  final LatLng center;
  final double demandLevel; // 0.0 to 1.0
  final double surgeMultiplier; // 1.0 = no surge, 1.5 = 50% surge
  final String? zoneName;

  HeatmapHexagon({
    required this.center,
    required this.demandLevel,
    this.surgeMultiplier = 1.0,
    this.zoneName,
  });

  bool get hasSurge => surgeMultiplier > 1.0;

  factory HeatmapHexagon.fromJson(Map<String, dynamic> json) {
    return HeatmapHexagon(
      center: LatLng(
        json['lat'] as double,
        json['lng'] as double,
      ),
      demandLevel: (json['demand_level'] as num).toDouble(),
      surgeMultiplier: (json['surge_multiplier'] as num?)?.toDouble() ?? 1.0,
      zoneName: json['zone_name'] as String?,
    );
  }
}

/// Today's earnings summary
class TodayEarnings {
  final double totalAmount;
  final int tripCount;
  final double onlineHours;
  final double co2Saved;

  TodayEarnings({
    required this.totalAmount,
    required this.tripCount,
    required this.onlineHours,
    required this.co2Saved,
  });

  factory TodayEarnings.empty() {
    return TodayEarnings(
      totalAmount: 0.0,
      tripCount: 0,
      onlineHours: 0.0,
      co2Saved: 0.0,
    );
  }

  factory TodayEarnings.fromJson(Map<String, dynamic> json) {
    return TodayEarnings(
      totalAmount: (json['total_amount'] as num).toDouble(),
      tripCount: json['trip_count'] as int,
      onlineHours: (json['online_hours'] as num?)?.toDouble() ?? 0.0,
      co2Saved: (json['co2_saved'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Map home state
class MapHomeState {
  final List<HeatmapHexagon> heatmapData;
  final TodayEarnings earnings;
  final bool showDemandLayer;
  final bool showSurgeLayer;
  final LatLng? currentLocation;
  final LatLng? gotoDestination;
  final bool isLoading;
  final String? error;

  MapHomeState({
    this.heatmapData = const [],
    TodayEarnings? earnings,
    this.showDemandLayer = true,
    this.showSurgeLayer = true,
    this.currentLocation,
    this.gotoDestination,
    this.isLoading = false,
    this.error,
  }) : earnings = earnings ?? TodayEarnings.empty();

  MapHomeState copyWith({
    List<HeatmapHexagon>? heatmapData,
    TodayEarnings? earnings,
    bool? showDemandLayer,
    bool? showSurgeLayer,
    LatLng? currentLocation,
    LatLng? gotoDestination,
    bool? isLoading,
    String? error,
  }) {
    return MapHomeState(
      heatmapData: heatmapData ?? this.heatmapData,
      earnings: earnings ?? this.earnings,
      showDemandLayer: showDemandLayer ?? this.showDemandLayer,
      showSurgeLayer: showSurgeLayer ?? this.showSurgeLayer,
      currentLocation: currentLocation ?? this.currentLocation,
      gotoDestination: gotoDestination ?? this.gotoDestination,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Map home notifier
class MapHomeNotifier extends StateNotifier<MapHomeState> {
  final SocketService _socketService;
  final ApiClient _apiClient;

  MapHomeNotifier({
    required SocketService socketService,
    required ApiClient apiClient,
  })  : _socketService = socketService,
        _apiClient = apiClient,
        super(MapHomeState()) {
    _initialize();
  }

  void _initialize() {
    _loadInitialData();
    _subscribeToHeatmapUpdates();
  }

  Future<void> _loadInitialData() async {
    state = state.copyWith(isLoading: true);

    try {
      // Load earnings and heatmap data
      // In production, fetch from API
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock data
      final mockEarnings = TodayEarnings(
        totalAmount: 2847.50,
        tripCount: 12,
        onlineHours: 8.5,
        co2Saved: 24.0,
      );

      final mockHeatmap = _generateMockHeatmap();

      state = state.copyWith(
        earnings: mockEarnings,
        heatmapData: mockHeatmap,
        currentLocation: LatLng(12.9716, 77.5946), // MG Road, Bangalore
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  List<HeatmapHexagon> _generateMockHeatmap() {
    // Generate mock hexagon data for Bangalore
    return [
      HeatmapHexagon(
        center: LatLng(12.9716, 77.5946),
        demandLevel: 0.8,
        surgeMultiplier: 1.5,
        zoneName: 'MG Road',
      ),
      HeatmapHexagon(
        center: LatLng(12.9352, 77.6245),
        demandLevel: 0.6,
        surgeMultiplier: 1.0,
        zoneName: 'Koramangala',
      ),
      HeatmapHexagon(
        center: LatLng(12.9784, 77.6408),
        demandLevel: 0.9,
        surgeMultiplier: 1.8,
        zoneName: 'Indiranagar',
      ),
      HeatmapHexagon(
        center: LatLng(12.9569, 77.7011),
        demandLevel: 0.5,
        surgeMultiplier: 1.2,
        zoneName: 'Marathahalli',
      ),
      HeatmapHexagon(
        center: LatLng(13.0067, 77.5695),
        demandLevel: 0.7,
        surgeMultiplier: 1.0,
        zoneName: 'Malleshwaram',
      ),
      HeatmapHexagon(
        center: LatLng(12.9141, 77.6411),
        demandLevel: 0.65,
        surgeMultiplier: 1.3,
        zoneName: 'HSR Layout',
      ),
    ];
  }

  void _subscribeToHeatmapUpdates() {
    _socketService.heatmapStream.listen((data) {
      if (data['type'] == 'surge') {
        // Update surge data
        _updateSurgeData(data['data']);
      } else {
        // Update demand data
        _updateHeatmapData(data);
      }
    });
  }

  void _updateHeatmapData(Map<String, dynamic> data) {
    // Parse and update heatmap
  }

  void _updateSurgeData(Map<String, dynamic> data) {
    // Parse and update surge multipliers
  }

  /// Toggle demand layer visibility
  void toggleDemandLayer() {
    state = state.copyWith(showDemandLayer: !state.showDemandLayer);
  }

  /// Toggle surge layer visibility
  void toggleSurgeLayer() {
    state = state.copyWith(showSurgeLayer: !state.showSurgeLayer);
  }

  /// Set "Go To" destination filter
  void setGotoDestination(LatLng? destination) {
    state = state.copyWith(gotoDestination: destination);
  }

  /// Clear goto destination
  void clearGotoDestination() {
    state = MapHomeState(
      heatmapData: state.heatmapData,
      earnings: state.earnings,
      showDemandLayer: state.showDemandLayer,
      showSurgeLayer: state.showSurgeLayer,
      currentLocation: state.currentLocation,
      gotoDestination: null,
      isLoading: state.isLoading,
      error: state.error,
    );
  }

  /// Update current location
  void updateCurrentLocation(LatLng location) {
    state = state.copyWith(currentLocation: location);
  }

  /// Refresh data
  Future<void> refresh() async {
    await _loadInitialData();
  }
}

// Provider
final mapHomeProvider =
    StateNotifierProvider<MapHomeNotifier, MapHomeState>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  final apiClient = ref.watch(apiClientProvider);

  return MapHomeNotifier(
    socketService: socketService,
    apiClient: apiClient,
  );
});

// Convenience providers
final todayEarningsProvider = Provider<TodayEarnings>((ref) {
  return ref.watch(mapHomeProvider).earnings;
});

final heatmapDataProvider = Provider<List<HeatmapHexagon>>((ref) {
  return ref.watch(mapHomeProvider).heatmapData;
});
