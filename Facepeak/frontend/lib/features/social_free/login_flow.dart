import 'package:flutter/material.dart';
import 'package:frontend/features/analysis/screens/app_state.dart';
import 'login_screen.dart';

class LoginGate {
  static bool _isShowing = false;

  static Future<void> requireLogin(
    BuildContext context,
    Function(String token) onSuccess,
  ) async {

    /// =========================
    /// 1️⃣ AKO JE VEĆ LOGIN → ODMAH NASTAVI
    /// =========================
    final isLogged = await AppState.isLoggedIn();

    if (isLogged) {
      final token = await AppState.getToken();

      if (token != null && token.isNotEmpty) {
        onSuccess(token);
      }
      return;
    }

    /// =========================
    /// 2️⃣ SPRIJEČI DUPLI OPEN
    /// =========================
    if (_isShowing) return;

    _isShowing = true;

    /// =========================
    /// 3️⃣ PUSH LOGIN SCREEN
    /// =========================
    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AuthScreen(
          onSuccess: (token) async {
            await AppState.setToken(token); // 🔥 SPREMI TOKEN
            Navigator.pop(context);
          },
        ),
      ),
    );

    _isShowing = false;

    /// =========================
    /// 4️⃣ NAKON LOGIN → PROVJERI OPET
    /// =========================
    final nowLogged = await AppState.isLoggedIn();

    if (nowLogged) {
      final token = await AppState.getToken();

      if (token != null && token.isNotEmpty) {
        onSuccess(token);
      }
    }
  }
}