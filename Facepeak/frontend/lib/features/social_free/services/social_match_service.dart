import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/features/social_free/social_features/social_api.dart';
import 'package:frontend/features/social_free/social_features/social_auth_guard.dart';

class SocialMatchService {
  static const Duration _timeout = Duration(seconds: 10);

  static Future<String> _token() async {
    final token = await SocialAuthGuard.ensureBackendToken();

    debugPrint("❌❌❌ MATCH_SERVICE token exists = ${token != null}");

    if (token == null || token.trim().isEmpty) {
      debugPrint("❌❌❌ MATCH_SERVICE NO VALID TOKEN");
      throw Exception("NO_VALID_TOKEN");
    }

    return token.trim();
  }

  static Map<String, dynamic> _decodeMap(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return <String, dynamic>{};
    } catch (_) {
      return {"detail": body};
    }
  }

  static List<Map<String, dynamic>> _decodeList(
    Map<String, dynamic> data,
    String key,
  ) {
    final raw = data[key];

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return <Map<String, dynamic>>[];
  }

  static String _errorMessage(
    Map<String, dynamic> data,
    int statusCode,
  ) {
    final detail = data["detail"];
    final message = data["message"];

    if (detail != null && detail.toString().trim().isNotEmpty) {
      return detail.toString();
    }

    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString();
    }

    return "MATCH_HTTP_FAILED_$statusCode";
  }

  static Future<Map<String, dynamic>> _requestMap({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    final token = await _token();
    final url = Uri.parse("${SocialApi.baseUrl}$path");

    debugPrint("❌❌❌ MATCH_SERVICE HTTP $method $url");

    try {
      final headers = {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json",
      };

      late final http.Response res;

      switch (method) {
        case "GET":
          res = await http.get(url, headers: headers).timeout(_timeout);
          break;

        case "POST":
          res = await http
              .post(
                url,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(_timeout);
          break;

        case "DELETE":
          res = await http.delete(url, headers: headers).timeout(_timeout);
          break;

        default:
          throw Exception("UNSUPPORTED_METHOD_$method");
      }

      debugPrint("❌❌❌ MATCH_SERVICE status = ${res.statusCode}");
      debugPrint("❌❌❌ MATCH_SERVICE body = ${res.body}");

      final data = _decodeMap(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return data;
      }

      throw Exception(_errorMessage(data, res.statusCode));
    } on TimeoutException {
      debugPrint("❌❌❌ MATCH_SERVICE TIMEOUT");
      throw Exception("MATCH_TIMEOUT");
    } catch (e) {
      debugPrint("❌❌❌ MATCH_SERVICE ERROR = $e");
      throw Exception("MATCH_ERROR: $e");
    }
  }

  static Future<Map<String, dynamic>> sendMatchRequest({
    required int targetUserId,
  }) async {
    if (targetUserId <= 0) {
      throw Exception("INVALID_TARGET_USER_ID");
    }

    debugPrint("❌❌❌ MATCH_SERVICE sendMatchRequest START");
    debugPrint("❌❌❌ MATCH_SERVICE targetUserId = $targetUserId");

    final res = await _requestMap(
      method: "POST",
      path: "/api/v1/social/users/$targetUserId/match-request",
    );

    debugPrint("❌❌❌ MATCH_SERVICE sendMatchRequest RESPONSE = $res");

    return res;
  }

  static Future<List<Map<String, dynamic>>> getIncomingRequests({
    int limit = 30,
    int offset = 0,
  }) async {
    debugPrint("❌❌❌ MATCH_SERVICE getIncomingRequests START");

    final safeLimit = limit.clamp(1, 50);
    final safeOffset = offset < 0 ? 0 : offset;

    final res = await _requestMap(
      method: "GET",
      path:
          "/api/v1/social/match-requests/incoming?limit=$safeLimit&offset=$safeOffset",
    );

    final list = _decodeList(res, "requests");

    debugPrint("❌❌❌ MATCH_SERVICE incoming count = ${list.length}");

    return list;
  }

  static Future<List<Map<String, dynamic>>> getMatches({
    int limit = 30,
    int offset = 0,
  }) async {
    debugPrint("❌❌❌ MATCH_SERVICE getMatches START");

    final safeLimit = limit.clamp(1, 50);
    final safeOffset = offset < 0 ? 0 : offset;

    final res = await _requestMap(
      method: "GET",
      path: "/api/v1/social/matches?limit=$safeLimit&offset=$safeOffset",
    );

    final list = _decodeList(res, "matches");

    debugPrint("❌❌❌ MATCH_SERVICE matches count = ${list.length}");

    return list;
  }

  static Future<Map<String, dynamic>> acceptRequest({
    required int requestId,
  }) async {
    if (requestId <= 0) {
      throw Exception("INVALID_REQUEST_ID");
    }

    debugPrint("❌❌❌ MATCH_SERVICE accept START requestId=$requestId");

    final res = await _requestMap(
      method: "POST",
      path: "/api/v1/social/match-requests/$requestId/accept",
    );

    debugPrint("❌❌❌ MATCH_SERVICE accept RESPONSE = $res");

    return res;
  }

  static Future<Map<String, dynamic>> rejectRequest({
    required int requestId,
  }) async {
    if (requestId <= 0) {
      throw Exception("INVALID_REQUEST_ID");
    }

    debugPrint("❌❌❌ MATCH_SERVICE reject START requestId=$requestId");

    final res = await _requestMap(
      method: "POST",
      path: "/api/v1/social/match-requests/$requestId/reject",
    );

    debugPrint("❌❌❌ MATCH_SERVICE reject RESPONSE = $res");

    return res;
  }
  static Future<Map<String, dynamic>> getIncomingRequestsPage({
  int limit = 30,
  int offset = 0,
}) async {
  debugPrint("❌❌❌ MATCH_SERVICE getIncomingRequestsPage START");

  final safeLimit = limit.clamp(1, 50);
  final safeOffset = offset < 0 ? 0 : offset;

  final res = await _requestMap(
    method: "GET",
    path:
        "/api/v1/social/match-requests/incoming?limit=$safeLimit&offset=$safeOffset",
  );

  final requests = _decodeList(res, "requests");

  return {
    "items": requests,
    "has_more": res["has_more"] == true ||
        requests.length == safeLimit,
    "next_offset": (res["next_offset"] as num?)?.toInt() ??
        safeOffset + requests.length,
    "count": (res["count"] as num?)?.toInt() ?? requests.length,
  };
}

static Future<Map<String, dynamic>> getMatchesPage({
  int limit = 30,
  int offset = 0,
}) async {
  debugPrint("❌❌❌ MATCH_SERVICE getMatchesPage START");

  final safeLimit = limit.clamp(1, 50);
  final safeOffset = offset < 0 ? 0 : offset;

  final res = await _requestMap(
    method: "GET",
    path: "/api/v1/social/matches?limit=$safeLimit&offset=$safeOffset",
  );

  final matches = _decodeList(res, "matches");

  return {
    "items": matches,
    "has_more": res["has_more"] == true ||
        matches.length == safeLimit,
    "next_offset": (res["next_offset"] as num?)?.toInt() ??
        safeOffset + matches.length,
    "count": (res["count"] as num?)?.toInt() ?? matches.length,
  };
}

  static Future<Map<String, dynamic>> cancelRequest({
    required int requestId,
  }) async {
    if (requestId <= 0) {
      throw Exception("INVALID_REQUEST_ID");
    }

    debugPrint("❌❌❌ MATCH_SERVICE cancel START requestId=$requestId");

    final res = await _requestMap(
      method: "DELETE",
      path: "/api/v1/social/match-requests/$requestId",
    );

    debugPrint("❌❌❌ MATCH_SERVICE cancel RESPONSE = $res");

    return res;
  }
}