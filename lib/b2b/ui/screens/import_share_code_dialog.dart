import 'package:flutter/material.dart';

class ImportShareCodeDialog extends StatelessWidget {
  const ImportShareCodeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final c = TextEditingController();

    return AlertDialog(
      title: const Text('Import tuyến (share code)'),
      content: TextField(
        controller: c,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Dán share code hoặc share link (có ?code=...)',
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('Import')),
      ],
    );
  }
}
