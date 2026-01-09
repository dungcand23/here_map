import '../../models/stop_model.dart';
import '../../models/truck_option_model.dart';

class RouteSharePayload {
  final int v;
  final String name;
  final double distanceKm;
  final double durationMin;
  final List<StopModel> stops;
  final String vehicleMode;
  final TruckOptionModel truckOption;
  final bool trafficEnabled;
  final String mapMode;

  const RouteSharePayload({
    required this.v,
    required this.name,
    required this.distanceKm,
    required this.durationMin,
    required this.stops,
    required this.vehicleMode,
    required this.truckOption,
    required this.trafficEnabled,
    required this.mapMode,
  });

  Map<String, dynamic> toJson() => {
        'v': v,
        'name': name,
        'distanceKm': distanceKm,
        'durationMin': durationMin,
        'stops': stops.map((e) => e.toJson()).toList(),
        'vehicleMode': vehicleMode,
        'truckOption': truckOption.toJson(),
        'trafficEnabled': trafficEnabled,
        'mapMode': mapMode,
      };

  factory RouteSharePayload.fromJson(Map<String, dynamic> json) {
    return RouteSharePayload(
      v: (json['v'] is num) ? (json['v'] as num).toInt() : int.tryParse((json['v'] ?? '1').toString()) ?? 1,
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
    );
  }
}
