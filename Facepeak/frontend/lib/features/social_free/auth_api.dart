import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class AuthApi {
  static const String _baseUrl = 'http://192.168.88.100:8000';

  // =========================================================
  // ▶️ GOOGLE LOGIN → BACKEND → ACCESS + REFRESH
  // =========================================================
  static Future<Map<String, dynamic>> googleLogin({
    required String idToken,
  }) async {
    final url = Uri.parse('$_baseUrl/api/v1/auth/google');

    try {
      final res = await http
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({
              "id_token": idToken,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = res.body.isNotEmpty
          ? jsonDecode(res.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (res.statusCode != 200) {
        throw Exception(
          data["detail"] ??
              data["message"] ??
              "GOOGLE_LOGIN_FAILED_${res.statusCode}",
        );
      }

      final accessToken = data["access_token"];
      final refreshToken = data["refresh_token"];

      if (accessToken == null ||
          accessToken is! String ||
          accessToken.isEmpty) {
        throw Exception("NO_ACCESS_TOKEN");
      }

      if (refreshToken == null ||
          refreshToken is! String ||
          refreshToken.isEmpty) {
        throw Exception("NO_REFRESH_TOKEN");
      }

      return {
        "access_token": accessToken,
        "refresh_token": refreshToken,
        "user_id": data["user_id"],
        "status": data["status"] ?? "success",
      };
    } on TimeoutException {
      throw Exception("GOOGLE_LOGIN_TIMEOUT");
    } catch (e) {
      throw Exception("GOOGLE_LOGIN_ERROR: $e");
    }
  }

  // =========================================================
  // ▶️ REFRESH ACCESS TOKEN
  // =========================================================
  static Future<Map<String, dynamic>> refresh({
    required String refreshToken,
  }) async {
    final url = Uri.parse('$_baseUrl/api/v1/auth/refresh');

    try {
      final res = await http
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({
              "refresh_token": refreshToken,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = res.body.isNotEmpty
          ? jsonDecode(res.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (res.statusCode != 200) {
        throw Exception(
          data["detail"] ??
              data["message"] ??
              "REFRESH_FAILED_${res.statusCode}",
        );
      }

      final accessToken = data["access_token"];
      final newRefreshToken = data["refresh_token"];

      if (accessToken == null ||
          accessToken is! String ||
          accessToken.isEmpty) {
        throw Exception("NO_ACCESS_TOKEN");
      }

      if (newRefreshToken == null ||
          newRefreshToken is! String ||
          newRefreshToken.isEmpty) {
        throw Exception("NO_REFRESH_TOKEN");
      }

      return {
        "access_token": accessToken,
        "refresh_token": newRefreshToken,
        "status": data["status"] ?? "success",
      };
    } on TimeoutException {
      throw Exception("REFRESH_TIMEOUT");
    } catch (e) {
      throw Exception("REFRESH_ERROR: $e");
    }
  }

  // =========================================================
  // ▶️ LOGOUT
  // =========================================================
  static Future<void> logout({
    required String refreshToken,
  }) async {
    final url = Uri.parse('$_baseUrl/api/v1/auth/logout');

    try {
      final res = await http
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({
              "refresh_token": refreshToken,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        final data = res.body.isNotEmpty
            ? jsonDecode(res.body) as Map<String, dynamic>
            : <String, dynamic>{};

        throw Exception(
          data["detail"] ??
              data["message"] ??
              "LOGOUT_FAILED_${res.statusCode}",
        );
      }
    } on TimeoutException {
      throw Exception("LOGOUT_TIMEOUT");
    } catch (e) {
      throw Exception("LOGOUT_ERROR: $e");
    }
  }

  // =========================================================
  // ▶️ GET ME
  // =========================================================
  static Future<Map<String, dynamic>> getMe({
    required String accessToken,
  }) async {
    final url = Uri.parse('$_baseUrl/api/v1/auth/me');

    try {
      final res = await http
          .get(
            url,
            headers: {
              "Authorization": "Bearer $accessToken",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10));

      final data = res.body.isNotEmpty
          ? jsonDecode(res.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (res.statusCode != 200) {
        throw Exception(
          data["detail"] ??
              data["message"] ??
              "GET_ME_FAILED_${res.statusCode}",
        );
      }

      return _normalizeUser(data);
    } on TimeoutException {
      throw Exception("GET_ME_TIMEOUT");
    } catch (e) {
      throw Exception("GET_ME_ERROR: $e");
    }
  }

  // =========================================================
  // ▶️ NORMALIZE USER SNAPSHOT
  // =========================================================
  static Map<String, dynamic> _normalizeUser(Map<String, dynamic> data) {
    final psl = (data["psl"] is Map<String, dynamic>)
        ? data["psl"] as Map<String, dynamic>
        : <String, dynamic>{};

    data["psl"] = {
      "psl_score": (psl["psl_score"] is num)
          ? (psl["psl_score"] as num).toInt()
          : 0,
      "tier": psl["tier"] ?? "Unknown",
      "percentile": psl["percentile"] ?? "",
      "confidence": (psl["confidence"] is num)
          ? (psl["confidence"] as num).toDouble()
          : 0.0,
    };

    data["id"] = data["id"];
    data["username"] = data["username"] ?? "user";
    data["bio"] = data["bio"] ?? "";
    data["email"] = data["email"] ?? "";
    data["profile_image_url"] = data["profile_image_url"] ?? "";

    data["followers"] = (data["followers"] is num) ? data["followers"] : 0;
    data["following"] = (data["following"] is num) ? data["following"] : 0;
    data["matches"] = (data["matches"] is num) ? data["matches"] : 0;
    data["profile_views"] =
        (data["profile_views"] is num) ? data["profile_views"] : 0;

    return data;
  }
}