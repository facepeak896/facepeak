import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApi {
  static const String _baseUrl = 'http://192.168.88.100:8000';

  // =========================================================
  // ▶️ SIGNUP
  // =========================================================
  static Future<Map<String, dynamic>> signup({
    required String email,
    required String username,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/api/v1/auth/signup'),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "username": username,
        "password": password,
      }),
    );

    print("SIGNUP STATUS: ${res.statusCode}");
    print("SIGNUP BODY: ${res.body}");

    if (res.statusCode != 200 && res.statusCode != 201) {
      try {
        final err = jsonDecode(res.body);
        throw Exception(err["detail"] ?? err["message"] ?? "SIGNUP_FAILED");
      } catch (_) {
        throw Exception("SIGNUP_FAILED");
      }
    }

    final body = jsonDecode(res.body);

    return body;
  }

  // =========================================================
  // ▶️ LOGIN
  // =========================================================
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/api/v1/auth/login'),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    print("LOGIN STATUS: ${res.statusCode}");
    print("LOGIN BODY: ${res.body}");

    if (res.statusCode != 200) {
      try {
        final err = jsonDecode(res.body);
        throw Exception(err["detail"] ?? err["message"] ?? "LOGIN_FAILED");
      } catch (_) {
        throw Exception("LOGIN_FAILED");
      }
    }

    final body = jsonDecode(res.body);

    final token = body["access_token"];

    if (token == null) {
      throw Exception("NO_TOKEN_RETURNED");
    }

    return body;
  }

  // =========================================================
  // ▶️ GET ME (🔥 FIXED ROUTE)
  // =========================================================
  static Future<Map<String, dynamic>> getMe(String token) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/api/v1/profile/me'), // ✅ FIX
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    print("GET ME STATUS: ${res.statusCode}");
    print("GET ME BODY: ${res.body}");

    if (res.statusCode != 200) {
      throw Exception("GET_ME_FAILED_${res.statusCode}");
    }

    final body = jsonDecode(res.body);

    return body;
  }

  // =========================================================
  // ▶️ VERIFY EMAIL
  // =========================================================
  static Future<Map<String, dynamic>> verifyEmail({
    required String token,
  }) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/api/v1/auth/verify-email?token=$token'),
    );

    if (res.statusCode != 200) {
      throw Exception("VERIFY_FAILED");
    }

    return jsonDecode(res.body);
  }

  // =========================================================
  // ▶️ REQUEST RESET
  // =========================================================
  static Future<void> requestReset({
    required String email,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/api/v1/auth/forgot-password'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    if (res.statusCode != 200) {
      throw Exception("RESET_REQUEST_FAILED");
    }
  }

  // =========================================================
  // ▶️ RESET PASSWORD
  // =========================================================
  static Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/api/v1/auth/reset-password'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "token": token,
        "new_password": newPassword,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("RESET_FAILED");
    }
  }
}