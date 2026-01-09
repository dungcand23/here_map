import '../../models/route_share_payload.dart';
import '../../utils/share_utils.dart' as core;
import '../share_repository.dart';

class LocalShareRepository implements ShareRepository {
  const LocalShareRepository();

  @override
  Future<String> createShareCode(RouteSharePayload payload) async {
    return core.ShareUtils.encodeRouteSharePayload(payload);
  }

  @override
  Future<RouteSharePayload?> resolveShareCode(String code) async {
    return core.ShareUtils.decodeRouteSharePayload(code);
  }

  @override
  String? extractCode(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;

    // Nếu là link: lấy query param `code`
    if (text.contains('://') && text.contains('?')) {
      try {
        final uri = Uri.parse(text);
        final c = uri.queryParameters['code'];
        if (c != null && c.trim().isNotEmpty) return c.trim();
      } catch (_) {
        // ignore
      }
    }

    // fallback: tìm query param thủ công
    final idx = text.indexOf('code=');
    if (idx >= 0) {
      final rest = text.substring(idx + 5);
      final endIdx = rest.indexOf('&');
      final c = (endIdx >= 0 ? rest.substring(0, endIdx) : rest).trim();
      if (c.isNotEmpty) return c;
    }

    // assume raw code
    return text;
  }
}
