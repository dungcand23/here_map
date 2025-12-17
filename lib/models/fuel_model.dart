class FuelModel {
  final double consumptionPer100km;
  final double pricePerLiter;

  const FuelModel({
    required this.consumptionPer100km,
    required this.pricePerLiter,
  });

  double calcCost(double distanceKm) {
    return (distanceKm / 100) * consumptionPer100km * pricePerLiter;
  }

  Map<String, dynamic> toJson() => {
    'consumptionPer100km': consumptionPer100km,
    'pricePerLiter': pricePerLiter,
  };

  factory FuelModel.fromJson(Map<String, dynamic> json) {
    return FuelModel(
      consumptionPer100km: json['consumptionPer100km'],
      pricePerLiter: json['pricePerLiter'],
    );
  }

  static FuelModel defaultValue() => const FuelModel(
    consumptionPer100km: 5.0,
    pricePerLiter: 22000,
  );
}
