class StopModel {
  final double lat;
  final double lng;
  final String name;

  const StopModel({
    required this.lat,
    required this.lng,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    'name': name,
  };

  factory StopModel.fromJson(Map<String, dynamic> json) {
    return StopModel(
      lat: json['lat'],
      lng: json['lng'],
      name: json['name'],
    );
  }
}
