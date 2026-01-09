import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app_config.dart';

class MapViewNative extends StatefulWidget {
  final Map<String, dynamic>? payload;

  const MapViewNative({
    super.key,
    this.payload,
  });

  @override
  State<MapViewNative> createState() => _MapViewNativeState();
}

class _MapViewNativeState extends State<MapViewNative> {
  late final WebViewController _controller;
  bool _pageLoaded = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _pageLoaded = true;
            // Inject HERE key (nếu có)
            if (AppConfig.hereApiKey.isNotEmpty) {
              _controller.runJavaScript(
                'try { window.setHereApiKey(${jsonEncode(AppConfig.hereApiKey)}); } catch(e) {}',
              );
            }
            _sendUpdate();
          },
        ),
      )
      ..loadFlutterAsset('assets/map_here.html');
  }

  void _sendUpdate() {
    if (!_pageLoaded) return;
    if (widget.payload == null) return;

    // ✅ window.updateMap(payloadJsonString)
    // JS trong assets/map_here.html đang JSON.parse(...) nên ta phải truyền *string*.
    final payloadStr = jsonEncode(widget.payload);
    _controller.runJavaScript('window.updateMap(${jsonEncode(payloadStr)});');
  }

  @override
  void didUpdateWidget(covariant MapViewNative oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.payload != oldWidget.payload) {
      _sendUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(
      controller: _controller,
    );
  }
}
