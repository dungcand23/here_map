import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'map_view_web.dart';
import 'map_view_native.dart';

class MapView extends StatelessWidget {
  final Map<String, dynamic>? payload;

  const MapView({
    super.key,
    this.payload,
  });

  @override
  Widget build(BuildContext context) {
    // Web (Chrome/Edge) → dùng MapViewWeb (placeholder hoặc HERE web sau này)
    if (kIsWeb) {
      return MapViewWeb(payload: payload);
    }

    // Android / iOS → dùng WebView (HERE thật)
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return MapViewNative(payload: payload);
    }

    // Windows / macOS desktop → tạm thời placeholder, tránh crash
    return Container(
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: const Text(
        'Map chưa hỗ trợ WebView trên Windows desktop.\n'
            'Hãy chạy bằng Chrome để test HERE map.',
        textAlign: TextAlign.center,
      ),
    );
  }
}
