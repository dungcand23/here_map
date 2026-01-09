import '../../app_config.dart';
import 'auth_repository.dart';
import 'route_repository.dart';
import 'session_store.dart';
import 'share_repository.dart';
import 'team_repository.dart';

import 'local/local_auth_repository.dart';
import 'local/local_route_repository.dart';
import 'local/local_session_store.dart';
import 'local/local_share_repository.dart';
import 'local/local_team_repository.dart';
import 'remote/wms_auth_repository.dart';
import 'remote/wms_route_repository.dart';
import 'remote/wms_share_repository.dart';
import 'remote/wms_team_repository.dart';

/// Dependency bundle cho B2B layer (Phase 2.5).
///
/// Tất cả UI/State chỉ phụ thuộc vào container này, nên sau này đổi backend (local -> WMS) gần như không phải sửa UI.
class B2BContainer {
  final AuthRepository auth;
  final SessionStore session;
  final TeamRepository teams;
  final RouteRepository routes;
  final ShareRepository share;

  const B2BContainer({
    required this.auth,
    required this.session,
    required this.teams,
    required this.routes,
    required this.share,
  });

  factory B2BContainer.create() {
    if (AppConfig.useWmsBackend) {
      final auth = WmsAuthRepository();
      return B2BContainer(
        auth: auth,
        session: const LocalSessionStore(),
        teams: WmsTeamRepository(auth: auth),
        routes: WmsRouteRepository(auth: auth),
        share: WmsShareRepository(auth: auth),
      );
    }

    return const B2BContainer(
      auth: LocalAuthRepository(),
      session: LocalSessionStore(),
      teams: LocalTeamRepository(),
      routes: LocalRouteRepository(),
      share: LocalShareRepository(),
    );
  }
}
