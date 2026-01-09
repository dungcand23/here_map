import '../../services/local_auth_service.dart';
import '../auth_repository.dart';
import '../../models/user_profile_model.dart';

class LocalAuthRepository implements AuthRepository {
  const LocalAuthRepository();

  @override
  Future<UserProfileModel?> getCurrentUser() => LocalAuthService.getCurrentUser();

  @override
  Future<UserProfileModel> signIn({required String email, required String displayName}) {
    return LocalAuthService.signIn(email: email, displayName: displayName);
  }

  @override
  Future<void> signOut() => LocalAuthService.signOut();

  @override
  Future<String?> getAccessToken() async => null;
}
