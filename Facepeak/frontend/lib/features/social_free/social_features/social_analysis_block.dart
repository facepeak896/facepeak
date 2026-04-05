import 'dart:convert';
import 'package:http/http.dart' as http;

class AnalysisBlock {
  static const String _baseUrl = 'http://192.168.88.100:8000';

  // =========================================================
  // 🔥 PSL ANALYSIS
  // =========================================================
  static Future<Map<String, dynamic>> analyzePSL({
    required String analysisId,
    required String guestToken,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/api/v1/analysis/$analysisId/psl'),
      headers: {
        "Content-Type": "application/json",
        "x-guest-token": guestToken,
      },
    );

    if (res.statusCode != 200) {
      try {
        final err = jsonDecode(res.body);
        throw Exception(err["detail"] ?? "PSL_FAILED");
      } catch (_) {
        throw Exception("PSL_FAILED");
      }
    }

    final body = jsonDecode(res.body);

    final psl = body["psl"];

    return {
      "score": psl["psl_score"],
      "tier": psl["tier"],
      "percentile": psl["percentile"],
      "confidence": psl["confidence"],
    };
  }
}