import 'package:flutter/material.dart';

import '../../models/saved_route_model.dart';
import '../../utils/format_utils.dart';

class SavedRoutesWidget extends StatelessWidget {
  final List<SavedRouteModel> routes;
  final void Function(SavedRouteModel) onTapRoute;

  /// Optional: cho phép xóa một tuyến trong lịch sử.
  final void Function(SavedRouteModel)? onDeleteRoute;

  /// Một số nơi đã có title bên ngoài (card), nên cho phép ẩn header.
  final bool showHeader;

  const SavedRoutesWidget({
    super.key,
    required this.routes,
    required this.onTapRoute,
    this.onDeleteRoute,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Text('Tuyến đã lưu', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
        ],
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: routes.length,
          itemBuilder: (context, index) {
            final r = routes[index];

            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${FormatUtils.formatDistanceKm(r.distanceKm)} • '
                    '${FormatUtils.formatDurationMin(r.durationMin)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${r.createdAt.day}/${r.createdAt.month}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (onDeleteRoute != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Xóa khỏi lịch sử',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => onDeleteRoute!.call(r),
                    ),
                  ],
                ],
              ),
              onTap: () => onTapRoute(r),
            );
          },
        ),
      ],
    );
  }
}
