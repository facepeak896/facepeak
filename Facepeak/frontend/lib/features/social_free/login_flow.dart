import 'package:flutter/material.dart';
import 'package:frontend/features/analysis/screens/app_state.dart';
import 'package:frontend/features/social_free/social_features/google_auth_service.dart';

// API
import 'package:frontend/features/social_free/auth_api.dart';

class LoginGate {
  static bool _isShowing = false;

  static Future<void> requireLogin(
    BuildContext context,
    Function(String token) onSuccess,
  ) async {
    final isLogged = await AppState.isLoggedIn();

    // ✅ već ima access token
    if (isLogged) {
      final token = await AppState.getToken();

      if (token != null && token.isNotEmpty) {
        onSuccess(token);
      }
      return;
    }

    if (_isShowing) return;
    _isShowing = true;

    try {
      // 🔥 GOOGLE LOGIN
      final userCredential = await GoogleAuthService.signInWithGoogle();
      if (userCredential == null) return;

      final user = userCredential.user;
      if (user == null) return;

      // 🔥 FIREBASE ID TOKEN
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) return;

      // 🔥 BACKEND LOGIN
      final authData = await AuthApi.googleLogin(idToken: idToken);

      final accessToken = authData["access_token"]?.toString();
      final refreshToken = authData["refresh_token"]?.toString();

      if (accessToken == null || accessToken.isEmpty) return;

      // 🔥 SPREMI ACCESS TOKEN
      await AppState.setToken(accessToken);

      // 🔥 ako kasnije dodaš refresh storage:
      // if (refreshToken != null && refreshToken.isNotEmpty) {
      //   await AppState.setRefreshToken(refreshToken);
      // }

      onSuccess(accessToken);
    } catch (e) {
      debugPrint("❌ LOGIN ERROR: $e");
    } finally {
      _isShowing = false;
    }
  }
}