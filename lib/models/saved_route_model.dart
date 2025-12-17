import 'vehicle_model.dart';
import 'stop_model.dart';
import 'truck_option_model.dart';

class SavedRouteModel {
  final String id;
  final String name;

  final double distanceKm;
  final double durationMin;

  /// Snapshot route đúng yêu cầu: lưu TUYẾN (không lưu vị trí rời rạc)
  final List<StopModel> stops;
  final VehicleModel? vehicle;
  final TruckOptionModel? truckOption;
  final String? mapMode;
  final bool? trafficEnabled;

  final DateTime createdAt;

  const SavedRouteModel({
    required this.id,
    required this.name,
    required this.distanceKm,
    required this.durationMin,
    required this.createdAt,
    this.stops = const [],
    this.vehicle,
    this.truckOption,
    this.mapMode,
    this.trafficEnabled,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'distanceKm': distanceKm,
    'durationMin': durationMin,
    'createdAt': createdAt.toIso8601String(),
    'stops': stops.map((e) => e.toJson()).toList(),
    'vehicle': vehicle?.toJson(),
    'truckOption': truckOption?.toJson(),
    'mapMode': mapMode,
    'trafficEnabled': trafficEnabled,
  };

  factory SavedRouteModel.fromJson(Map<String, dynamic> json) {
    final stopsJson = (json['stops'] as List<dynamic>?) ?? const [];
    return SavedRouteModel(
      id: json['id'],
      name: json['name'],
      distanceKm: (json['distanceKm'] as num).toDouble(),
      durationMin: (json['durationMin'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      stops: stopsJson
          .whereType<Map<String, dynamic>>()
          .map((e) => StopModel.fromJson(e))
          .toList(),
      vehicle: (json['vehicle'] is Map<String, dynamic>)
          ? VehicleModel.fromJson(json['vehicle'])
          : null,
      truckOption: (json['truckOption'] is Map<String, dynamic>)
          ? TruckOptionModel.fromJson(json['truckOption'])
          : null,
      mapMode: json['mapMode'] as String?,
      trafficEnabled: json['trafficEnabled'] as bool?,
    );
  }
}
