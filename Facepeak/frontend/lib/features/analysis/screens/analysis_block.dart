import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AnalysisBlock {
  static const String _baseUrl = 'http://192.168.88.100:8000';

  // =========================================================
  // ▶️ RUN PSL ANALYSIS (PREMIUM)
  // =========================================================
  static Future<Map<String, dynamic>> runPslAnalysis({
    required File imageFile,
    required String guestToken,
  }) async {

    // ============================
    // 1️⃣ START SESSION
    // ============================
    final startReq = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/api/v1/analysis/analyze/start'),
    );

    startReq.headers['X-Guest-Token'] = guestToken;

    startReq.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final startRes = await startReq.send();
    final startRaw = await startRes.stream.bytesToString();

    if (startRes.statusCode != 200) {
      throw Exception('START_ANALYSIS_FAILED');
    }

    final startBody = jsonDecode(startRaw);
    final analysisId = startBody['analysis_id'];

    if (analysisId == null) {
      throw Exception('INVALID_ANALYSIS_ID');
    }

    // ============================
    // 2️⃣ RUN PSL
    // ============================
    final pslRes = await http.post(
      Uri.parse('$_baseUrl/api/v1/analysis/analyze/$analysisId/psl'),
      headers: {
        'X-Guest-Token': guestToken,
      },
    );

    if (pslRes.statusCode != 200) {
      throw Exception('PSL_ANALYSIS_FAILED');
    }

    final pslBody = jsonDecode(pslRes.body);

    if (pslBody['status'] != 'success') {
      throw Exception('INVALID_PSL_RESPONSE');
    }

    final psl = pslBody['psl'] as Map<String, dynamic>;

    return {
      "status": "success",
      "analysis_id": analysisId,
      "psl": {
        "psl_score": psl["psl_score"],
        "tier": psl["tier"],
        "percentile": psl["percentile"],
        "confidence": psl["confidence"],
      },
    };
  }

  // =========================================================
  // ▶️ RUN FREE PSL ANALYSIS
  // =========================================================
  static Future<Map<String, dynamic>> runFreePslAnalysis({
  required File imageFile,
  required String guestToken,
}) async {

  // ============================
  // 1️⃣ START SESSION
  // ============================
  final startReq = http.MultipartRequest(
    'POST',
    Uri.parse('$_baseUrl/api/v1/analysis/analyze/start'),
  );

  startReq.headers['X-Guest-Token'] = guestToken;

  startReq.files.add(
    await http.MultipartFile.fromPath(
      'image',
      imageFile.path,
      contentType: MediaType('image', 'jpeg'),
    ),
  );

  final startRes = await startReq.send();
  final startRaw = await startRes.stream.bytesToString();

  if (startRes.statusCode != 200) {
    try {
      final err = jsonDecode(startRaw);
      throw Exception(err["detail"] ?? "START_ANALYSIS_FAILED");
    } catch (_) {
      throw Exception("START_ANALYSIS_FAILED");
    }
  }

  final startBody = jsonDecode(startRaw);
  final analysisId = startBody['analysis_id'];

  if (analysisId == null) {
    throw Exception('INVALID_ANALYSIS_ID');
  }

  // ============================
  // 2️⃣ RUN FREE PSL
  // ============================
  final res = await http.post(
    Uri.parse('$_baseUrl/api/v1/analysis/analyze/$analysisId/free'),
    headers: {
      'X-Guest-Token': guestToken,
    },
  );

  if (res.statusCode != 200) {
    try {
      final err = jsonDecode(res.body);
      throw Exception(err["detail"] ?? "FREE_PSL_ANALYSIS_FAILED");
    } catch (_) {
      throw Exception("FREE_PSL_ANALYSIS_FAILED");
    }
  }

  final body = jsonDecode(res.body);

  if (body['status'] != 'success') {
    throw Exception(body["reason"] ?? "INVALID_FREE_PSL_RESPONSE");
  }

  return {
    "status": "success",
    "analysis_id": analysisId,
    "psl": body["psl"],
    "strengths": body["strengths"] ?? [],
    "limits": body["limits"] ?? [],
  };
}

  // =========================================================
  // ▶️ RUN APPEAL ANALYSIS
  // BACKEND BROJI SUCCESS (used / max)
  // FRONTEND ODLUČUJE LOCK
  // =========================================================
  static Future<Map<String, dynamic>> runAppealAnalysis({
    required File imageFile,
    required String guestToken,
  }) async {

    print('');
    print('🔥🔥🔥 APPEAL ANALYSIS START 🔥🔥🔥');
    print('🔥 guestToken = $guestToken');
    print('🔥 imagePath  = ${imageFile.path}');
    print('');

    final startReq = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/api/v1/analysis/analyze/start'),
    );

    startReq.headers['X-Guest-Token'] = guestToken;

    startReq.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    print('🚀 Sending /start request...');
    final startRes = await startReq.send();

    final startRaw = await startRes.stream.bytesToString();
    print('📥 /start RAW RESPONSE = $startRaw');

    final startBody = jsonDecode(startRaw);
    final analysisId = startBody['analysis_id'];

    print('✅ analysisId = $analysisId');
    print('');

    print('🚀 Calling /appeal...');
    final res = await http.post(
      Uri.parse('$_baseUrl/api/v1/analysis/analyze/$analysisId/appeal'),
      headers: {'X-Guest-Token': guestToken},
    );

    print('📡 STATUS CODE = ${res.statusCode}');
    print('📥 RAW BODY    = ${res.body}');
    print('');

    if (res.statusCode != 200) {
      print('❌ APPEAL_ANALYSIS_FAILED');
      throw Exception('APPEAL_ANALYSIS_FAILED');
    }

    final body = jsonDecode(res.body);

    print('💥💥💥 PARSED RESPONSE 💥💥💥');
    print('💥 appeal = ${body["appeal"]}');
    print('💥 used   = ${body["used"]}');
    print('💥 limit  = ${body["limit"]}');
    print('💥 cached = ${body["cached"]}');
    print('💥💥💥💥💥💥💥💥💥💥💥💥💥');
    print('');

    final used = body["used"];
    final max = body["limit"] ?? body["max"] ?? 2;

    print('✅ FINAL VALUES → used=$used / max=$max');
    print('🔥🔥🔥 APPEAL ANALYSIS END 🔥🔥🔥');
    print('');

    return {
      "status": "success",
      "appeal": body["appeal"],
      "used": used,
      "max": max,
      "analysis_id": analysisId,
    };
  }
}