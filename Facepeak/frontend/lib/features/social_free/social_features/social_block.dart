import 'dart:convert';
import 'package:http/http.dart' as http;

class SocialBlock {
  static const String _baseUrl = 'http://192.168.88.100:8000';

  // =========================================================
  // ▶️ FOLLOW
  // =========================================================
  static Future<Map<String, dynamic>> follow({
    required int userId,
    required int targetId,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/social/follow/$targetId?user_id=$userId'),
    );

    if (res.statusCode != 200) {
      throw Exception("FOLLOW_FAILED");
    }

    return jsonDecode(res.body);
  }

  // =========================================================
  // ▶️ UNFOLLOW
  // =========================================================
  static Future<Map<String, dynamic>> unfollow({
    required int userId,
    required int targetId,
  }) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/social/follow/$targetId?user_id=$userId'),
    );

    if (res.statusCode != 200) {
      throw Exception("UNFOLLOW_FAILED");
    }

    return jsonDecode(res.body);
  }

  // =========================================================
  // ▶️ IS FOLLOWING
  // =========================================================
  static Future<bool> isFollowing({
    required int userId,
    required int targetId,
  }) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/social/is-following?user_id=$userId&target_id=$targetId'),
    );

    if (res.statusCode != 200) {
      throw Exception("CHECK_FAILED");
    }

    final body = jsonDecode(res.body);
    return body["is_following"] ?? false;
  }

  // =========================================================
  // ▶️ GET FOLLOWERS
  // =========================================================
  static Future<List<dynamic>> getFollowers({
    required int userId,
  }) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/social/followers/$userId'),
    );

    if (res.statusCode != 200) {
      throw Exception("GET_FOLLOWERS_FAILED");
    }

    return jsonDecode(res.body);
  }

  // =========================================================
  // ▶️ GET FOLLOWING
  // =========================================================
  static Future<List<dynamic>> getFollowing({
    required int userId,
  }) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/social/following/$userId'),
    );

    if (res.statusCode != 200) {
      throw Exception("GET_FOLLOWING_FAILED");
    }

    return jsonDecode(res.body);
  }

  // =========================================================
  // ▶️ ADD PROFILE VIEW
  // =========================================================
  static Future<Map<String, dynamic>> addView({
    required int userId,
    required int targetId,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/social/view/$targetId?user_id=$userId'),
    );

    if (res.statusCode != 200) {
      throw Exception("VIEW_FAILED");
    }

    return jsonDecode(res.body);
  }

  // =========================================================
  // ▶️ GET PROFILE VIEWS
  // =========================================================
  static Future<Map<String, dynamic>> getViews({
    required int userId,
  }) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/social/views/$userId'),
    );

    if (res.statusCode != 200) {
      throw Exception("GET_VIEWS_FAILED");
    }

    return jsonDecode(res.body);
  }
}