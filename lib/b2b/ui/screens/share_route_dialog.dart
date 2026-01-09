import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app_config.dart';

class ShareRouteDialog extends StatelessWidget {
  const ShareRouteDialog({
    super.key,
    required this.shareCode,
    required this.routeName,
  });

  final String shareCode;
  final String routeName;

  String get shareLink => '${AppConfig.safeBaseUrl}/?code=$shareCode';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chia sẻ tuyến'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(routeName, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Center(
              child: QrImageView(
                data: shareLink,
                size: 220,
              ),
            ),
            const SizedBox(height: 12),
            Text('Share link (web):', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            SelectableText(shareLink),
            const SizedBox(height: 12),
            Text('Share code (backup):', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            SelectableText(shareCode),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: shareCode));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã copy share code')));
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy code'),
        ),
        FilledButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: shareLink));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã copy share link')));
          },
          icon: const Icon(Icons.link),
          label: const Text('Copy link'),
        ),
      ],
    );
  }
}
