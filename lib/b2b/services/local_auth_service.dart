import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile_model.dart';

class LocalAuthService {
  static const _kCurrentUser = 'b2b_current_user';

  static String _userIdFromEmail(String email) {
    final bytes = Uint8List.fromList(utf8.encode(email.trim().toLowerCase()));
    return sha1.convert(bytes).toString();
  }

  static Future<UserProfileModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_kCurrentUser);
    if (s == null || s.trim().isEmpty) return null;
    try {
      final json = jsonDecode(s);
      if (json is! Map) return null;
      return UserProfileModel.fromJson(Map<String, dynamic>.from(json as Map));
    } catch (_) {
      return null;
    }
  }

  static Future<UserProfileModel> signIn({required String email, required String displayName}) async {
    final prefs = await SharedPreferences.getInstance();
    final user = UserProfileModel(
      id: _userIdFromEmail(email),
      email: email.trim(),
      displayName: displayName.trim().isNotEmpty ? displayName.trim() : email.trim(),
      createdAt: DateTime.now(),
    );
    await prefs.setString(_kCurrentUser, jsonEncode(user.toJson()));
    return user;
  }

  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCurrentUser);
  }
}
