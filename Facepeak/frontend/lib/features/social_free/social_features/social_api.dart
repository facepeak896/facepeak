import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class SocialApi {
  static const String baseUrl = 'http://192.168.88.100:8000';

  // =========================================
  // 🔥 GO LIVE
  // POST /api/v1/social/go-live
  // =========================================
  static Future<Map<String, dynamic>> goLive({
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/social/go-live');

    try {
      final response = await http
          .post(
            url,
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10));

      final Map<String, dynamic> data = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {};

      if (response.statusCode == 200) {
        return data;
      }

      throw Exception(
        data["detail"] ??
            data["message"] ??
            "GO_LIVE_FAILED_${response.statusCode}",
      );
    } on TimeoutException {
      throw Exception("GO_LIVE_TIMEOUT");
    } catch (e) {
      throw Exception("GO_LIVE_ERROR: $e");
    }
  }

  // =========================================
  // 🔥 LIVE STATUS
  // GET /api/v1/social/live-status
  // =========================================
  static Future<bool> getLiveStatus({
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/social/live-status');

    try {
      final response = await http
          .get(
            url,
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10));

      final Map<String, dynamic> data = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {};

      if (response.statusCode == 200) {
        return data["is_live"] == true;
      }

      throw Exception(
        data["detail"] ??
            data["message"] ??
            "LIVE_STATUS_FAILED_${response.statusCode}",
      );
    } on TimeoutException {
      throw Exception("LIVE_STATUS_TIMEOUT");
    } catch (e) {
      throw Exception("LIVE_STATUS_ERROR: $e");
    }
  }

  // =========================================
  // 🔥 EXPLAINER SEEN
  // POST /api/v1/social/social-explainer/seen
  // =========================================
  static Future<Map<String, dynamic>> markExplainerSeen({
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/social/social-explainer/seen');

    try {
      final response = await http
          .post(
            url,
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10));

      final Map<String, dynamic> data = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {};

      if (response.statusCode == 200) {
        return data;
      }

      throw Exception(
        data["detail"] ??
            data["message"] ??
            "EXPLAINER_FAILED_${response.statusCode}",
      );
    } on TimeoutException {
      throw Exception("EXPLAINER_TIMEOUT");
    } catch (e) {
      throw Exception("EXPLAINER_ERROR: $e");
    }
  }
}