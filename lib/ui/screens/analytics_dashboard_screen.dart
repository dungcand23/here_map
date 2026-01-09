import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/analytics_service.dart';

class AnalyticsDashboardScreen extends StatelessWidget {
  const AnalyticsDashboardScreen({super.key});

  Widget _kpiTile(String label, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Color(0x14000000))],
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Copy JSONL',
            icon: const Icon(Icons.copy_all),
            onPressed: () async {
              final text = AnalyticsService.exportAsJsonLines(limit: 500);
              await Clipboard.setData(ClipboardData(text: text));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã copy 500 events gần nhất (JSONL)')),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await AnalyticsService.clear();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xoá analytics local')),
                );
              }
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF3F5F8),
      body: ValueListenableBuilder<int>(
        valueListenable: AnalyticsService.rev,
        builder: (context, _, __) {
          final kpi24h = AnalyticsService.computeKpis(window: const Duration(hours: 24));
          final kpi7d = AnalyticsService.computeKpis(window: const Duration(days: 7));

          final ev = AnalyticsService.events;
          final recent = ev.length <= 80 ? ev.reversed.toList() : ev.sublist(ev.length - 80).reversed.toList();

          String pct(num v) => '${(v * 100).toStringAsFixed(1)}%';

          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              const Text('Last 24h', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              _kpiTile('Route requests', '${kpi24h['route_requested']}', icon: Icons.alt_route),
              const SizedBox(height: 8),
              _kpiTile('Route success rate', pct(kpi24h['route_success_rate'] ?? 0.0), icon: Icons.check_circle_outline),
              const SizedBox(height: 8),
              _kpiTile('Route latency p50', '${kpi24h['route_latency_p50_ms']} ms', icon: Icons.speed),
              const SizedBox(height: 8),
              _kpiTile('Route latency p95', '${kpi24h['route_latency_p95_ms']} ms', icon: Icons.speed_outlined),
              const SizedBox(height: 8),
              _kpiTile('Search → select', pct(kpi24h['search_to_select_rate'] ?? 0.0), icon: Icons.search),
              const SizedBox(height: 18),

              const Text('Last 7d', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              _kpiTile('Route requests', '${kpi7d['route_requested']}', icon: Icons.alt_route),
              const SizedBox(height: 8),
              _kpiTile('Route success rate', pct(kpi7d['route_success_rate'] ?? 0.0), icon: Icons.check_circle_outline),
              const SizedBox(height: 8),
              _kpiTile('Search → select', pct(kpi7d['search_to_select_rate'] ?? 0.0), icon: Icons.search),
              const SizedBox(height: 18),

              const Text('Recent events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(blurRadius: 10, color: Color(0x14000000))],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recent.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final e = recent[i];
                    return ListTile(
                      dense: true,
                      title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        '${e.ts.toLocal().toIso8601String()}\n${e.props}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
