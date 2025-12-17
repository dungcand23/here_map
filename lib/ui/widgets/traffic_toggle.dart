import 'package:flutter/material.dart';

class TrafficToggle extends StatelessWidget {
  final bool enabled;
  final void Function(bool) onChanged;

  const TrafficToggle({
    super.key,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.traffic),
        const SizedBox(width: 8),
        const Text('Traffic'),
        const Spacer(),
        Switch(
          value: enabled,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
