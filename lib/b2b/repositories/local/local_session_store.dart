import 'package:shared_preferences/shared_preferences.dart';

import '../session_store.dart';

class LocalSessionStore implements SessionStore {
  const LocalSessionStore();

  static const String _kCurrentTeamId = 'b2b_current_team_id';

  @override
  Future<String?> getCurrentTeamId() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_kCurrentTeamId);
    if (v == null || v.trim().isEmpty) return null;
    return v;
  }

  @override
  Future<void> setCurrentTeamId(String? teamId) async {
    final prefs = await SharedPreferences.getInstance();
    final v = teamId?.trim() ?? '';
    if (v.isEmpty) {
      await prefs.remove(_kCurrentTeamId);
    } else {
      await prefs.setString(_kCurrentTeamId, v);
    }
  }
}
