import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppState {
  static const _keyAccess = 'access_mode';
  static const _keyWelcomeDone = 'welcome_done';
  static const _keyToken = 'auth_token';

  static const _secure = FlutterSecureStorage();

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
    await _secure.write(key: _keyToken, value: token);
  }

  static Future<String?> getToken() async {
    return await _secure.read(key: _keyToken);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearToken() async {
    await _secure.delete(key: _keyToken);
  }

  static Future<void> logout() async {
    await clearToken();
  }
}