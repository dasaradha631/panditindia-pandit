import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  SessionStore._(this.scope);

  final String scope;

  static const String _genericToken = 'access_token';
  static const String _genericUser = 'pi_user';
  static const String _genericRole = 'role';

  String get _tokenKey => scope == 'pandit' ? 'pandit_access_token' : 'customer_access_token';
  String get _userKey => scope == 'pandit' ? 'pandit_pi_user' : 'customer_pi_user';
  String get _roleKey => scope == 'pandit' ? 'pandit_role' : 'customer_role';

  static SessionStore? _instance;
  static SessionStore get instance => _instance ??= SessionStore._('pandit');
  static SessionStore forScope(String scope) => SessionStore._(scope);

  SharedPreferences? _prefs;

  Future<SharedPreferences> _sp() async => _prefs ??= await SharedPreferences.getInstance();

  Future<void> saveSession({
    required String token,
    required String role,
    required Map<String, dynamic> user,
  }) async {
    final sp = await _sp();
    final raw = jsonEncode(user);
    await sp.setString(_tokenKey, token);
    await sp.setString(_userKey, raw);
    await sp.setString(_roleKey, role);
    await sp.setString(_genericToken, token);
    await sp.setString(_genericUser, raw);
    await sp.setString(_genericRole, role);
    await sp.setString('pi_last_activity', DateTime.now().toIso8601String());
  }

  Future<Map<String, dynamic>?> readUser() async {
    final sp = await _sp();
    final raw = sp.getString(_userKey) ?? sp.getString(_genericUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  Future<String?> readToken() async {
    final sp = await _sp();
    return sp.getString(_tokenKey) ?? sp.getString(_genericToken);
  }

  Future<String?> readRole() async {
    final sp = await _sp();
    return sp.getString(_roleKey) ?? sp.getString(_genericRole);
  }

  Future<void> touchActivity() async {
    final sp = await _sp();
    await sp.setString('pi_last_activity', DateTime.now().toIso8601String());
  }

  Future<DateTime?> lastActivity() async {
    final sp = await _sp();
    final raw = sp.getString('pi_last_activity');
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> clear() async {
    final sp = await _sp();
    final keys = sp.getKeys().where((k) {
      return k.startsWith('pi_') ||
          k.startsWith('customer_') ||
          k.startsWith('pandit_') ||
          k.contains('token') ||
          k.contains('user') ||
          k.contains('role');
    }).toList();
    for (final k in keys) {
      await sp.remove(k);
    }
  }

  Future<void> setValue(String key, String value) async {
    final sp = await _sp();
    await sp.setString(key, value);
  }

  Future<String?> getValue(String key) async {
    final sp = await _sp();
    return sp.getString(key);
  }

  Future<void> removeValue(String key) async {
    final sp = await _sp();
    await sp.remove(key);
  }
}
