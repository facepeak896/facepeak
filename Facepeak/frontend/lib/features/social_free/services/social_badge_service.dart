import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:frontend/features/social_free/social_features/social_api.dart';
import 'package:frontend/features/social_free/social_features/social_auth_guard.dart';

class SocialBadgeService {
  static Future<Map<String, dynamic>> getBadges() async {
    final token = await SocialAuthGuard.ensureBackendToken();

    if (token == null || token.isEmpty) {
      throw Exception("NO_TOKEN");
    }

    final res = await http.get(
      Uri.parse('${SocialApi.baseUrl}/api/v1/social/badges'),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    final data = jsonDecode(res.body);

    if (res.statusCode != 200) {
      throw Exception("BADGES_FAILED_${res.statusCode}");
    }

    return Map<String, dynamic>.from(data["badges"] ?? {});
  }
  
  static Future<void> markFollowSeen() async {
  final token = await SocialAuthGuard.ensureBackendToken();

  if (token == null || token.isEmpty) {
    throw Exception("NO_TOKEN");
  }

  final res = await http.post(
    Uri.parse('${SocialApi.baseUrl}/api/v1/social/badges/follow/seen'),
    headers: {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
      "Content-Type": "application/json",
    },
  );

  if (res.statusCode != 200) {
    throw Exception("FOLLOW_SEEN_FAILED_${res.statusCode}");
  }
}}
  