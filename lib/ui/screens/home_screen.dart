import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/stop_model.dart';
import '../../state/app_notifier.dart';
import '../../b2b/b2b_notifier.dart';
import '../../b2b/ui/screens/team_workspace_screen.dart';
import '../../b2b/repositories/b2b_container.dart';
import '../../b2b/utils/share_utils.dart';
import '../../services/routing_service.dart';
import '../../services/waypoints_sequence_service.dart';
import '../../services/api_exceptions.dart';
import '../map/map_view.dart';
import '../widgets/bottom_sheet_panel.dart';
import 'analytics_dashboard_screen.dart';

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
  bool _skipResetOnce = false;

  bool get _isDesktopLike =>
      kIsWeb ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS;

  void _openTeamWorkspace() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TeamWorkspaceScreen()),
    );
  }

  void _openSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mở Cài đặt (placeholder)')),
    );
  }

  @override
  void initState() {
    super.initState();

    // ✅ Web: support share link .../?code=xxx
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final code = Uri.base.queryParameters['code'];
        if (code == null || code.trim().isEmpty) return;

        final shareRepo = context.read<B2BContainer>().share;
        shareRepo.resolveShareCode(code.trim()).then((payload) {
          if (payload == null) return;

          final app = context.read<AppNotifier>();
          final saved = ShareUtils.toSavedRoute(payload);
          app.setSuggestedVehicleMode(payload.vehicleMode);
          app.updateTruck(payload.truckOption);
          app.setTraffic(payload.trafficEnabled);
          app.loadSavedRoute(saved);
          app.saveRoute(saved);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã import tuyến từ share link')),
            );
          }
        });
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = context.read<AppNotifier>();
    if (_app != app) {
      _app?.removeListener(_onAppChanged);
      _app = app;
      _app!.addListener(_onAppChanged);
      _onAppChanged();
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
    if (sig == _lastSig) {
      _skipResetOnce = false;
      return;
    }
    _lastSig = sig;

    if (_skipResetOnce) {
      _skipResetOnce = false;
    } else {
      _isRouting = false;
    }
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

    // ✅ >=3 điểm: tối ưu thứ tự (giữ START, end-free) rồi mới gọi Routing v8.
    var usedStops = List<StopModel>.from(stops);
    if (usedStops.length >= 3) {
      try {
        final optimized = await WaypointsSequenceService.optimizeStops(
          stops: usedStops,
          vehicle: vehicle,
          truck: s.truckOption,
          trafficEnabled: s.trafficEnabled,
          improveFor: 'time',
        );

        if (optimized.length >= 2) {
          _skipResetOnce = true;
          app.applyStops(optimized);
          usedStops = optimized;
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tối ưu tuyến thất bại, sẽ định tuyến theo thứ tự hiện tại.'),
            ),
          );
        }
      }
    }

    RoutingResult? result;
    try {
      result = await RoutingService.buildRoute(
        stops: usedStops,
        vehicle: vehicle,
        truck: s.truckOption,
        trafficEnabled: s.trafficEnabled,
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
      result = null;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tạo tuyến lúc này')),
        );
      }
      result = null;
    }

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
    final polylinesEncoded = result.polylinesEncoded;

    final filled = usedStops
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
        'polylinesEncoded': polylinesEncoded, // 👈 gửi encoded sang JS để decode
        if (filled.isNotEmpty)
          'center': {'lat': filled.first.lat, 'lng': filled.first.lng},
        if (filled.isNotEmpty) 'zoom': 12.0,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppNotifier>();
    final b2b = context.watch<B2BNotifier>();
    final canSaveTeamRoute = b2b.isSignedIn && b2b.hasTeam && b2b.canEditRoutes;

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
                          onOpenTeamWorkspace: _openTeamWorkspace,
                          onOpenAnalytics: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AnalyticsDashboardScreen()),
                            );
                          },
                          authLabel: b2b.authLabel(),
                          canSaveTeamRoute: canSaveTeamRoute,
                          onSaveTeamRoute: (routeName) async {
                            final s = app.state;
                            final ok = await b2b.saveCurrentRouteToTeam(
                              name: routeName,
                              distanceKm: _distanceKm,
                              durationMin: _durationMin,
                              stops: List.of(s.stops.where((e) => e.name.trim().isNotEmpty)),
                              vehicle: s.currentVehicle,
                              truck: s.truckOption,
                              trafficEnabled: s.trafficEnabled,
                              mapMode: s.mapMode,
                            );
                            if (ok == null && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Không thể lưu team (chưa login/team hoặc thiếu quyền)')),
                              );
                            } else if (ok != null && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã lưu tuyến vào team')),
                              );
                            }
                          },
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
                onOpenTeamWorkspace: _openTeamWorkspace,
                onOpenAnalytics: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AnalyticsDashboardScreen()),
                  );
                },
                authLabel: b2b.authLabel(),
                canSaveTeamRoute: canSaveTeamRoute,
                onSaveTeamRoute: (routeName) async {
                  final s = app.state;
                  final ok = await b2b.saveCurrentRouteToTeam(
                    name: routeName,
                    distanceKm: _distanceKm,
                    durationMin: _durationMin,
                    stops: List.of(s.stops.where((e) => e.name.trim().isNotEmpty)),
                    vehicle: s.currentVehicle,
                    truck: s.truckOption,
                    trafficEnabled: s.trafficEnabled,
                    mapMode: s.mapMode,
                  );
                  if (ok == null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Không thể lưu team (chưa login/team hoặc thiếu quyền)')),
                    );
                  } else if (ok != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã lưu tuyến vào team')),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
