import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'web_platform_view_registry_stub.dart'
if (dart.library.html) 'web_platform_view_registry.dart';

class MapViewWeb extends StatefulWidget {
  final Map<String, dynamic>? payload;
  const MapViewWeb({super.key, this.payload});

  @override
  State<MapViewWeb> createState() => _MapViewWebState();
}

class _MapViewWebState extends State<MapViewWeb> {
  static const String _viewType = 'here-map-view';
  static const String _containerId = 'here_map_container';
  static bool _registered = false;

  @override
  void initState() {
    super.initState();

    if (kIsWeb && !_registered) {
      _registered = true;

      registerViewFactory(_viewType, (int viewId) {
        final div = html.DivElement()
          ..id = _containerId
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.backgroundColor = 'transparent';
        return div;
      });
    }

    // ✅ Init map ngay lập tức (tránh màn xám chờ payload)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pingInit();
      _send();
    });
  }

  @override
  void didUpdateWidget(covariant MapViewWeb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.payload != oldWidget.payload) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send());
    }
  }

  void _pingInit() {
    // Gửi payload rỗng để JS init map ngay (không cần chờ stop/route)
    try {
      js.context.callMethod('updateMap', [
        jsonEncode({
          'clearMarkers': true,
          'clearPolylines': true,
          'markers': [],
          // tùy chọn: center mặc định HCM cho đẹp
          'center': {'lat': 10.776, 'lng': 106.700},
          'zoom': 12.0,
        }),
        _containerId,
      ]);
    } catch (_) {
      // ignore
    }
  }

  void _send() {
    final p = widget.payload;
    if (p == null) return;

    try {
      js.context.callMethod('updateMap', [jsonEncode(p), _containerId]);
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return const HtmlElementView(viewType: _viewType);
  }
}
