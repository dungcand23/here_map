import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'map_view_web_stub.dart' if (dart.library.html) 'map_view_web.dart';
import 'map_view_native.dart';

class MapView extends StatelessWidget {
  final Map<String, dynamic>? payload;

  const MapView({
    super.key,
    this.payload,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return MapViewWeb(payload: payload);
    }

    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return MapViewNative(payload: payload);
    }

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
