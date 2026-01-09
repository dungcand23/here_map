import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/saved_route_model.dart';
import '../../b2b/repositories/b2b_container.dart';
import '../../b2b/utils/share_utils.dart';
import '../../b2b/ui/screens/share_route_dialog.dart';
import '../../b2b/ui/screens/import_share_code_dialog.dart';
import '../../state/app_notifier.dart';
import '../../utils/format_utils.dart';
import 'stop_list_widget.dart';
import 'saved_routes_widget.dart';
import 'traffic_toggle.dart';
import 'truck_option_form.dart';

class BottomSheetPanel extends StatelessWidget {
  const BottomSheetPanel({
    super.key,
    required this.scrollController,
    required this.app,
    required this.isRouting,
    required this.distanceKm,
    required this.durationMin,
    required this.onRequestRoute,
    required this.onClearRoute,
    required this.onResetPlan,
    required this.onLoadSavedRoute,
    required this.onOpenSettings,
    required this.onOpenTeamWorkspace,
    required this.onOpenAnalytics,
    required this.authLabel,
    required this.canSaveTeamRoute,
    required this.onSaveTeamRoute,
  });

  final ScrollController scrollController;
  final AppNotifier app;
  final bool isRouting;
  final double distanceKm;
  final double durationMin;
  final VoidCallback onRequestRoute;
  final VoidCallback onClearRoute;
  final VoidCallback onResetPlan;
  final void Function(SavedRouteModel) onLoadSavedRoute;

  final VoidCallback onOpenSettings;
  final VoidCallback onOpenTeamWorkspace;
  final VoidCallback onOpenAnalytics;
  final String authLabel;

  final bool canSaveTeamRoute;
  final Future<void> Function(String routeName) onSaveTeamRoute;

  bool get _hasRoute => distanceKm > 0 && durationMin > 0;

  bool _isFilledStop(dynamic s) {
    try {
      return s.name.trim().isNotEmpty && (s.lat != 0 || s.lng != 0);
    } catch (_) {
      return false;
    }
  }

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
            decoration: const InputDecoration(
              hintText: 'VD: Giao hàng sáng 08/01',
            ),
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

