class StopModel {
  final double lat;
  final double lng;
  final String name;

  /// Optional: full address / extra context for UI display.
  /// Example: "Phường 2, Quận Tân Bình, Hồ Chí Minh, Việt Nam"
  final String subtitle;

  const StopModel({
    required this.lat,
    required this.lng,
    required this.name,
    this.subtitle = '',
  });

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    'name': name,
    'subtitle': subtitle,
  };

  factory StopModel.fromJson(Map<String, dynamic> json) {
    return StopModel(
      lat: json['lat'],
      lng: json['lng'],
      name: json['name'],
      subtitle: (json['subtitle'] ?? '').toString(),
    );
  }
}
