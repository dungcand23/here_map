// lib/ui/map/map_view_web.dart
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Flutter web registry lives in different places depending on Flutter version.
// - Newer: dart:ui_web has platformViewRegistry
// - Older: dart:ui has platformViewRegistry (but not always)
// We import ui_web first. If your Flutter doesn't have ui_web, comment that line
// and use the ui fallback below.
import 'dart:ui_web' as ui_web;
// ignore: unused_import
import 'dart:ui' as ui;

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

  Timer? _pump;
  String? _lastSentPayload; // ✅ tránh gửi lặp gây clear/nhấp nháy + spam log

  @override
  void initState() {
    super.initState();

    if (kIsWeb && !_registered) {
      _registered = true;

      ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
        final div = html.DivElement()
          ..id = _containerId
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.position = 'relative'
          ..style.overflow = 'hidden'
          ..style.backgroundColor = '#ffffff';
        return div;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPump();
      _resize();      // ✅ init map sớm
      _sendPayload(); // ✅ apply payload ngay nếu có
    });
  }

  @override
  void dispose() {
    _pump?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MapViewWeb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.payload != oldWidget.payload) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendPayload();
        _resize();
      });
    }
  }

  void _startPump() {
    _pump?.cancel();
    int count = 0;

    // ✅ pump ngắn để cover mount/shadowRoot chậm
    _pump = Timer.periodic(const Duration(milliseconds: 120), (t) {
      count++;
      _resize();
      _sendPayload();

      if (count >= 25) {
        t.cancel();
        _pump = null;
      }
    });
  }

  void _sendPayload() {
    final payload = widget.payload;
    if (payload == null) return;

    final payloadStr = jsonEncode(payload);
    if (payloadStr == _lastSentPayload) return;
    _lastSentPayload = payloadStr;

    // ✅ LOG từng bước
    final markers = payload['markers'];
    final polyline = payload['polyline'];
    final mLen = markers is List ? markers.length : 0;
    final pLen = polyline is List ? polyline.length : 0;

    if (kDebugMode) {
      if (mLen > 0) debugPrint('[Flutter] Gửi marker: $mLen marker(s)');
      if (pLen > 1) debugPrint('[Flutter] Gửi polyline: $pLen point(s)');
      if (mLen == 0 && pLen <= 1) debugPrint('[Flutter] Gửi payload (no markers/polyline)');
    }

    try {
      js.context.callMethod('updateMap', [payloadStr, _containerId]);
    } catch (e) {
      if (kDebugMode) debugPrint('[Flutter] updateMap error: $e');
    }
  }

  void _resize() {
    try {
      js.context.callMethod('resizeHereMap', [_containerId]);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return const HtmlElementView(viewType: _viewType);
  }
}
