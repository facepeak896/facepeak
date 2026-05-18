import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppState {
  static const _keyAccess = 'access_mode';
  static const _keyWelcomeDone = 'welcome_done';
  static const _keyToken = 'auth_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keySocialLive = 'social_live';

  static const _keySocialUserSnapshot = 'social_user_snapshot';
  static const _keySocialPslSnapshot = 'social_psl_snapshot';

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

  static Future<void> setRefreshToken(String token) async {
    await _secure.write(key: _keyRefreshToken, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return await _secure.read(key: _keyRefreshToken);
  }

  static Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await setToken(accessToken);
    await setRefreshToken(refreshToken);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearToken() async {
    await _secure.delete(key: _keyToken);
    await _secure.delete(key: _keyRefreshToken);
  }

  static Future<void> logout() async {
    await clearToken();
  }

  // ======================
  // SOCIAL
  // ======================

  static Future<void> setSocialLive(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySocialLive, value);
  }

  static Future<bool> isSocialLive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySocialLive) ?? false;
  }

  // ======================
  // 🔥 SNAPSHOT CACHE (FIXED)
  // ======================

  static Future<void> setSocialSnapshot({
    required Map<String, dynamic> user,
    required Map<String, dynamic> psl,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // ✅ SAFE USERNAME
      final rawUsername = user["username"]?.toString().trim() ?? "";
      final safeUsername =
          rawUsername.isNotEmpty ? rawUsername : "User";

      // ✅ SAFE DISPLAY NAME
      final rawDisplay = user["display_name"]?.toString().trim() ?? "";
      final safeDisplayName =
          rawDisplay.isNotEmpty ? rawDisplay : safeUsername;

      final safeUser = {
        ...user,
        "username": safeUsername,
        "display_name": safeDisplayName,
      };

      await prefs.setString(_keySocialUserSnapshot, jsonEncode(safeUser));
      await prefs.setString(_keySocialPslSnapshot, jsonEncode(psl));
    } catch (_) {
      // silent fail
    }
  }

  static Future<Map<String, dynamic>?> getSocialUserSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySocialUserSnapshot);

    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      final user = decoded is Map<String, dynamic>
          ? decoded
          : Map<String, dynamic>.from(decoded as Map);

      // ✅ FALLBACK AGAIN (double safety)
      final username = user["username"]?.toString().trim();
      if (username == null || username.isEmpty) {
        user["username"] = "User";
      }

      final display = user["display_name"]?.toString().trim();
      if (display == null || display.isEmpty) {
        user["display_name"] = user["username"];
      }

      return user;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getSocialPslSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySocialPslSnapshot);

    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return Map<String, dynamic>.from(decoded as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearSocialSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySocialUserSnapshot);
    await prefs.remove(_keySocialPslSnapshot);
  }
}