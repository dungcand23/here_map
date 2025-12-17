import 'package:flutter/material.dart';
import '../models/stop_model.dart';
import '../models/vehicle_model.dart';
import '../models/truck_option_model.dart';
import '../models/fuel_model.dart';
import '../models/saved_route_model.dart';

class AppState {
  final List<StopModel> stops;
  final VehicleModel? currentVehicle;
  final List<VehicleModel> vehicles;
  final TruckOptionModel truckOption;
  final FuelModel fuel;
  final bool trafficEnabled;
  final String mapMode;
  final List<SavedRouteModel> savedRoutes;

  const AppState({
    required this.stops,
    required this.currentVehicle,
    required this.vehicles,
    required this.truckOption,
    required this.fuel,
    required this.trafficEnabled,
    required this.mapMode,
    required this.savedRoutes,
  });

  factory AppState.initial() {
    return AppState(
      // ✅ ban đầu chỉ có 1 ô A
      stops: const [
        StopModel(lat: 0, lng: 0, name: ''),
      ],
      currentVehicle: null,
      vehicles: _defaultVehicles,
      truckOption: TruckOptionModel.empty(),
      fuel: FuelModel.defaultValue(),
      trafficEnabled: false,
      mapMode: "normal",
      savedRoutes: const [],
    );
  }

  AppState copyWith({
    List<StopModel>? stops,
    VehicleModel? currentVehicle,
    List<VehicleModel>? vehicles,
    TruckOptionModel? truckOption,
    FuelModel? fuel,
    bool? trafficEnabled,
    String? mapMode,
    List<SavedRouteModel>? savedRoutes,
  }) {
    return AppState(
      stops: stops ?? this.stops,
      currentVehicle: currentVehicle ?? this.currentVehicle,
      vehicles: vehicles ?? this.vehicles,
      truckOption: truckOption ?? this.truckOption,
      fuel: fuel ?? this.fuel,
      trafficEnabled: trafficEnabled ?? this.trafficEnabled,
      mapMode: mapMode ?? this.mapMode,
      savedRoutes: savedRoutes ?? this.savedRoutes,
    );
  }
}

final List<VehicleModel> _defaultVehicles = [
  VehicleModel(id: "motor", name: "Xe máy", icon: Icons.motorcycle, mode: "scooter"),
  VehicleModel(id: "car", name: "Van / Ô tô", icon: Icons.directions_car, mode: "car"),
  VehicleModel(id: "truck1", name: "Xe tải", icon: Icons.local_shipping, mode: "truck"),
];
