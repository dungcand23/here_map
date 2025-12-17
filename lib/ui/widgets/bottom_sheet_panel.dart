import 'package:flutter/material.dart';
import '../../models/saved_route_model.dart';
import '../../state/app_notifier.dart';
import '../../utils/format_utils.dart';
import 'stop_list_widget.dart';
import 'saved_routes_widget.dart';

class BottomSheetPanel extends StatelessWidget {
  const BottomSheetPanel({
    super.key,
    required this.scrollController,
    required this.app,
    required this.isRouting,
    required this.distanceKm,
    required this.durationMin,
    required this.onRequestRoute,
    required this.onOpenSettings,
    required this.onGoogleLogin,
    required this.authLabel,
  });

  final ScrollController scrollController;
  final AppNotifier app;
  final bool isRouting;
  final double distanceKm;
  final double durationMin;
  final VoidCallback onRequestRoute;

  // ✅ footer actions
  final VoidCallback onOpenSettings;
  final VoidCallback onGoogleLogin;
  final String authLabel;

  bool get _hasRoute => distanceKm > 0 && durationMin > 0;

  Future<String?> _askRouteName(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Lưu tuyến'),
          content: TextField(
            controller: c,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Nhập tên tuyến…'),
            onSubmitted: (_) => Navigator.of(ctx).pop(c.text),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Hủy')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(c.text), child: const Text('Lưu')),
          ],
        );
      },
    );
  }

  Widget _card(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [BoxShadow(blurRadius: 10, color: Color(0x14000000))],
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final s = app.state;
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(14, 14, 22, 14),
            children: [
              _card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Điểm đi / đến', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    StopListWidget(
                      stops: s.stops,
                      onUpdateStop: (i, stop) => app.updateStop(i, stop),
                      onClearStop: (i) => app.clearStop(i),
                      onRemove: (i) => app.removeStop(i),
                      onReorder: (a, b) => app.reorderStops(a, b),
                    ),
                  ],
                ),
              ),
              _card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('Tuyến đường', style: theme.textTheme.titleMedium)),
                        FilledButton(
                          onPressed: isRouting ? null : onRequestRoute,
                          child: isRouting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Route'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_hasRoute) ...[
                      Text('Quãng đường: ${FormatUtils.formatDistanceKm(distanceKm)}'),
                      Text('Thời gian: ${FormatUtils.formatDurationMin(durationMin)}'),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final name = await _askRouteName(context);
                          final trimmed = (name ?? '').trim();
                          if (trimmed.isEmpty) return;
                          final now = DateTime.now();
                          app.saveRoute(
                            SavedRouteModel(
                              id: now.millisecondsSinceEpoch.toString(),
                              createdAt: now,
                              name: trimmed,
                              distanceKm: distanceKm,
                              durationMin: durationMin,
                              stops: List.of(s.stops.where((e) => e.name.trim().isNotEmpty)),
                              vehicle: s.currentVehicle, // bạn có thể bỏ hẳn sau
                              truckOption: s.truckOption,
                              mapMode: s.mapMode,
                              trafficEnabled: s.trafficEnabled,
                            ),
                          );
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Lưu tuyến'),
                      ),
                    ] else
                      const Text('Nhập điểm đi/đến rồi nhấn Route để xem tuyến.'),
                  ],
                ),
              ),
              _card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tuyến đã lưu', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (s.savedRoutes.isEmpty)
                      const Text('Chưa có tuyến nào.')
                    else
                      SavedRoutesWidget(routes: s.savedRoutes, onTapRoute: (_) {}),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ✅ Footer cố định dưới đáy
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: const [BoxShadow(blurRadius: 12, color: Color(0x1A000000))],
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Cài đặt',
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings),
              ),
              Expanded(
                child: Text(
                  authLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                ),
              ),
              FilledButton.icon(
                onPressed: onGoogleLogin,
                icon: const Icon(Icons.login),
                label: const Text('Google'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
