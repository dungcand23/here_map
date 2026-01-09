import '../models/user_profile_model.dart';

/// Contract cho authentication.
///
/// Phase 2.5: UI/State chỉ phụ thuộc vào interface này.
/// - Local implementation: lưu user trong SharedPreferences (demo).
/// - WMS implementation (Phase 3/4): gọi API WMS trả JWT/access token.
abstract class AuthRepository {
  Future<UserProfileModel?> getCurrentUser();

  Future<UserProfileModel> signIn({required String email, required String displayName});

  Future<void> signOut();

  /// Token để gọi backend (JWT/bearer). Local backend có thể return null.
  Future<String?> getAccessToken();
}
