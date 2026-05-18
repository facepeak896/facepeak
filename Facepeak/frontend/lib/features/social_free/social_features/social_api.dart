import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';

import 'package:frontend/features/social_free/social_features/social_auth_guard.dart';

class SocialApi {
  static const String baseUrl = 'http://192.168.88.100:8000';

  static bool _socialUsersFetching = false;

  static Future<String> _validToken() async {
    final token = await SocialAuthGuard.ensureBackendToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception("AUTH_REQUIRED");
    }

    return token.trim();
  }

  // =========================================
  // ❌ SAVE ANALYSIS PROFILE
  // =========================================
  static Future<Map<String, dynamic>> saveAnalysisProfile({
    required String token,
    required File imageFile,
    String? weeklyPotentialRange,
    int? reachTargetPercentile,
  }) async {
    final cleanToken = token.trim().isNotEmpty ? token.trim() : await _validToken();

    final url = Uri.parse('$baseUrl/api/v1/profile/me/save-analysis-profile');

    try {
      debugPrint("❌❌❌ SOCIAL_API saveAnalysisProfile START");

      final request = http.MultipartRequest("POST", url);

      request.headers.addAll({
        "Authorization": "Bearer $cleanToken",
        "Accept": "application/json",
      });

      request.files.add(
        await http.MultipartFile.fromPath(
          "image",
          imageFile.path,
          contentType: MediaType("image", "jpeg"),
        ),
      );

      if (weeklyPotentialRange != null) {
        request.fields["weekly_potential_range"] = weeklyPotentialRange;
      }

      if (reachTargetPercentile != null) {
        request.fields["reach_target_percentile"] =
            reachTargetPercentile.toString();
      }

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 15));

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("❌❌❌ SOCIAL_API saveAnalysisProfile status = ${response.statusCode}");
      debugPrint("❌❌❌ SOCIAL_API saveAnalysisProfile body = ${response.body}");

      final Map<String, dynamic> data =
          response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        debugPrint("❌❌❌ SOCIAL_API saveAnalysisProfile SUCCESS");
        return data;
      }

      throw Exception(
        data["detail"] ??
            data["message"] ??
            "SAVE_PROFILE_FAILED_${response.statusCode}",
      );
    } on TimeoutException {
      debugPrint("❌❌❌ SOCIAL_API saveAnalysisProfile TIMEOUT");
      throw Exception("SAVE_PROFILE_TIMEOUT");
    } catch (e) {
      debugPrint("❌❌❌ SOCIAL_API saveAnalysisProfile ERROR = $e");
      throw Exception("SAVE_PROFILE_ERROR: $e");
    }
  }

  // =========================================
  // ❌ GO LIVE
  // =========================================
  static Future<Map<String, dynamic>> goLive({
    required String token,
  }) async {
    final cleanToken = token.trim().isNotEmpty ? token.trim() : await _validToken();

    final url = Uri.parse('$baseUrl/api/v1/social/go-live');

    try {
      debugPrint("❌❌❌ SOCIAL_API goLive START");
      debugPrint("❌❌❌ SOCIAL_API goLive token exists = ${cleanToken.isNotEmpty}");

      final response = await http
          .post(
            url,
            headers: {
              "Authorization": "Bearer $cleanToken",
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint("❌❌❌ SOCIAL_API goLive status = ${response.statusCode}");
      debugPrint("❌❌❌ SOCIAL_API goLive body = ${response.body}");

      final Map<String, dynamic> data =
          response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        debugPrint("❌❌❌ SOCIAL_API goLive SUCCESS");
        return data;
      }

      throw Exception(
        data["detail"] ??
            data["message"] ??
            "GO_LIVE_FAILED_${response.statusCode}",
      );
    } on TimeoutException {
      debugPrint("❌❌❌ SOCIAL_API goLive TIMEOUT");
      throw Exception("GO_LIVE_TIMEOUT");
    } catch (e) {
      debugPrint("❌❌❌ SOCIAL_API goLive ERROR = $e");
      throw Exception("GO_LIVE_ERROR: $e");
    }
  }

  static Future<Map<String, dynamic>> getUserById({
    required String token,
    required int userId,
  }) async {
    final cleanToken = token.trim().isNotEmpty ? token.trim() : await _validToken();

    final url = Uri.parse('$baseUrl/api/v1/social/user/$userId');

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $cleanToken",
        "Accept": "application/json",
      },
    );

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode == 200) {
      return data["user"];
    }

    throw Exception("USER_FETCH_FAILED_${response.statusCode}");
  }
  static Future<Map<String, dynamic>> getSocialRescoreStatus({
  required String token,
}) async {
  final cleanToken =
      token.trim().isNotEmpty ? token.trim() : await _validToken();

  final url = Uri.parse('$baseUrl/api/v1/social/rescore/status');

  final response = await http.get(
    url,
    headers: {
      "Authorization": "Bearer $cleanToken",
      "Accept": "application/json",
    },
  );

  final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

  if (response.statusCode == 200 && data is Map<String, dynamic>) {
    return data;
  }

  throw Exception("RESCORE_STATUS_FAILED_${response.statusCode}");
}

  // =========================================
  // ❌ LIVE STATUS
  // =========================================
  static Future<bool> getLiveStatus({
    required String token,
  }) async {
    final cleanToken = token.trim().isNotEmpty ? token.trim() : await _validToken();

    final url = Uri.parse('$baseUrl/api/v1/social/live-status');

    try {
      debugPrint("❌❌❌ SOCIAL_API getLiveStatus START");

      final response = await http
          .get(
            url,
            headers: {
              "Authorization": "Bearer $cleanToken",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10));

      final Map<String, dynamic> data =
          response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return data["is_live"] == true;
      }

      throw Exception("LIVE_STATUS_FAILED_${response.statusCode}");
    } catch (e) {
      debugPrint("❌❌❌ SOCIAL_API getLiveStatus ERROR = $e");
      throw Exception("LIVE_STATUS_ERROR: $e");
    }
  }

  // =========================================
  // ❌ EXPLAINER SEEN
  // =========================================
  static Future<Map<String, dynamic>> markExplainerSeen({
    required String token,
  }) async {
    final cleanToken = token.trim().isNotEmpty ? token.trim() : await _validToken();

    final url = Uri.parse('$baseUrl/api/v1/social/social-explainer/seen');

    try {
      final response = await http
          .post(
            url,
            headers: {
              "Authorization": "Bearer $cleanToken",
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10));

      final Map<String, dynamic> data =
          response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return data;
      }

      throw Exception("EXPLAINER_FAILED_${response.statusCode}");
    } catch (e) {
      debugPrint("❌❌❌ SOCIAL_API markExplainerSeen ERROR = $e");
      throw Exception("EXPLAINER_ERROR: $e");
    }
  }
  static Future<void> deleteMyAccount({
  required String token,
}) async {
  final response = await http.delete(
    Uri.parse("$baseUrl/api/v1/account/me"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  if (response.statusCode != 200) {
    throw Exception("DELETE_ACCOUNT_FAILED");
  }
}
  static Future<Map<String, dynamic>> getSocialUsersPage({
  required String token,
  int limit = 30,
  int offset = 0,
}) async {
  final safeLimit = limit.clamp(1, 50);
  final safeOffset = offset < 0 ? 0 : offset;

  final uri = Uri.parse(
    "$baseUrl/api/v1/social/users?limit=$safeLimit&offset=$safeOffset",
  );

  final res = await http.get(
    uri,
    headers: {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    },
  );

  final data = jsonDecode(res.body);

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception(data["detail"] ?? "SOCIAL_USERS_FAILED");
  }

  final users = data["users"];

  return {
    "users": users is List ? users : [],
    "items": users is List ? users : [],
    "has_more": data["has_more"] == true,
    "next_offset": data["next_offset"] is num
        ? (data["next_offset"] as num).toInt()
        : safeOffset + (users is List ? users.length : 0),
    "count": data["count"] is num
        ? (data["count"] as num).toInt()
        : (users is List ? users.length : 0),
  };
}

  // =========================================
  // ❌ SOCIAL USERS SEARCH / FEED
  // =========================================
  static Future<List<Map<String, dynamic>>> getSocialUsers({
    required String token,
    int limit = 30,
    int offset = 0,
  }) async {
    if (_socialUsersFetching && offset == 0) {
      debugPrint("❌❌❌ SOCIAL_API getSocialUsers SKIPPED duplicate request");
      return [];
    }

    _socialUsersFetching = true;

    try {
      final cleanToken = token.trim().isNotEmpty ? token.trim() : await _validToken();

      final safeLimit = limit.clamp(1, 50);
      final safeOffset = offset < 0 ? 0 : offset;

      final url = Uri.parse(
        '$baseUrl/api/v1/social/users?limit=$safeLimit&offset=$safeOffset',
      );

      debugPrint("❌❌❌ SOCIAL_API getSocialUsers START");

      final response = await http
          .get(
            url,
            headers: {
              "Authorization": "Bearer $cleanToken",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint("❌❌❌ SOCIAL_API getSocialUsers status = ${response.statusCode}");
      debugPrint("❌❌❌ SOCIAL_API getSocialUsers body = ${response.body}");

      final Map<String, dynamic> data =
          response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 && data["status"] == "success") {
        final rawUsers = data["users"];

        if (rawUsers is List) {
          return rawUsers
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }

        return [];
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        await SocialAuthGuard.forceLogout();
        throw Exception("AUTH_REQUIRED");
      }

      throw Exception(
        data["detail"] ??
            data["message"] ??
            "GET_SOCIAL_USERS_FAILED_${response.statusCode}",
      );
    } on TimeoutException {
      debugPrint("❌❌❌ SOCIAL_API getSocialUsers TIMEOUT");
      throw Exception("GET_SOCIAL_USERS_TIMEOUT");
    } catch (e) {
      debugPrint("❌❌❌ SOCIAL_API getSocialUsers ERROR = $e");
      throw Exception("GET_SOCIAL_USERS_ERROR: $e");
    } finally {
      _socialUsersFetching = false;
    }
  }
}