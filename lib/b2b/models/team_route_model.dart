import '../../models/stop_model.dart';
import '../../models/truck_option_model.dart';

class TeamRouteModel {
  final String id;
  final String teamId;
  final String name;
  final double distanceKm;
  final double durationMin;
  final List<StopModel> stops;
  final String vehicleMode;
  final TruckOptionModel truckOption;
  final bool trafficEnabled;
  final String mapMode;
  final String createdBy;
  final DateTime createdAt;

  const TeamRouteModel({
    required this.id,
    required this.teamId,
    required this.name,
    required this.distanceKm,
    required this.durationMin,
    required this.stops,
    required this.vehicleMode,
    required this.truckOption,
    required this.trafficEnabled,
    required this.mapMode,
    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'teamId': teamId,
        'name': name,
        'distanceKm': distanceKm,
        'durationMin': durationMin,
        'stops': stops.map((e) => e.toJson()).toList(),
        'vehicleMode': vehicleMode,
        'truckOption': truckOption.toJson(),
        'trafficEnabled': trafficEnabled,
        'mapMode': mapMode,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TeamRouteModel.fromJson(Map<String, dynamic> json) {
    return TeamRouteModel(
      id: (json['id'] ?? '').toString(),
      teamId: (json['teamId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      distanceKm: (json['distanceKm'] is num)
          ? (json['distanceKm'] as num).toDouble()
          : double.tryParse((json['distanceKm'] ?? '0').toString()) ?? 0,
      durationMin: (json['durationMin'] is num)
          ? (json['durationMin'] as num).toDouble()
          : double.tryParse((json['durationMin'] ?? '0').toString()) ?? 0,
      stops: ((json['stops'] as List?) ?? const [])
          .map((e) => StopModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      vehicleMode: (json['vehicleMode'] ?? 'car').toString(),
      truckOption: json['truckOption'] is Map
          ? TruckOptionModel.fromJson(Map<String, dynamic>.from(json['truckOption'] as Map))
          : TruckOptionModel.empty(),
      trafficEnabled: (json['trafficEnabled'] ?? false) == true,
      mapMode: (json['mapMode'] ?? 'normal').toString(),
      createdBy: (json['createdBy'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}
