class FormatUtils {
  static String formatDistanceKm(double km) {
    if (km < 1) {
      final m = (km * 1000).round();
      return '$m m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  static String formatDurationMin(double minutes) {
    final total = minutes.round();
    final h = total ~/ 60;
    final m = total % 60;

    if (h <= 0) return '$m phút';
    if (m == 0) return '$h giờ';
    return '$h giờ $m phút';
  }

  static String formatCurrency(double vnd) {
    // đơn giản: làm tròn và thêm dấu chấm ngăn cách ngàn
    int value = vnd.round();
    final s = value.toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buf.write(s[i]);
      count++;
      if (count == 3 && i > 0) {
        buf.write('.');
        count = 0;
      }
    }
    final reversed = buf.toString().split('').reversed.join();
    return '$reversed đ';
  }
}
