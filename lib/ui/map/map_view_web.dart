// lib/ui/map/map_view_web.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

import 'dart:ui_web' as ui_web;

@JS('updateMap')
external void _updateMap(JSString payload, JSString containerId);

@JS('resizeHereMap')
external void _resizeHereMap(JSString containerId);

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
  String? _lastSent;

  @override
  void initState() {
    super.initState();

    if (!_registered) {
      _registered = true;
      ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
        final div = web.HTMLDivElement()
          ..id = _containerId
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.backgroundColor = '#ffffff';
        return div;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPump();
      _sendPayload();
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
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendPayload());
    }
  }

  void _startPump() {
    int tick = 0;
    _pump = Timer.periodic(const Duration(milliseconds: 120), (t) {
      tick++;
      _resizeHereMap(_containerId.toJS);
      _sendPayload();
      if (tick > 20) t.cancel();
    });
  }

  void _sendPayload() {
    if (widget.payload == null) return;

    final json = jsonEncode(widget.payload);
    if (json == _lastSent) return;
    _lastSent = json;

    if (kDebugMode) {
      final m = widget.payload?['markers'];
      debugPrint('[Flutter] Gửi marker: ${m is List ? m.length : 0}');
    }

    _updateMap(json.toJS, _containerId.toJS);
  }

  @override
  Widget build(BuildContext context) {
    return const HtmlElementView(viewType: _viewType);
  }
}
