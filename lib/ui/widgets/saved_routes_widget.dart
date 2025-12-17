import 'package:flutter/material.dart';
import '../../models/saved_route_model.dart';
import '../../utils/format_utils.dart';

class SavedRoutesWidget extends StatelessWidget {
  final List<SavedRouteModel> routes;
  final void Function(SavedRouteModel) onTapRoute;

  const SavedRoutesWidget({
    super.key,
    required this.routes,
    required this.onTapRoute,
  });

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tuyến đã lưu',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: routes.length,
          itemBuilder: (context, index) {
            final r = routes[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(r.name),
              subtitle: Text(
                '${FormatUtils.formatDistanceKm(r.distanceKm)} • '
                    '${FormatUtils.formatDurationMin(r.durationMin)}',
              ),
              trailing: Text(
                '${r.createdAt.day}/${r.createdAt.month}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              onTap: () => onTapRoute(r),
            );
          },
        ),
      ],
    );
  }
}
