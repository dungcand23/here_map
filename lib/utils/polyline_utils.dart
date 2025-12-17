class PolylineUtils {
  /// Decode HERE flexible polyline (v8) thành list {lat, lng}
  /// Nếu lỗi → trả về list rỗng để không làm app crash.
  static List<Map<String, double>> decodeFlexiblePolyline(String encoded) {
    if (encoded.isEmpty) return [];

    int index = 0;

    int _decodeUnsigned() {
      int result = 0;
      int shift = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20 && index < encoded.length);
      return result;
    }

    int _decodeSigned() {
      final res = _decodeUnsigned();
      final negative = (res & 1) != 0;
      final value = res >> 1;
      return negative ? -value : value;
    }

    // Header
    final header = _decodeUnsigned();
    final precision = header & 15; // 4 bits cuối
    final factor = _pow10(precision);

    int lat = 0;
    int lng = 0;

    final coords = <Map<String, double>>[];

    while (index < encoded.length) {
      lat += _decodeSigned();
      lng += _decodeSigned();

      coords.add({
        'lat': lat / factor,
        'lng': lng / factor,
      });
    }

    return coords;
  }

  static double _pow10(int n) {
    double r = 1.0;
    for (int i = 0; i < n; i++) {
      r *= 10.0;
    }
    return r;
  }
}
