import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_notifier.dart';
import '../../services/routing_service.dart';
import '../map/map_view.dart';
import '../widgets/bottom_sheet_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _mapPayload;
  bool _isRouting = false;
  double _distanceKm = 0;
  double _durationMin = 0;

  AppNotifier? _app;
  String? _lastSig;

  bool get _isDesktopLike =>
      kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  // ✅ Placeholder auth label (sau này bạn thay bằng auth thật theo Option C)
  String get _authLabel => 'Chưa đăng nhập';

  void _openSettings() {
    // TODO: mở screen/dialog settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mở Cài đặt (placeholder)')),
    );
  }

  void _googleLogin() {
    // TODO: triển khai Google login theo option C
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google Login (placeholder)')),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = context.read<AppNotifier>();
    if (_app != app) {
      _app?.removeListener(_onAppChanged);
      _app = app;
      _app!.addListener(_onAppChanged);
      _onAppChanged(); // ✅ lần đầu cũng set payload để map init
    }
  }

  @override
  void dispose() {
    _app?.removeListener(_onAppChanged);
    super.dispose();
  }

  void _onAppChanged() {
    final app = _app;
    if (app == null) return;

    final filled = app.state.stops
        .where((e) => e.name.trim().isNotEmpty && (e.lat != 0 || e.lng != 0))
        .toList();

    final sig = filled.map((e) => '${e.name}|${e.lat}|${e.lng}').join('||');
    if (sig == _lastSig) return;
    _lastSig = sig;

    // ✅ Khi danh sách điểm thay đổi: route cũ không còn hợp lệ.
    // Clear polyline + reset thống kê để tránh "dữ liệu ma".
    _isRouting = false;
    _distanceKm = 0;
    _durationMin = 0;

    final markers = <Map<String, dynamic>>[];
    for (int i = 0; i < filled.length; i++) {
      final st = filled[i];
      markers.add({
        'lat': st.lat,
        'lng': st.lng,
        'label': '${i + 1}',
        'title': st.name,
        'color': '#1A73E8',
      });
    }

    if (!mounted) return;
    setState(() {
      _mapPayload = {
        'clearMarkers': true,
        'markers': markers,
        'clearPolylines': true,
        if (filled.isNotEmpty) ...{
          'center': {'lat': filled.last.lat, 'lng': filled.last.lng},
          'zoom': 13.0,
        } else ...{
          // default center nếu chưa có điểm nào
          'center': {'lat': 10.776, 'lng': 106.700},
          'zoom': 12.0,
        }
      };
    });
  }

  void _clearRouteOnly() {
    if (!mounted) return;
    setState(() {
      _isRouting = false;
      _distanceKm = 0;
      _durationMin = 0;
      _mapPayload = {
        ...?_mapPayload,
        'clearPolylines': true,
      };
    });
  }

  void _resetPlan(AppNotifier app) {
    app.resetPlan();
    _clearRouteOnly();
  }

  Future<void> _buildRoute(AppNotifier app) async {
    final s = app.state;
    final stops = s.stops
        .where((e) => e.name.trim().isNotEmpty && (e.lat != 0 || e.lng != 0))
        .toList();
    final vehicle =
        s.currentVehicle ?? (s.vehicles.isNotEmpty ? s.vehicles.first : null);

    if (stops.length < 2 || vehicle == null) return;

    setState(() => _isRouting = true);

    final result = await RoutingService.buildRoute(
      stops: stops,
      vehicle: vehicle,
      truck: s.truckOption,
    );

    if (!mounted) return;

    if (result == null) {
      setState(() {
        _isRouting = false;
        _distanceKm = 0;
        _durationMin = 0;
        _mapPayload = {
          ...?_mapPayload,
          'clearPolylines': true,
        };
      });
      return;
    }

    final distanceKm = result.distanceKm;
    final durationMin = result.durationMin;
    final polyline = result.polyline; // list {lat,lng}

    final filled = stops
        .where((e) => e.name.trim().isNotEmpty && (e.lat != 0 || e.lng != 0))
        .toList();

    final markers = <Map<String, dynamic>>[];
    for (int i = 0; i < filled.length; i++) {
      final st = filled[i];
      markers.add({
        'lat': st.lat,
        'lng': st.lng,
        'label': '${i + 1}',
        'title': st.name,
        'color': '#1A73E8',
      });
    }

    setState(() {
      _isRouting = false;
      _distanceKm = distanceKm;
      _durationMin = durationMin;
      _mapPayload = {
        'clearMarkers': true,
        'markers': markers,
        'clearPolylines': true,
        'polyline': polyline,
        if (filled.isNotEmpty)
          'center': {'lat': filled.first.lat, 'lng': filled.first.lng},
        if (filled.isNotEmpty) 'zoom': 12.0,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppNotifier>();

    if (_isDesktopLike) {
      return Scaffold(
        backgroundColor: const Color(0xFFF3F5F8),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final leftWidth = (c.maxWidth * 0.34).clamp(360.0, 420.0);

              return Row(
                children: [
                  SizedBox(
                    width: leftWidth,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Material(
                        color: const Color(0xFFF3F5F8),
                        child: BottomSheetPanel(
                          scrollController: ScrollController(),
                          app: app,
                          isRouting: _isRouting,
                          distanceKm: _distanceKm,
                          durationMin: _durationMin,
                          onRequestRoute: () => _buildRoute(app),
                          onClearRoute: _clearRouteOnly,
                          onResetPlan: () => _resetPlan(app),
                          onLoadSavedRoute: (r) => app.loadSavedRoute(r),
                          onOpenSettings: _openSettings,
                          onGoogleLogin: _googleLogin,
                          authLabel: _authLabel,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                      ),
                      child: MapView(payload: _mapPayload),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: MapView(payload: _mapPayload)),
          DraggableScrollableSheet(
            initialChildSize: 0.30,
            minChildSize: 0.18,
            maxChildSize: 0.92,
            builder: (context, scroll) {
              return BottomSheetPanel(
                scrollController: scroll,
                app: app,
                isRouting: _isRouting,
                distanceKm: _distanceKm,
                durationMin: _durationMin,
                onRequestRoute: () => _buildRoute(app),
                onClearRoute: _clearRouteOnly,
                onResetPlan: () => _resetPlan(app),
                onLoadSavedRoute: (r) => app.loadSavedRoute(r),
                onOpenSettings: _openSettings,
                onGoogleLogin: _googleLogin,
                authLabel: _authLabel,
              );
            },
          ),
        ],
      ),
    );
  }
}
