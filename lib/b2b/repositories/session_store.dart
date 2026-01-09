/// Store các trạng thái "session" đơn giản của B2B (VD: currentTeamId).
///
/// Tách riêng để sau này chuyển sang secure storage / backend sync mà không phải sửa UI.
abstract class SessionStore {
  Future<String?> getCurrentTeamId();

  Future<void> setCurrentTeamId(String? teamId);
}
