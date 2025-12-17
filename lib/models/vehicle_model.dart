import 'package:flutter/material.dart';

class VehicleModel {
  final String id;
  final String name;
  final IconData icon;
  final String mode; // car | scooter | truck

  const VehicleModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.mode,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon.codePoint,
    'fontFamily': icon.fontFamily,
    'fontPackage': icon.fontPackage,
    'mode': mode,
  };

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'],
      name: json['name'],
      icon: IconData(
        json['icon'],
        fontFamily: json['fontFamily'],
        fontPackage: json['fontPackage'],
      ),
      mode: json['mode'],
    );
  }
}
