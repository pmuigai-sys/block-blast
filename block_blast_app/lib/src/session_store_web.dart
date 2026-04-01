import 'package:shared_preferences/shared_preferences.dart';

import 'session_store.dart';

class SharedPrefsSessionStore implements SessionStore {
  static const _key = 'active_session';

  @override
  Future<String?> loadSessionJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  @override
  Future<void> saveSessionJson(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json);
  }
}

SessionStore createSessionStore() => SharedPrefsSessionStore();
