import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SocialMatchApi {
  static const String baseUrl = 'http://192.168.88.100:8000';

  static Map<String, dynamic> _decodeMap(String body) {
    if (body.isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    } catch (_) {
      return {
        "detail": body,
      };
    }
  }

  static Future<Map<String, dynamic>> sendMatchRequest({
    required String token,
    required int targetUserId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/v1/social/users/$targetUserId/match-request',
    );

    try {
      debugPrint("❌❌❌ SOCIAL_MATCH_API sendMatchRequest START");
      debugPrint("❌❌❌ SOCIAL_MATCH_API targetUserId = $targetUserId");

      final res = await http
          .post(
            url,
            headers: {
              "Authorization": "Bearer ${token.trim()}",
              "Accept": "application/json",
              "Content-Type": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint("❌❌❌ SOCIAL_MATCH_API status = ${res.statusCode}");
      debugPrint("❌❌❌ SOCIAL_MATCH_API body = ${res.body}");

      final data = _decodeMap(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return data;
      }

      throw Exception(
        data["detail"] ??
            data["message"] ??
            "MATCH_REQUEST_FAILED_${res.statusCode}",
      );
    } on TimeoutException {
      throw Exception("MATCH_REQUEST_TIMEOUT");
    } catch (e) {
      debugPrint("❌❌❌ SOCIAL_MATCH_API ERROR = $e");
      throw Exception("MATCH_REQUEST_ERROR: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> getIncomingMatchRequests({
    required String token,
    int limit = 30,
    int offset = 0,
  }) async {
    final safeLimit = limit.clamp(1, 50);
    final safeOffset = offset < 0 ? 0 : offset;

    final url = Uri.parse(
      '$baseUrl/api/v1/social/match-requests/incoming?limit=$safeLimit&offset=$safeOffset',
    );

    try {
      debugPrint("❌❌❌ SOCIAL_MATCH_API getIncoming START");

      final res = await http
          .get(
            url,
            headers: {
              "Authorization": "Bearer ${token.trim()}",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint("❌❌❌ SOCIAL_MATCH_API incoming status = ${res.statusCode}");
      debugPrint("❌❌❌ SOCIAL_MATCH_API incoming body = ${res.body}");

      final data = _decodeMap(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final raw = data["requests"];
        if (raw is List) {
          return raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        return [];
      }

      throw Exception(
        data["detail"] ??
            data["message"] ??
            "GET_MATCH_REQUESTS_FAILED_${res.statusCode}",
      );
    } on TimeoutException {
      throw Exception("GET_MATCH_REQUESTS_TIMEOUT");
    } catch (e) {
      debugPrint("❌❌❌ SOCIAL_MATCH_API getIncoming ERROR = $e");
      throw Exception("GET_MATCH_REQUESTS_ERROR: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> getMatches({
    required String token,
    int limit = 30,
    int offset = 0,
  }) async {
    final safeLimit = limit.clamp(1, 50);
    final safeOffset = offset < 0 ? 0 : offset;

    final url = Uri.parse(
      '$baseUrl/api/v1/social/matches?limit=$safeLimit&offset=$safeOffset',
    );

    try {
      debugPrint("❌❌❌ SOCIAL_MATCH_API getMatches START");

      final res = await http
          .get(
            url,
            headers: {
              "Authorization": "Bearer ${token.trim()}",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint("❌❌❌ SOCIAL_MATCH_API matches status = ${res.statusCode}");
      debugPrint("❌❌❌ SOCIAL_MATCH_API matches body = ${res.body}");

      final data = _decodeMap(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final raw = data["matches"];
        if (raw is List) {
          return raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        return [];
      }

      throw Exception(
        data["detail"] ??
            data["message"] ??
            "GET_MATCHES_FAILED_${res.statusCode}",
      );
    } on TimeoutException {
      throw Exception("GET_MATCHES_TIMEOUT");
    } catch (e) {
      debugPrint("❌❌❌ SOCIAL_MATCH_API getMatches ERROR = $e");
      throw Exception("GET_MATCHES_ERROR: $e");
    }
  }

  static Future<Map<String, dynamic>> acceptMatchRequest({
    required String token,
    required int requestId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/v1/social/match-requests/$requestId/accept',
    );

    try {
      debugPrint("❌❌❌ SOCIAL_MATCH_API accept START requestId=$requestId");

      final res = await http
          .post(
            url,
            headers: {
              "Authorization": "Bearer ${token.trim()}",
              "Accept": "application/json",
              "Content-Type": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint("❌❌❌ SOCIAL_MATCH_API accept status = ${res.statusCode}");
      debugPrint("❌❌❌ SOCIAL_MATCH_API accept body = ${res.body}");

      final data = _decodeMap(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return data;
      }

      throw Exception(
        data["detail"] ??
            data["message"] ??
            "ACCEPT_MATCH_FAILED_${res.statusCode}",
      );
    } on TimeoutException {
      throw Exception("ACCEPT_MATCH_TIMEOUT");
    } catch (e) {
      debugPrint("❌❌❌ SOCIAL_MATCH_API accept ERROR = $e");
      throw Exception("ACCEPT_MATCH_ERROR: $e");
    }
  }

  static Future<Map<String, dynamic>> rejectMatchRequest({
    required String token,
    required int requestId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/v1/social/match-requests/$requestId/reject',
    );

    try {
      debugPrint("❌❌❌ SOCIAL_MATCH_API reject START requestId=$requestId");

      final res = await http
          .post(
            url,
            headers: {
              "Authorization": "Bearer ${token.trim()}",
              "Accept": "application/json",
              "Content-Type": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint("❌❌❌ SOCIAL_MATCH_API reject status = ${res.statusCode}");
      debugPrint("❌❌❌ SOCIAL_MATCH_API reject body = ${res.body}");

      final data = _decodeMap(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return data;
      }

      throw Exception(
        data["detail"] ??
            data["message"] ??
            "REJECT_MATCH_FAILED_${res.statusCode}",
      );
    } on TimeoutException {
      throw Exception("REJECT_MATCH_TIMEOUT");
    } catch (e) {
      debugPrint("❌❌❌ SOCIAL_MATCH_API reject ERROR = $e");
      throw Exception("REJECT_MATCH_ERROR: $e");
    }
  }

  static Future<Map<String, dynamic>> cancelMatchRequest({
    required String token,
    required int requestId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/v1/social/match-requests/$requestId',
    );

    try {
      debugPrint("❌❌❌ SOCIAL_MATCH_API cancel START requestId=$requestId");

      final res = await http
          .delete(
            url,
            headers: {
              "Authorization": "Bearer ${token.trim()}",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint("❌❌❌ SOCIAL_MATCH_API cancel status = ${res.statusCode}");
      debugPrint("❌❌❌ SOCIAL_MATCH_API cancel body = ${res.body}");

      final data = _decodeMap(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return data;
      }

      throw Exception(
        data["detail"] ??
            data["message"] ??
            "CANCEL_MATCH_FAILED_${res.statusCode}",
      );
    } on TimeoutException {
      throw Exception("CANCEL_MATCH_TIMEOUT");
    } catch (e) {
      debugPrint("❌❌❌ SOCIAL_MATCH_API cancel ERROR = $e");
      throw Exception("CANCEL_MATCH_ERROR: $e");
    }
  }
}