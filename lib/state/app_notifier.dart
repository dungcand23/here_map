import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/stop_model.dart';
import '../models/vehicle_model.dart';
import '../models/truck_option_model.dart';
import '../models/fuel_model.dart';
import '../models/saved_route_model.dart';
import 'app_state.dart';

class AppNotifier extends ChangeNotifier {
  AppState _state = AppState.initial();
  AppState get state => _state;

  AppNotifier() {
    _loadState();
  }

  StopModel _emptyStop() => const StopModel(lat: 0, lng: 0, name: '');

  bool _isFilled(StopModel s) => s.name.trim().isNotEmpty && (s.lat != 0 || s.lng != 0);

  /// ✅ Quy tắc giống Google/WeGo:
  /// - Ban đầu: chỉ A
  /// - A có data -> hiện B
  /// - B có data -> hiện stop mới (+)
  /// - Stop cuối có data -> tự append thêm 1 stop trống
  void _normalizeStops() {
    final stops = List<StopModel>.from(_state.stops);

    if (stops.isEmpty) {
      stops.add(_emptyStop()); // A
    }

    // Nếu A trống thì chỉ giữ đúng 1 ô A
    final aFilled = _isFilled(stops[0]);
    if (!aFilled) {
      _state = _state.copyWith(stops: [stops[0]]);
      return;
    }

    // A có -> phải có B
    if (stops.length < 2) stops.add(_emptyStop());
    final bFilled = _isFilled(stops[1]);

    // B có -> phải có ít nhất 1 ô stop mới
    if (bFilled) {
      if (stops.length < 3) stops.add(_emptyStop());
      // nếu ô cuối đã có data thì append thêm ô trống
      final last = stops.last;
      if (_isFilled(last)) stops.add(_emptyStop());
    } else {
      // B chưa có thì cắt về đúng A + B
      if (stops.length > 2) {
        _state = _state.copyWith(stops: [stops[0], stops[1]]);
        return;
      }
    }

    _state = _state.copyWith(stops: stops);
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();

    final stopsJson = prefs.getStringList('stops') ?? [];
    final vehiclesJson = prefs.getStringList('vehicles') ?? [];
    final truckJson = prefs.getString('truck') ?? '';
    final savedRoutesJson = prefs.getStringList('savedRoutes') ?? [];

    final stops = stopsJson.map((e) => StopModel.fromJson(jsonDecode(e))).toList();
    final vehicles = vehiclesJson.map((e) => VehicleModel.fromJson(jsonDecode(e))).toList();

    final truckOption = truckJson.isNotEmpty
        ? TruckOptionModel.fromJson(jsonDecode(truckJson))
        : TruckOptionModel.empty();

    final savedRoutes = savedRoutesJson.map((e) => SavedRouteModel.fromJson(jsonDecode(e))).toList();

    _state = _state.copyWith(
      stops: stops.isNotEmpty ? stops : _state.stops,
      vehicles: vehicles.isNotEmpty ? vehicles : _state.vehicles,
      truckOption: truckOption,
      savedRoutes: savedRoutes,
    );

    // ✅ set mặc định gợi ý = van/ô tô
    _state = _state.copyWith(currentVehicle: _pickVehicleByMode('car'));

    _normalizeStops();
    _saveStops();
    notifyListeners();
  }

  VehicleModel? _pickVehicleByMode(String mode) {
    for (final v in _state.vehicles) {
      if (v.mode == mode) return v;
    }
    return _state.vehicles.isNotEmpty ? _state.vehicles.first : null;
  }

  Future<void> _saveStops() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('stops', _state.stops.map((e) => jsonEncode(e.toJson())).toList());
  }

  Future<void> _saveVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('vehicles', _state.vehicles.map((e) => jsonEncode(e.toJson())).toList());
  }

  Future<void> _saveTruck() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('truck', jsonEncode(_state.truckOption.toJson()));
  }

  Future<void> _saveSavedRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'savedRoutes',
      _state.savedRoutes.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  /// ✅ update stop bằng StopModel có lat/lng thật
  void updateStop(int index, StopModel stop) {
    final stops = List<StopModel>.from(_state.stops);
    if (index < 0 || index >= stops.length) return;

    stops[index] = stop;
    _state = _state.copyWith(stops: stops);

    _normalizeStops();
    _saveStops();
    notifyListeners();
  }

  void clearStop(int index) {
    final stops = List<StopModel>.from(_state.stops);
    if (index < 0 || index >= stops.length) return;

    stops[index] = _emptyStop();
    _state = _state.copyWith(stops: stops);

    _normalizeStops();
    _saveStops();
    notifyListeners();
  }

  void removeStop(int index) {
    final stops = List<StopModel>.from(_state.stops);
    if (index < 0 || index >= stops.length) return;

    // không xoá A/B, chỉ clear
    if (index == 0 || index == 1) {
      stops[index] = _emptyStop();
    } else {
      stops.removeAt(index);
    }
    _state = _state.copyWith(stops: stops);

    _normalizeStops();
    _saveStops();
    notifyListeners();
  }

  void reorderStops(int oldIndex, int newIndex) {
    final stops = List<StopModel>.from(_state.stops);

    // chỉ reorder stop trung gian (>=2)
    if (oldIndex < 2 || newIndex < 2) return;
    if (oldIndex >= stops.length || newIndex >= stops.length) return;

    final item = stops.removeAt(oldIndex);
    stops.insert(newIndex, item);

    _state = _state.copyWith(stops: stops);
    _saveStops();
    notifyListeners();
  }

  // ✅ Gợi ý phương tiện: van / truck (bỏ VehicleSelector)
  void setSuggestedVehicleMode(String mode) {
    _state = _state.copyWith(currentVehicle: _pickVehicleByMode(mode));
    notifyListeners();
  }

  void updateTruck(TruckOptionModel t) {
    _state = _state.copyWith(truckOption: t);
    _saveTruck();
    notifyListeners();
  }

  void saveRoute(SavedRouteModel r) {
    final list = List<SavedRouteModel>.from(_state.savedRoutes)..add(r);
    _state = _state.copyWith(savedRoutes: list);
    _saveSavedRoutes();
    notifyListeners();
  }

  void setTraffic(bool enabled) {
    _state = _state.copyWith(trafficEnabled: enabled);
    notifyListeners();
  }

  void setMapMode(String mode) {
    _state = _state.copyWith(mapMode: mode);
    notifyListeners();
  }
}
