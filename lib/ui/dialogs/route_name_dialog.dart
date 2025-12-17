import 'package:flutter/material.dart';

/// Hiển thị dialog nhập tên tuyến đường,
/// trả về string (hoặc null nếu bấm Hủy).
class RouteNameDialog {
  static Future<String?> show(BuildContext context) async {
    final TextEditingController controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Đặt tên tuyến'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Nhập tên tuyến...',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) {
                  Navigator.of(ctx).pop(null);
                } else {
                  Navigator.of(ctx).pop(text);
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }
}
