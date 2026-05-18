import 'package:flutter/foundation.dart';
import 'package:frontend/features/analysis/screens/app_state.dart';
import 'package:frontend/features/social_free/auth_api.dart';
import 'google_auth_service.dart';

class SocialAuthGuard {
  static Future<String?>? _inFlight;
  static Future<String?>? _refreshInFlight;

  static Future<String?> ensureBackendToken() {
    if (_inFlight != null) return _inFlight!;

    _inFlight = _ensureBackendTokenInternal();

    return _inFlight!.whenComplete(() {
      _inFlight = null;
    });
  }

  static Future<String?> _refreshAccessToken() {
    if (_refreshInFlight != null) return _refreshInFlight!;

    _refreshInFlight = _refreshAccessTokenInternal();

    return _refreshInFlight!.whenComplete(() {
      _refreshInFlight = null;
    });
  }

  static Future<String?> _refreshAccessTokenInternal() async {
    final refreshToken = await AppState.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      debugPrint("❌❌❌ AUTH_GUARD no refresh token");
      await AppState.logout();
      return null;
    }

    try {
      final refreshed = await AuthApi.refresh(
        refreshToken: refreshToken,
      );

      final newAccess = refreshed["access_token"]?.toString();
      final newRefresh = refreshed["refresh_token"]?.toString();

      if (newAccess == null ||
          newAccess.isEmpty ||
          newRefresh == null ||
          newRefresh.isEmpty) {
        debugPrint("❌❌❌ AUTH_GUARD refresh returned empty tokens");

        await AppState.logout();

        return null;
      }

      await AppState.setTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );

      return newAccess;
    } catch (e) {
      debugPrint("❌❌❌ AUTH_GUARD refresh FAILED = $e");

      await AppState.logout();

      return null;
    }
  }

  static Future<String?> _ensureBackendTokenInternal() async {
    try {
      debugPrint("❌❌❌ AUTH_GUARD ensureBackendToken START");

      final existing = await AppState.getToken();

      if (existing != null && existing.isNotEmpty) {
        try {
          await AuthApi.getMe(accessToken: existing);

          debugPrint("❌❌❌ AUTH_GUARD existing token VALID");

          return existing;
        } catch (e) {
          debugPrint("❌❌❌ AUTH_GUARD existing token INVALID = $e");
        }
      }

      try {
        debugPrint("❌❌❌ AUTH_GUARD trying refresh token");

        final refreshedAccess = await _refreshAccessToken();

        if (refreshedAccess != null && refreshedAccess.isNotEmpty) {
          debugPrint("❌❌❌ AUTH_GUARD refresh SUCCESS");

          return refreshedAccess;
        }
      } catch (e) {
        debugPrint("❌❌❌ AUTH_GUARD refresh FAILED = $e");
      }

      debugPrint("❌❌❌ AUTH_GUARD doing Google login");

      final userCredential =
          await GoogleAuthService.signInWithGoogle();

      if (userCredential == null) {
        debugPrint("❌❌❌ AUTH_GUARD Google login cancelled/null");
        return null;
      }

      final user = userCredential.user;

      if (user == null) {
        debugPrint("❌❌❌ AUTH_GUARD Firebase user null");
        return null;
      }

      final idToken = await user.getIdToken(true);

      if (idToken == null || idToken.isEmpty) {
        debugPrint("❌❌❌ AUTH_GUARD idToken empty");
        return null;
      }

      final authData = await AuthApi.googleLogin(
        idToken: idToken,
      );

      final accessToken =
          authData["access_token"]?.toString();

      final refreshToken =
          authData["refresh_token"]?.toString();

      if (accessToken == null ||
          accessToken.isEmpty ||
          refreshToken == null ||
          refreshToken.isEmpty) {
        debugPrint("❌❌❌ AUTH_GUARD backend tokens empty");

        return null;
      }

      await AppState.setTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      debugPrint(
        "❌❌❌ AUTH_GUARD Google/backend login SUCCESS",
      );

      return accessToken;
    } catch (e, s) {
      debugPrint("❌❌❌ AUTH_GUARD ERROR = $e");
      debugPrint("$s");

      return null;
    }
  }

  static Future<void> forceLogout() async {
    try {
      await AppState.logout();

      await GoogleAuthService.signOut();

      debugPrint(
        "❌❌❌ AUTH_GUARD forceLogout SUCCESS",
      );
    } catch (e) {
      debugPrint(
        "❌❌❌ AUTH_GUARD forceLogout ERROR = $e",
      );
    }
  }
}