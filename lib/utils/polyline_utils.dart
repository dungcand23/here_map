class PolylineUtils {
  // HERE Flexible Polyline uses a custom 64-char alphabet (NOT charCode-63).
  // https://github.com/heremaps/flexible-polyline is the reference.
  static const String _alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

  static final Map<int, int> _decodeTable = {
    for (int i = 0; i < _alphabet.length; i++) _alphabet.codeUnitAt(i): i,
  };

  /// Decode HERE flexible polyline (v8) thành list {lat, lng}
  /// Nếu lỗi → trả về list rỗng để không làm app crash.
  static List<Map<String, double>> decodeFlexiblePolyline(String encoded) {
    if (encoded.isEmpty) return [];

    int index = 0;

    int _decodeChar() {
      if (index >= encoded.length) return -1;
      final code = encoded.codeUnitAt(index++);
      return _decodeTable[code] ?? -1;
    }

    int _decodeUnsignedVarint() {
      int result = 0;
      int shift = 0;
      int value;
      do {
        value = _decodeChar();
        if (value < 0) return result;
        result |= (value & 0x1F) << shift;
        shift += 5;
      } while ((value & 0x20) != 0 && index < encoded.length);
      return result;
    }

    int _decodeSignedVarint() {
      final u = _decodeUnsignedVarint();
      // ZigZag decode
      return (u >> 1) ^ (-(u & 1));
    }

    try {
      final header = _decodeUnsignedVarint();
      // Header packing (HERE Flexible Polyline spec):
      // version (3 bits) | precision (4 bits) | thirdDim (3 bits) | thirdDimPrecision (4 bits)
      // No extra varint after the header.
      // Ref: https://github.com/heremaps/flexible-polyline
      final version = header & 0x07;
      // Spec version hiện tại = 1.
      // Nếu khác, vẫn cố decode nhưng có thể fail.
      // ignore: unused_local_variable
      final _v = version;

      final precision = (header >> 3) & 0x0F;
      final thirdDim = (header >> 7) & 0x07;
      final thirdDimPrecision = (header >> 10) & 0x0F;

      final factor = _pow10(precision);
      // ignore: unused_local_variable
      final thirdFactor = _pow10(thirdDimPrecision);

      int lastLat = 0;
      int lastLng = 0;
      int lastZ = 0;

      final coords = <Map<String, double>>[];
      while (index < encoded.length) {
        lastLat += _decodeSignedVarint();
        lastLng += _decodeSignedVarint();
        if (thirdDim != 0) {
          lastZ += _decodeSignedVarint();
          // final _ = lastZ / thirdFactor;
        }

        final lat = lastLat / factor;
        final lng = lastLng / factor;

        // Guard: nếu decode lỗi sẽ ra lat ngoài [-90,90].
        if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
          continue;
        }
        coords.add({'lat': lat, 'lng': lng});
      }
      return coords;
    } catch (_) {
      return [];
    }
  }

  static double _pow10(int n) {
    double r = 1.0;
    for (int i = 0; i < n; i++) {
      r *= 10.0;
    }
    return r;
  }
}
