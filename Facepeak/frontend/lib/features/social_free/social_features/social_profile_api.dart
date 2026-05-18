import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/features/social_free/social_features/social_api.dart';
import 'package:frontend/features/social_free/social_features/social_auth_guard.dart';

class SocialProfileApi {
  static Future<String> _validToken(String token) async {
    final clean = token.trim();

    if (clean.isNotEmpty) return clean;

    final guarded = await SocialAuthGuard.ensureBackendToken();

    if (guarded == null || guarded.trim().isEmpty) {
      throw Exception("AUTH_REQUIRED");
    }

    return guarded.trim();
  }

  // =========================================
  // 👤 GET USER PROFILE
  // =========================================
  static Future<Map<String, dynamic>> getUserById({
    required String token,
    required int userId,
  }) async {
    final cleanToken = await _validToken(token);

    final url = Uri.parse(
      '${SocialApi.baseUrl}/api/v1/social/user/$userId',
    );

    try {
      debugPrint("❌❌❌ SOCIAL_PROFILE_API getUserById START");
      debugPrint("❌❌❌ SOCIAL_PROFILE_API userId = $userId");

      final response = await http
          .get(
            url,
            headers: {
              "Authorization": "Bearer $cleanToken",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint(
        "❌❌❌ SOCIAL_PROFILE_API status = ${response.statusCode}",
      );
      debugPrint("❌❌❌ SOCIAL_PROFILE_API body = ${response.body}");

      final Map<String, dynamic> data =
          response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 && data["status"] == "success") {
        final user = data["user"];
        if (user is Map) {
          return Map<String, dynamic>.from(user);
        }
        return {};
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        await SocialAuthGuard.forceLogout();
        throw Exception("AUTH_REQUIRED");
      }

      throw Exception(
        data["detail"] ??
            data["message"] ??
            "GET_USER_FAILED_${response.statusCode}",
      );
    } on TimeoutException {
      debugPrint("❌❌❌ SOCIAL_PROFILE_API TIMEOUT");
      throw Exception("GET_USER_TIMEOUT");
    } catch (e) {
      debugPrint("❌❌❌ SOCIAL_PROFILE_API ERROR = $e");
      throw Exception("GET_USER_ERROR: $e");
    }
  }
}