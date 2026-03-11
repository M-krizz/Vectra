import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/socket/socket_service.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../rides/data/models/trip.dart';

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
  StreamSubscription<Map<String, dynamic>>? _heatmapSubscription;

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
    state = state.copyWith(isLoading: true, error: null);

    try {
      final earnings = await _fetchTodayEarnings();

      state = state.copyWith(
        earnings: earnings,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<TodayEarnings> _fetchTodayEarnings() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.tripHistory);
      final trips = _extractTrips(response.data);

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      var todayAmount = 0.0;
      var todayTrips = 0;

      for (final trip in trips) {
        if (trip.status != TripStatus.completed || trip.completedAt == null) {
          continue;
        }

        if (trip.completedAt!.isBefore(todayStart)) {
          continue;
        }

        todayAmount += trip.fare;
        todayTrips += 1;
      }

      // Online hours and CO2 savings will come from dedicated backend metrics in next phase.
      return TodayEarnings(
        totalAmount: todayAmount,
        tripCount: todayTrips,
        onlineHours: state.earnings.onlineHours,
        co2Saved: state.earnings.co2Saved,
      );
    } catch (_) {
      return state.earnings;
    }
  }

  List<Trip> _extractTrips(dynamic payload) {
    final rawList = _extractList(payload);
    return rawList
        .whereType<Map>()
        .map((entry) => Trip.fromJson(Map<String, dynamic>.from(entry)))
        .toList();
  }

  List<dynamic> _extractList(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is List) return data;

      final items = payload['items'];
      if (items is List) return items;

      if (data is Map<String, dynamic>) {
        final nestedItems = data['items'];
        if (nestedItems is List) return nestedItems;
      }
    }
    return const [];
  }

  void _subscribeToHeatmapUpdates() {
    _heatmapSubscription?.cancel();
    _heatmapSubscription = _socketService.heatmapStream.listen((data) {
      if (data['type'] == 'surge') {
        _updateSurgeData(data);
      } else {
        _updateHeatmapData(data);
      }
    });
  }

  void _updateHeatmapData(Map<String, dynamic> data) {
    final incoming = _parseHexagons(data);
    if (incoming.isEmpty) return;

    final merged = _mergeHexagons(
      base: state.heatmapData,
      incoming: incoming,
      overwriteDemand: true,
      overwriteSurge: false,
    );

    state = state.copyWith(heatmapData: merged, error: null);
  }

  void _updateSurgeData(Map<String, dynamic> data) {
    final incoming = _parseHexagons(data);
    if (incoming.isEmpty) return;

    final merged = _mergeHexagons(
      base: state.heatmapData,
      incoming: incoming,
      overwriteDemand: false,
      overwriteSurge: true,
    );

    state = state.copyWith(heatmapData: merged, error: null);
  }

  List<HeatmapHexagon> _parseHexagons(Map<String, dynamic> payload) {
    final candidates = <dynamic>[
      payload['data'],
      payload['hotspots'],
      payload['hexagons'],
      payload['zones'],
      payload,
    ];

    for (final candidate in candidates) {
      final list = _extractList(candidate);
      if (list.isEmpty) continue;

      final parsed = list
          .whereType<Map>()
          .map((entry) => _tryHexagonFromDynamic(entry))
          .whereType<HeatmapHexagon>()
          .toList();

      if (parsed.isNotEmpty) {
        return parsed;
      }
    }

    return const [];
  }

  HeatmapHexagon? _tryHexagonFromDynamic(Map<dynamic, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);

    final latRaw = map['lat'] ?? map['latitude'];
    final lngRaw = map['lng'] ?? map['lon'] ?? map['longitude'];
    if (latRaw is! num || lngRaw is! num) {
      return null;
    }

    final demandRaw = map['demand_level'] ?? map['demandLevel'] ?? map['demand'] ?? 0;
    final surgeRaw = map['surge_multiplier'] ?? map['surgeMultiplier'] ?? map['surge'] ?? 1;

    return HeatmapHexagon(
      center: LatLng(latRaw.toDouble(), lngRaw.toDouble()),
      demandLevel: (demandRaw as num?)?.toDouble() ?? 0,
      surgeMultiplier: (surgeRaw as num?)?.toDouble() ?? 1,
      zoneName: (map['zone_name'] ?? map['zoneName']) as String?,
    );
  }

  List<HeatmapHexagon> _mergeHexagons({
    required List<HeatmapHexagon> base,
    required List<HeatmapHexagon> incoming,
    required bool overwriteDemand,
    required bool overwriteSurge,
  }) {
    final merged = <String, HeatmapHexagon>{
      for (final item in base) _hexagonKey(item): item,
    };

    for (final item in incoming) {
      final key = _hexagonKey(item);
      final existing = merged[key];

      if (existing == null) {
        merged[key] = item;
        continue;
      }

      merged[key] = HeatmapHexagon(
        center: existing.center,
        demandLevel: overwriteDemand ? item.demandLevel : existing.demandLevel,
        surgeMultiplier:
            overwriteSurge ? item.surgeMultiplier : existing.surgeMultiplier,
        zoneName: item.zoneName ?? existing.zoneName,
      );
    }

    return merged.values.toList();
  }

  String _hexagonKey(HeatmapHexagon hexagon) {
    final zone = hexagon.zoneName?.trim().toLowerCase();
    if (zone != null && zone.isNotEmpty) return 'zone:$zone';

    final lat = hexagon.center.latitude.toStringAsFixed(4);
    final lng = hexagon.center.longitude.toStringAsFixed(4);
    return 'coord:$lat,$lng';
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

  @override
  void dispose() {
    _heatmapSubscription?.cancel();
    super.dispose();
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
