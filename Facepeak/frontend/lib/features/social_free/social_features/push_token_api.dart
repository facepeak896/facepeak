import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/features/social_free/social_features/social_auth_guard.dart';

class PushTokenApi {
  static const String baseUrl = 'http://192.168.88.100:8000';

  static bool _sending = false;

  static Future<void> sendToken({
    required String fcmToken,
  }) async {
    if (_sending) {
      debugPrint("⚠️ PUSH_API already sending → skip");
      return;
    }

    if (fcmToken.trim().isEmpty) {
      debugPrint("❌ PUSH_API invalid fcm token");
      return;
    }

    _sending = true;

    try {
      debugPrint("🔥 PUSH_API sendToken START");

      final token = await SocialAuthGuard.ensureBackendToken();

      debugPrint("🔥 PUSH_API backend token exists = ${token != null}");

      if (token == null || token.trim().isEmpty) {
        debugPrint("❌ PUSH_API NO VALID BACKEND TOKEN");
        return;
      }

      final url = Uri.parse('$baseUrl/api/v1/social/push-token');

      final res = await http
          .post(
            url,
            headers: {
              "Authorization": "Bearer ${token.trim()}",
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({
              "fcm_token": fcmToken.trim(),
              "platform": "android",
            }),
          )
          .timeout(const Duration(seconds: 8));

      debugPrint("🔥 PUSH_API status = ${res.statusCode}");
      debugPrint("🔥 PUSH_API body = ${res.body}");

      if (res.statusCode >= 200 && res.statusCode < 300) {
        debugPrint("✅ PUSH_API SUCCESS");
        return;
      }

      debugPrint("❌ PUSH_API FAILED status=${res.statusCode}");
    } on TimeoutException {
      debugPrint("❌ PUSH_API TIMEOUT");
    } catch (e, s) {
      debugPrint("❌ PUSH_API ERROR = $e");
      debugPrint("❌ PUSH_API STACK = $s");
    } finally {
      _sending = false;
    }
  }
}