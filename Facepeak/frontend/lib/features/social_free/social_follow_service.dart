import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/features/social_free/social_features/social_api.dart';
import 'package:frontend/features/social_free/social_features/social_auth_guard.dart';

class SocialFollowService {
  static const Duration _timeout = Duration(seconds: 10);

  // ======================
  // 🔑 TOKEN
  // ======================
  static Future<String> _token() async {
    final token = await SocialAuthGuard.ensureBackendToken();

    debugPrint("❌❌❌ FOLLOW_SERVICE token exists = ${token != null}");

    if (token == null || token.trim().isEmpty) {
      debugPrint("❌❌❌ FOLLOW_SERVICE NO TOKEN");
      throw Exception("NO_TOKEN");
    }

    return token.trim();
  }

  // ======================
  // 🧠 REQUEST CORE
  // ======================
  static Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
  }) async {
    final token = await _token();
    final url = Uri.parse("${SocialApi.baseUrl}$path");

    debugPrint("❌❌❌ FOLLOW_SERVICE $method $url");

    try {
      final headers = {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      };

      late http.Response res;

      if (method == "POST") {
        res = await http.post(url, headers: headers).timeout(_timeout);
      } else if (method == "DELETE") {
        res = await http.delete(url, headers: headers).timeout(_timeout);
      } else if (method == "GET") {
        res = await http.get(url, headers: headers).timeout(_timeout);
      } else {
        throw Exception("INVALID_METHOD");
      }

      debugPrint("❌❌❌ FOLLOW_SERVICE status = ${res.statusCode}");
      debugPrint("❌❌❌ FOLLOW_SERVICE body = ${res.body}");

      final decoded = res.body.isNotEmpty ? jsonDecode(res.body) : {};

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return decoded is Map<String, dynamic>
            ? decoded
            : Map<String, dynamic>.from(decoded);
      }

      throw Exception(decoded.toString());
    } catch (e) {
      debugPrint("❌❌❌ FOLLOW_SERVICE ERROR = $e");
      throw Exception("FOLLOW_ERROR: $e");
    }
  }

  // ======================
  // ➕ FOLLOW
  // ======================
  static Future<Map<String, dynamic>> followUser({
    required int targetUserId,
  }) async {
    if (targetUserId <= 0) {
      throw Exception("INVALID_USER_ID");
    }

    debugPrint("❌❌❌ FOLLOW_SERVICE FOLLOW START");
    debugPrint("❌❌❌ FOLLOW_SERVICE targetUserId = $targetUserId");

    return await _request(
      method: "POST",
      path: "/api/v1/social/users/$targetUserId/follow",
    );
  }

  // ======================
  // ➖ UNFOLLOW
  // ======================
  static Future<Map<String, dynamic>> unfollowUser({
    required int targetUserId,
  }) async {
    if (targetUserId <= 0) {
      throw Exception("INVALID_USER_ID");
    }

    debugPrint("❌❌❌ FOLLOW_SERVICE UNFOLLOW START");
    debugPrint("❌❌❌ FOLLOW_SERVICE targetUserId = $targetUserId");

    return await _request(
      method: "DELETE",
      path: "/api/v1/social/users/$targetUserId/follow",
    );
  }

  // ======================
  // ❌ REMOVE FOLLOWER
  // ======================
  static Future<Map<String, dynamic>> removeFollower({
    required int followerId,
  }) async {
    if (followerId <= 0) {
      throw Exception("INVALID_USER_ID");
    }

    debugPrint("❌❌❌ FOLLOW_SERVICE REMOVE FOLLOWER START");
    debugPrint("❌❌❌ FOLLOW_SERVICE followerId = $followerId");

    return await _request(
      method: "DELETE",
      path: "/api/v1/social/followers/$followerId",
    );
  }

  // ======================
  // 👥 GET FOLLOWERS
  // ======================
  static Future<List<Map<String, dynamic>>> getFollowers({
    required int userId,
  }) async {
    debugPrint("❌❌❌ FOLLOW_SERVICE GET FOLLOWERS START userId=$userId");

    final res = await _request(
      method: "GET",
      path: "/api/v1/social/users/$userId/followers",
    );

    final list = res["followers"];

    if (list is List) {
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return [];
  }

  // ======================
  // 👤 GET FOLLOWING
  // ======================
  static Future<List<Map<String, dynamic>>> getFollowing({
    required int userId,
  }) async {
    debugPrint("❌❌❌ FOLLOW_SERVICE GET FOLLOWING START userId=$userId");

    final res = await _request(
      method: "GET",
      path: "/api/v1/social/users/$userId/following",
    );

    final list = res["following"];

    if (list is List) {
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return [];
  }
}