  Widget _sectionCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(14),
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E8EE)),
        boxShadow: const [
          BoxShadow(blurRadius: 10, color: Color(0x08000000), offset: Offset(0, 6)),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = app.state;
    final theme = Theme.of(context);

    final filledStops = s.stops.where(_isFilledStop).toList();
    final canRoute = filledStops.length >= 2;
    final isOptimize = filledStops.length >= 3;
    final primaryLabel = isOptimize ? 'Tối ưu tuyến' : 'Định tuyến';
    final primaryIcon = isOptimize ? Icons.auto_graph_rounded : Icons.route_rounded;

    final selectedMode = s.currentVehicle?.mode ?? 'car';
    final isTruck = selectedMode == 'truck';

    return Container(
      color: const Color(0xFFF3F5F8),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(14, 14, 22, 14),
              children: [
                // ===== Stops =====
                _sectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(
                        icon: Icons.place_outlined,
                        title: 'Điểm đi / điểm dừng',
                        subtitle: 'Chọn địa điểm từ gợi ý. Có thể kéo để đổi thứ tự (từ điểm 3).',
                      ),
                      const SizedBox(height: 12),
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

                // ===== Route result + primary action =====
                _sectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Tuyến đường',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Tooltip(
                            message: 'Tuyến mới (reset)',
                            child: IconButton(
                              onPressed: onResetPlan,
                              icon: const Icon(Icons.restart_alt_rounded),
                            ),
                          ),
                          Tooltip(
                            message: 'Xóa tuyến (polyline)',
                            child: IconButton(
                              onPressed: onClearRoute,
                              icon: const Icon(Icons.layers_clear_rounded),
                            ),
                          ),
                        ],
                      ),

                      if (_hasRoute) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricTile(
                                label: 'Thời gian',
                                value: FormatUtils.formatDurationMin(durationMin),
                                icon: Icons.schedule_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MetricTile(
                                label: 'Quãng đường',
                                value: FormatUtils.formatDistanceKm(distanceKm),
                                icon: Icons.straighten_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        const SizedBox(height: 6),
                        Text(
                          canRoute
                              ? (isOptimize
                              ? 'Giữ điểm A cố định, hệ thống sắp xếp các điểm còn lại (điểm cuối tự chọn).'
                              : 'Nhập đủ 2 điểm rồi bấm “Định tuyến”.')
                              : 'Hãy nhập tối thiểu 2 điểm để bắt đầu.',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 10),
                      ],

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: (!canRoute || isRouting) ? null : onRequestRoute,
                          icon: isRouting
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : Icon(primaryIcon),
                          label: Text(isRouting ? 'Đang xử lý…' : primaryLabel),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),

                      if (_hasRoute) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
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
                                    vehicle: s.currentVehicle,
                                    truckOption: s.truckOption,
                                    mapMode: s.mapMode,
                                    trafficEnabled: s.trafficEnabled,
                                  ),
                                );
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đã lưu tuyến local')),
                                );
                              },
                              icon: const Icon(Icons.save_rounded),
                              label: const Text('Lưu local'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final name = await _askRouteName(context);
                                final trimmed = (name ?? '').trim();
                                if (trimmed.isEmpty) return;

                                final payload = ShareUtils.fromCurrentRoute(
                                  name: trimmed,
                                  distanceKm: distanceKm,
                                  durationMin: durationMin,
                                  stops: List.of(s.stops.where((e) => e.name.trim().isNotEmpty)),
                                  vehicle: s.currentVehicle,
                                  truck: s.truckOption,
                                  trafficEnabled: s.trafficEnabled,
                                  mapMode: s.mapMode,
                                );
                                final shareRepo = context.read<B2BContainer>().share;
                                final code = await shareRepo.createShareCode(payload);

                                // ignore: use_build_context_synchronously
                                showDialog(
                                  context: context,
                                  builder: (_) => ShareRouteDialog(shareCode: code, routeName: trimmed),
                                );
                              },
                              icon: const Icon(Icons.qr_code_2_rounded),
                              label: const Text('Share'),
                            ),
                            if (canSaveTeamRoute)
                              FilledButton.icon(
                                onPressed: () async {
                                  final name = await _askRouteName(context);
                                  final trimmed = (name ?? '').trim();
                                  if (trimmed.isEmpty) return;
                                  await onSaveTeamRoute(trimmed);
                                },
                                icon: const Icon(Icons.group_rounded),
                                label: const Text('Lưu team'),
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // ===== Options =====
                _sectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(
                        icon: Icons.tune_rounded,
                        title: 'Tùy chọn',
                        subtitle: 'Chọn phương tiện và điều kiện giao thông.',
                      ),
                      const SizedBox(height: 12),

                      // Vehicle chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: s.vehicles.map((v) {
                          final selected = (s.currentVehicle?.mode == v.mode);
                          return ChoiceChip(
                            selected: selected,
                            label: Text(v.name),
                            avatar: Icon(v.icon, size: 18),
                            onSelected: (_) {
                              app.setSuggestedVehicleMode(v.mode);
                              onClearRoute(); // đổi xe -> clear tuyến cũ
                            },
                            labelStyle: TextStyle(
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 10),
                      TrafficToggle(
                        enabled: s.trafficEnabled,
                        onChanged: (v) {
                          app.setTraffic(v);
                          onClearRoute(); // đổi traffic -> clear tuyến cũ
                        },
                      ),

                      if (isTruck) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F7F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE6E8EE)),
                          ),
                          child: TruckOptionForm(
                            truckOption: s.truckOption,
                            onChanged: (t) {
                              app.updateTruck(t);
                              onClearRoute();
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ===== Saved routes =====
                _sectionCard(
                  padding: EdgeInsets.zero,
                  child: Theme(
                    data: theme.copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
                      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      title: Text(
                        'Tuyến đã lưu (${s.savedRoutes.length})',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'Lưu local để dùng lại hoặc import bằng share code.',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () async {
                              final raw = await showDialog<String?>(
                                context: context,
                                builder: (_) => const ImportShareCodeDialog(),
                              );
                              final input = (raw ?? '').trim();
                              if (input.isEmpty) return;

                              final shareRepo = context.read<B2BContainer>().share;
                              final code = shareRepo.extractCode(input);
                              final payload = code == null ? null : await shareRepo.resolveShareCode(code);
                              if (payload == null) {
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Share code không hợp lệ')),
                                );
                                return;
                              }

                              final saved = ShareUtils.toSavedRoute(payload);
                              app.setSuggestedVehicleMode(payload.vehicleMode);
                              app.updateTruck(payload.truckOption);
                              app.setTraffic(payload.trafficEnabled);
                              app.loadSavedRoute(saved);
                              app.saveRoute(saved);

                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã import tuyến và lưu local')),
                              );
                            },
                            icon: const Icon(Icons.download_rounded),
                            label: const Text('Import share code'),
                          ),
                        ),
                        if (s.savedRoutes.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text('Chưa có tuyến nào.'),
                          )
                        else
                          SavedRoutesWidget(
                            routes: s.savedRoutes,
                            onTapRoute: onLoadSavedRoute,
                            onDeleteRoute: (r) => app.deleteSavedRoute(r.id),
                            showHeader: false,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ===== Footer =====
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: const Color(0xFFE6E8EE))),
              boxShadow: const [BoxShadow(blurRadius: 12, color: Color(0x12000000))],
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Cài đặt',
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.settings_rounded),
                ),
                IconButton(
                  tooltip: 'Analytics',
                  onPressed: onOpenAnalytics,
                  icon: const Icon(Icons.insights_rounded),
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
                  onPressed: onOpenTeamWorkspace,
                  icon: const Icon(Icons.people_alt_rounded),
                  label: const Text('Team'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6E8EE)),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF1A73E8)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EE)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1A73E8)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
