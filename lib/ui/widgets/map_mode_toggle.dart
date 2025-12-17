import 'package:flutter/material.dart';

class MapModeToggle extends StatelessWidget {
  final String currentMode; // normal | satellite | terrain | transit
  final void Function(String) onChanged;

  const MapModeToggle({
    super.key,
    required this.currentMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final modes = {
      'normal': 'Thường',
      'satellite': 'Vệ tinh',
      'terrain': 'Địa hình',
      'transit': 'Giao thông công cộng',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chế độ bản đồ',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: modes.entries.map((e) {
            final selected = currentMode == e.key;
            return ChoiceChip(
              selected: selected,
              onSelected: (_) => onChanged(e.key),
              label: Text(e.value),
            );
          }).toList(),
        ),
      ],
    );
  }
}
