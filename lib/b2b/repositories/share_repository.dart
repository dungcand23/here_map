import '../models/route_share_payload.dart';

/// Contract tạo / resolve share code.
///
/// - Local: embed payload -> base64url (hiện tại).
/// - WMS: tạo share token ở backend + expiry + revoke.
abstract class ShareRepository {
  /// Tạo share code từ payload.
  Future<String> createShareCode(RouteSharePayload payload);

  /// Resolve share code -> payload.
  Future<RouteSharePayload?> resolveShareCode(String code);

  /// Trích code từ input: code thô hoặc link có `?code=...`.
  String? extractCode(String input);
}
