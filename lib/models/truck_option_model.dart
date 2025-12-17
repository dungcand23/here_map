class TruckOptionModel {
  final double height;
  final double width;
  final double length;
  final double grossWeight;
  final int axleCount;

  const TruckOptionModel({
    required this.height,
    required this.width,
    required this.length,
    required this.grossWeight,
    required this.axleCount,
  });

  Map<String, dynamic> toJson() => {
    'height': height,
    'width': width,
    'length': length,
    'grossWeight': grossWeight,
    'axleCount': axleCount,
  };

  factory TruckOptionModel.fromJson(Map<String, dynamic> json) {
    return TruckOptionModel(
      height: json['height'],
      width: json['width'],
      length: json['length'],
      grossWeight: json['grossWeight'],
      axleCount: json['axleCount'],
    );
  }

  static TruckOptionModel empty() => const TruckOptionModel(
    height: 2.5,
    width: 2.5,
    length: 6.0,
    grossWeight: 3500,
    axleCount: 2,
  );
}
