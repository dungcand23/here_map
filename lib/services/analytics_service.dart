import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'storage_utils.dart';

class AnalyticsEvent {
  final String name;
  final DateTime ts;
  final Map<String, dynamic> props;

  const AnalyticsEvent({
    required this.name,
    required this.ts,
    required this.props,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'ts': ts.toIso8601String(),
        'props': props,
      };

  static AnalyticsEvent fromJson(Map<String, dynamic> json) {
    final props = (json['props'] is Map)
        ? Map<String, dynamic>.from(json['props'] as Map)
        : <String, dynamic>{};
    return AnalyticsEvent(
      name: (json['name'] ?? '').toString(),
      ts: DateTime.tryParse((json['ts'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0),
      props: props,
    );
  }
}

/// Analytics tối thiểu (Phase 1):
/// - Persist event vào SharedPreferences
/// - Có thể mở "Dashboard" ngay trong app để xem funnel + error
///
/// ✅ Sau này bạn có thể thay sink bằng Firebase/PostHog mà giữ nguyên schema.
class AnalyticsService {
  static const String _prefsKey = 'analytics_events_v1';
  static const int _maxEvents = 800;

  static final List<AnalyticsEvent> _events = <AnalyticsEvent>[];
  static bool _inited = false;

  /// Dùng để UI rebuild khi có event mới.
  static final ValueNotifier<int> rev = ValueNotifier<int>(0);

  static List<AnalyticsEvent> get events => List.unmodifiable(_events);

  static Future<void> init() async {
    if (_inited) return;
    _inited = true;

    final raw = await StorageUtils.getStringList(_prefsKey);
    for (final line in raw) {
      try {
        final obj = jsonDecode(line);
        if (obj is Map<String, dynamic>) {
          _events.add(AnalyticsEvent.fromJson(obj));
        }
      } catch (_) {
        // ignore corrupted line
      }
    }
  }

  static Future<void> track(String name, Map<String, dynamic> props) async {
    final e = AnalyticsEvent(
      name: name,
      ts: DateTime.now(),
      props: _trimProps(props),
    );

    _events.add(e);
    if (_events.length > _maxEvents) {
      _events.removeRange(0, _events.length - _maxEvents);
    }

    // Persist (best-effort)
    try {
      await StorageUtils.setStringList(
        _prefsKey,
        _events.map((x) => jsonEncode(x.toJson())).toList(growable: false),
      );
    } catch (_) {
      // ignore
    }

    // Debug log
    if (kDebugMode) {
      debugPrint('[Analytics] $name ${jsonEncode(e.props)}');
    }

    rev.value++;
  }

  static Future<void> clear() async {
    _events.clear();
    try {
      await StorageUtils.setStringList(_prefsKey, const []);
    } catch (_) {
      // ignore
    }
    rev.value++;
  }

  static String exportAsJsonLines({int limit = 500}) {
    final take = _events.length <= limit ? _events : _events.sublist(_events.length - limit);
    return take.map((e) => jsonEncode(e.toJson())).join('\n');
  }

  // ---------------- KPIs helpers ----------------

  static Map<String, dynamic> computeKpis({Duration window = const Duration(hours: 24)}) {
    final since = DateTime.now().subtract(window);
    final w = _events.where((e) => e.ts.isAfter(since)).toList(growable: false);

    int routeReq = 0, routeOk = 0, routeFail = 0;
    final latencies = <int>[];
    final status = <int, int>{};

    int sugReq = 0, sugOk = 0, sugSel = 0;

    for (final e in w) {
      switch (e.name) {
        case 'route_requested':
          routeReq++;
          break;
        case 'route_succeeded':
          routeOk++;
          final lm = e.props['latency_ms'];
          if (lm is num) latencies.add(lm.round());
          final st = e.props['status'];
          if (st is num) status[st.round()] = (status[st.round()] ?? 0) + 1;
          break;
        case 'route_failed':
          routeFail++;
          final st = e.props['status'];
          if (st is num) status[st.round()] = (status[st.round()] ?? 0) + 1;
          break;
        case 'autosuggest_requested':
          sugReq++;
          break;
        case 'autosuggest_received':
          sugOk++;
          break;
        case 'autosuggest_item_selected':
          sugSel++;
          break;
      }
    }

    latencies.sort();

    return {
      'window_hours': window.inHours,
      'route_requested': routeReq,
      'route_succeeded': routeOk,
      'route_failed': routeFail,
      'route_success_rate': routeReq == 0 ? 0.0 : (routeOk / routeReq),
      'route_latency_p50_ms': _percentile(latencies, 50),
      'route_latency_p95_ms': _percentile(latencies, 95),
      'status_counts': status,
      'autosuggest_requested': sugReq,
      'autosuggest_received': sugOk,
      'autosuggest_selected': sugSel,
      'search_to_select_rate': sugReq == 0 ? 0.0 : (sugSel / sugReq),
    };
  }

  static int _percentile(List<int> sorted, int p) {
    if (sorted.isEmpty) return 0;
    if (p <= 0) return sorted.first;
    if (p >= 100) return sorted.last;
    final idx = ((p / 100) * (sorted.length - 1)).round();
    return sorted[idx.clamp(0, sorted.length - 1)];
  }

  static Map<String, dynamic> _trimProps(Map<String, dynamic> props) {
    final out = <String, dynamic>{};
    for (final e in props.entries) {
      final k = e.key;
      final v = e.value;
      if (v == null) continue;
      if (v is String) {
        out[k] = v.length > 200 ? '${v.substring(0, 200)}…' : v;
      } else if (v is num || v is bool) {
        out[k] = v;
      } else if (v is Map) {
        out[k] = v; // assume small
      } else if (v is List) {
        out[k] = v.length > 20 ? v.sublist(0, 20) : v;
      } else {
        out[k] = v.toString();
      }
    }
    return out;
  }
}
