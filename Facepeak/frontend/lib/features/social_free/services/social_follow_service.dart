import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/features/social_free/social_features/social_api.dart';
import 'package:frontend/features/social_free/social_features/social_auth_guard.dart';

class SocialFollowService {
  static const Duration _timeout = Duration(seconds: 10);

  static Future<String> _token() async {
    final token = await SocialAuthGuard.ensureBackendToken();

    debugPrint("❌❌❌ FOLLOW_SERVICE token exists = ${token != null}");

    if (token == null || token.trim().isEmpty) {
      debugPrint("❌❌❌ FOLLOW_SERVICE NO TOKEN");
      throw Exception("NO_TOKEN");
    }

    return token.trim();
  }

  static Map<String, dynamic> _decodeMap(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);

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

  static String _errorMessage(Map<String, dynamic> data, int statusCode) {
    final detail = data["detail"];
    final message = data["message"];

    if (detail != null && detail.toString().trim().isNotEmpty) {
      return detail.toString();
    }

    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString();
    }

    return "FOLLOW_HTTP_FAILED_$statusCode";
  }

  static Future<Map<String, dynamic>> _requestMap({
    required String method,
    required String path,
  }) async {
    final token = await _token();
    final url = Uri.parse("${SocialApi.baseUrl}$path");

    debugPrint("❌❌❌ FOLLOW_SERVICE HTTP $method $url");

    try {
      final headers = {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      };

      late final http.Response res;

      switch (method) {
        case "GET":
          res = await http.get(url, headers: headers).timeout(_timeout);
          break;
        case "POST":
          res = await http.post(url, headers: headers).timeout(_timeout);
          break;
        case "DELETE":
          res = await http.delete(url, headers: headers).timeout(_timeout);
          break;
        default:
          throw Exception("UNSUPPORTED_METHOD_$method");
      }

      debugPrint("❌❌❌ FOLLOW_SERVICE status = ${res.statusCode}");
      debugPrint("❌❌❌ FOLLOW_SERVICE body = ${res.body}");

      final data = _decodeMap(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return data;
      }

      throw Exception(_errorMessage(data, res.statusCode));
    } on TimeoutException {
      debugPrint("❌❌❌ FOLLOW_SERVICE TIMEOUT");
      throw Exception("FOLLOW_TIMEOUT");
    } catch (e) {
      debugPrint("❌❌❌ FOLLOW_SERVICE ERROR = $e");
      throw Exception("FOLLOW_ERROR: $e");
    }
  }

  static Future<Map<String, dynamic>> followUser({
    required int targetUserId,
  }) async {
    if (targetUserId <= 0) throw Exception("INVALID_TARGET_USER_ID");

    debugPrint("❌❌❌ FOLLOW_SERVICE followUser targetUserId=$targetUserId");

    return await _requestMap(
      method: "POST",
      path: "/api/v1/social/users/$targetUserId/follow",
    );
  }

  static Future<Map<String, dynamic>> unfollowUser({
    required int targetUserId,
  }) async {
    if (targetUserId <= 0) throw Exception("INVALID_TARGET_USER_ID");

    debugPrint("❌❌❌ FOLLOW_SERVICE unfollowUser targetUserId=$targetUserId");

    return await _requestMap(
      method: "DELETE",
      path: "/api/v1/social/users/$targetUserId/follow",
    );
  }

  static Future<Map<String, dynamic>> removeFollower({
    required int followerId,
  }) async {
    if (followerId <= 0) throw Exception("INVALID_FOLLOWER_ID");

    debugPrint("❌❌❌ FOLLOW_SERVICE removeFollower followerId=$followerId");

    return await _requestMap(
      method: "DELETE",
      path: "/api/v1/social/followers/$followerId",
    );
  }

  static Future<Map<String, dynamic>> getFollowersPage({
    required int userId,
    int limit = 30,
    int offset = 0,
  }) async {
    if (userId <= 0) throw Exception("INVALID_USER_ID");

    final safeLimit = limit.clamp(1, 50);
    final safeOffset = offset < 0 ? 0 : offset;

    debugPrint(
      "❌❌❌ FOLLOW_SERVICE getFollowersPage userId=$userId limit=$safeLimit offset=$safeOffset",
    );

    final res = await _requestMap(
      method: "GET",
      path:
          "/api/v1/social/users/$userId/followers?limit=$safeLimit&offset=$safeOffset",
    );

    final followers = _decodeList(res, "followers");
    final items = followers.isNotEmpty ? followers : _decodeList(res, "items");

    return {
      "followers": items,
      "items": items,
      "has_more": res["has_more"] == true,
      "next_offset": res["next_offset"] is num
          ? (res["next_offset"] as num).toInt()
          : safeOffset + items.length,
      "count": res["count"] is num
          ? (res["count"] as num).toInt()
          : items.length,
      "limit": safeLimit,
      "offset": safeOffset,
    };
  }

  static Future<Map<String, dynamic>> getFollowingPage({
    required int userId,
    int limit = 30,
    int offset = 0,
  }) async {
    if (userId <= 0) throw Exception("INVALID_USER_ID");

    final safeLimit = limit.clamp(1, 50);
    final safeOffset = offset < 0 ? 0 : offset;

    debugPrint(
      "❌❌❌ FOLLOW_SERVICE getFollowingPage userId=$userId limit=$safeLimit offset=$safeOffset",
    );

    final res = await _requestMap(
      method: "GET",
      path:
          "/api/v1/social/users/$userId/following?limit=$safeLimit&offset=$safeOffset",
    );

    final following = _decodeList(res, "following");
    final items = following.isNotEmpty ? following : _decodeList(res, "items");

    return {
      "following": items,
      "items": items,
      "has_more": res["has_more"] == true,
      "next_offset": res["next_offset"] is num
          ? (res["next_offset"] as num).toInt()
          : safeOffset + items.length,
      "count": res["count"] is num
          ? (res["count"] as num).toInt()
          : items.length,
      "limit": safeLimit,
      "offset": safeOffset,
    };
  }

  static Future<List<Map<String, dynamic>>> getFollowers({
    required int userId,
    int limit = 30,
    int offset = 0,
  }) async {
    final page = await getFollowersPage(
      userId: userId,
      limit: limit,
      offset: offset,
    );

    final raw = page["items"];

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return <Map<String, dynamic>>[];
  }

  static Future<List<Map<String, dynamic>>> getFollowing({
    required int userId,
    int limit = 30,
    int offset = 0,
  }) async {
    final page = await getFollowingPage(
      userId: userId,
      limit: limit,
      offset: offset,
    );

    final raw = page["items"];

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return <Map<String, dynamic>>[];
  }
}