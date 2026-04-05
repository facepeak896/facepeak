import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  static const _keyAccess = 'access_mode';
  static const _keyWelcomeDone = 'welcome_done';
  static const _keyToken = 'auth_token';

  // ======================
  // ACCESS
  // ======================

  static Future<void> setAccessMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccess, mode);
    await prefs.setBool(_keyWelcomeDone, true);
  }

  static Future<String?> getAccessMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccess);
  }

  static Future<bool> isWelcomeDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyWelcomeDone) ?? false;
  }

  // ======================
  // AUTH
  // ======================

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
  }

  static Future<void> logout() async {
    await clearToken();
  }
}