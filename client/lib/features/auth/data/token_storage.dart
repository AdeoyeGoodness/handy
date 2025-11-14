import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/auth_state.dart';

class TokenStorage {
  TokenStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _authKey = 'auth_tokens';

  Future<void> save(AuthState state) async {
    final data = state.toJson();
    await _prefs.setString(_authKey, jsonEncode(data));
  }

  Future<void> clear() async {
    await _prefs.remove(_authKey);
  }

  AuthState? read() {
    final raw = _prefs.getString(_authKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AuthState.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}

