// lib/ui/map/map_view_web_stub.dart
// ✅ Stub để tránh lỗi build Windows/Linux/macOS vì map_view_web.dart dùng dart:html.
import 'package:flutter/material.dart';

class MapViewWeb extends StatelessWidget {
  final Map<String, dynamic>? payload;

  const MapViewWeb({super.key, this.payload});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: const Text(
        'MapViewWeb chỉ dùng cho Flutter Web.\n'
            'Hãy chạy bằng Chrome/Edge để test HERE map.',
        textAlign: TextAlign.center,
      ),
    );
  }
}
