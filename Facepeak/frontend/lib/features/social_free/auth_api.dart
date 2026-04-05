import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApi {
  static const String _baseUrl = 'http://192.168.88.100:8000';

  // =========================================================
  // ▶️ GET ME (🔥 SNAPSHOT)
  // =========================================================
  static Future<Map<String, dynamic>> getMe(String token) async {
    final url = Uri.parse('$_baseUrl/api/v1/auth/me'); // 🔥 FIXED

    final res = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    print("🔥 GET ME URL: $url");
    print("🔥 STATUS: ${res.statusCode}");
    print("🔥 BODY: ${res.body}");

    if (res.statusCode != 200) {
      throw Exception("GET_ME_FAILED_${res.statusCode}");
    }

    final data = jsonDecode(res.body);

    if (data == null || data is! Map<String, dynamic>) {
      throw Exception("INVALID_USER_DATA");
    }

    return data; // 🔥 flat snapshot
  }
}