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

  @override
  void initState() {
    super.initState();

    if (kIsWeb && !_registered) {
      _registered = true;

      // ✅ Register platform view for Flutter Web (works on recent Flutter)
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

    WidgetsBinding.instance.addPostFrameCallback((_) => _startPump());
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
    _pump = Timer.periodic(const Duration(milliseconds: 120), (t) {
      count++;
      _pingInit();
      _sendPayload();
      _resize();

      if (count >= 25) {
        t.cancel();
        _pump = null;
      }
    });
  }

  void _pingInit() {
    try {
      js.context.callMethod('updateMap', [
        jsonEncode({
          'markers': const [],
          'clearMarkers': false,
          'clearPolylines': false,
        }),
        _containerId,
      ]);
    } catch (_) {}
  }

  void _sendPayload() {
    if (widget.payload == null) return;
    try {
      js.context.callMethod('updateMap', [jsonEncode(widget.payload), _containerId]);
    } catch (_) {}
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
