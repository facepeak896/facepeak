import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AnalysisBlock {
  static const String _baseUrl = 'http://192.168.88.100:8000';

  // =========================================================
  // ▶️ RUN PSL ANALYSIS (PREMIUM)
  // =========================================================
  // =========================================================
// ▶️ RUN WELCOME PSL ANALYSIS
// Backend is source of truth.
// If backend has cached result, backend returns it here.
// =========================================================
static Future<Map<String, dynamic>> runPslAnalysis({
  required File imageFile,
  required String accessToken,
}) async {
  print('');
  print('🔥🔥🔥 WELCOME PSL ANALYSIS START 🔥🔥🔥');
  print('🔥 imagePath = ${imageFile.path}');
  print('');

  final startReq = http.MultipartRequest(
    'POST',
    Uri.parse('$_baseUrl/api/v1/analysis/analyze/start'),
  );

  startReq.headers['Authorization'] = 'Bearer $accessToken';

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

  print('📡 /start STATUS CODE = ${startRes.statusCode}');
  print('📥 /start RAW BODY    = $startRaw');
  print('');

  if (startRes.statusCode != 200) {
    String detail = 'START_ANALYSIS_FAILED';

    try {
      final err = jsonDecode(startRaw);
      detail = err['detail']?.toString() ?? detail;
    } catch (_) {}

    print('❌ START FAILED → $detail');

    if (startRes.statusCode == 401 || startRes.statusCode == 403) {
      throw Exception('auth_required');
    }

    if (startRes.statusCode == 422) {
      throw Exception('no_face_detected');
    }

    if (startRes.statusCode == 429) {
      throw Exception('rate_limited');
    }

    throw Exception(detail);
  }

  final startBody = jsonDecode(startRaw);
  final analysisId = startBody['analysis_id'];

  if (analysisId == null) {
    print('❌ INVALID_ANALYSIS_ID');
    throw Exception('INVALID_ANALYSIS_ID');
  }

  print('✅ analysisId = $analysisId');
  print('');

  final endpoint =
      '$_baseUrl/api/v1/analysis/analyze/$analysisId/psl';

  print('🚀 Calling WELCOME /psl...');
  print('🔥 endpoint = $endpoint');

  final pslRes = await http.post(
    Uri.parse(endpoint),
    headers: {
      'Authorization': 'Bearer $accessToken',
    },
  );

  print('📡 /psl STATUS CODE = ${pslRes.statusCode}');
  print('📥 /psl RAW BODY    = ${pslRes.body}');
  print('');

  if (pslRes.statusCode != 200) {
    String detail = 'PSL_ANALYSIS_FAILED';

    try {
      final err = jsonDecode(pslRes.body);
      detail = err['detail']?.toString() ?? detail;
    } catch (_) {}

    print('❌ WELCOME PSL FAILED → $detail');

    if (pslRes.statusCode == 401 || pslRes.statusCode == 403) {
      throw Exception('auth_required');
    }

    if (pslRes.statusCode == 422) {
      throw Exception('no_face_detected');
    }

    if (pslRes.statusCode == 429) {
      throw Exception('rate_limited');
    }

    throw Exception(detail);
  }

  final body = jsonDecode(pslRes.body);

  final status = body['status'];

  print('🔥 PARSED STATUS = $status');
  print('🔥 PARSED PSL = ${body["psl"]}');
  print('🔥 STRENGTHS = ${body["strengths"]}');
  print('🔥 LIMITS = ${body["limits"]}');
  print('🔥 IS_CACHED = ${body["is_cached"]}');
  print('');

  if (status == 'rate_limited') {
    return {
      'status': 'rate_limited',
      'analysis_id': analysisId,
      'locked': body['locked'] ?? true,
      'cooldown_until': body['cooldown_until'],
    };
  }

  if (status != 'success') {
    throw Exception(
      body['reason'] ?? 'INVALID_WELCOME_PSL_RESPONSE',
    );
  }

  final psl = body['psl'] ?? {};

  print('💥💥💥 WELCOME PSL PARSED RESPONSE 💥💥💥');
  print('💥 psl_score  = ${psl["psl_score"]}');
  print('💥 tier       = ${psl["tier"]}');
  print('💥 percentile = ${psl["percentile"]}');
  print('💥 cached     = ${body["is_cached"] == true}');
  print('💥💥💥💥💥💥💥💥💥💥💥💥💥');
  print('');

  print('🔥🔥🔥 WELCOME PSL ANALYSIS END 🔥🔥🔥');
  print('');

  return {
    'status': 'success',
    'analysis_id': analysisId,
    'is_cached': body['is_cached'] == true,
    'psl': {
      'psl_score': psl['psl_score'],
      'tier': psl['tier'],
      'percentile': psl['percentile'],
      'confidence': psl['confidence'],
      'stable_score_float': psl['stable_score_float'],
      'raw_expected': psl['raw_expected'],
      'bonus_applied': psl['bonus_applied'],
    },
    'strengths': body['strengths'] ?? [],
    'limits': body['limits'] ?? [],
  };
}

  // =========================================================
  // ▶️ RUN HOME FREE PSL ANALYSIS
  // =========================================================
  static Future<Map<String, dynamic>> runFreePslAnalysis({
    required File imageFile,
    required String guestToken,
    String? accessToken,
  }) async {
    print('');
    print('X_HOME_FREE_PSL_START');
    print('X_GUEST_TOKEN = $guestToken');
    print('X_IMAGE_PATH = ${imageFile.path}');
    print('');

    final startReq = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/api/v1/analysis/analyze/start'),
    );

    startReq.headers['X-Guest-Token'] = guestToken;

    if (accessToken != null && accessToken.isNotEmpty) {
      startReq.headers['Authorization'] = 'Bearer $accessToken';
    }

    startReq.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    print('X_START_REQUEST_SEND');

    final startRes = await startReq.send();

    final startRaw = await startRes.stream.bytesToString();

    print('X_START_STATUS = ${startRes.statusCode}');
    print('X_START_BODY = $startRaw');
    print('');

    if (startRes.statusCode != 200) {
      String detail = 'START_ANALYSIS_FAILED';

      try {
        final err = jsonDecode(startRaw);
        detail = err['detail']?.toString() ?? detail;
      } catch (_) {}

      print('X_START_FAILED = $detail');

      // ✅ FIX: normalize 422 -> no_face_detected
      if (startRes.statusCode == 422) {
        throw Exception('no_face_detected');
      }

      throw Exception(detail);
    }

    final startBody = jsonDecode(startRaw);

    final analysisId = startBody['analysis_id'];

    if (analysisId == null) {
      print('X_INVALID_ANALYSIS_ID');
      throw Exception('INVALID_ANALYSIS_ID');
    }

    print('X_ANALYSIS_ID = $analysisId');
    print('');

    final endpoint =
        '$_baseUrl/api/v1/home-free/analyze/$analysisId/psl';

    print('X_HOME_FREE_PSL_ENDPOINT = $endpoint');

    final res = await http.post(
      Uri.parse(endpoint),
      headers: {
        'X-Guest-Token': guestToken,
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      },
    );

    print('X_HOME_FREE_PSL_STATUS = ${res.statusCode}');
    print('X_HOME_FREE_PSL_BODY = ${res.body}');
    print('');

    if (res.statusCode != 200) {
      String detail = 'HOME_FREE_PSL_ANALYSIS_FAILED';

      try {
        final err = jsonDecode(res.body);
        detail = err['detail']?.toString() ?? detail;
      } catch (_) {}

      print('X_HOME_FREE_PSL_FAILED = $detail');

      // ✅ FIX: normalize 422 -> no_face_detected
      if (res.statusCode == 422) {
        throw Exception('no_face_detected');
      }

      throw Exception(detail);
    }

    final body = jsonDecode(res.body);

    final status = body['status'];

    print('X_PARSED_STATUS = $status');
    print('X_PARSED_PSL = ${body["psl"]}');
    print('X_STRENGTHS = ${body["strengths"]}');
    print('X_LIMITS = ${body["limits"]}');
    print('X_LOCKED = ${body["locked"]}');
    print('X_COOLDOWN_UNTIL = ${body["cooldown_until"]}');
    print(
      'X_ATTEMPTS = ${body["free_attempts_used"]}/${body["free_attempts_limit"]}',
    );
    print('');

    if (status == 'rate_limited') {
      print('X_RATE_LIMITED');
      print('');

      return {
        'status': 'rate_limited',
        'analysis_id': analysisId,
        'locked': body['locked'] ?? true,
        'cooldown_until': body['cooldown_until'],
        'free_attempts_used': body['free_attempts_used'] ?? 1,
        'free_attempts_limit': body['free_attempts_limit'] ?? 1,
      };
    }

    if (status != 'success') {
      print('X_INVALID_RESPONSE');

      throw Exception(
        body['reason'] ?? 'INVALID_HOME_FREE_PSL_RESPONSE',
      );
    }

    final psl = body['psl'] ?? {};

    print('X_FINAL_SCORE = ${psl["psl_score"]}');
    print('X_FINAL_TIER = ${psl["tier"]}');
    print('X_FINAL_LOCK = ${body["locked"]}');
    print('X_HOME_FREE_PSL_END');
    print('');

    return {
      'status': 'success',
      'analysis_id': analysisId,
      'psl': {
        'psl_score': psl['psl_score'],
        'tier': psl['tier'],
        'percentile': psl['percentile'],
        'confidence': psl['confidence'],
        'stable_score_float': psl['stable_score_float'],
        'raw_expected': psl['raw_expected'],
        'bonus_applied': psl['bonus_applied'],
      },
      'strengths': body['strengths'] ?? [],
      'limits': body['limits'] ?? [],
      'locked': body['locked'] ?? true,
      'cooldown_until': body['cooldown_until'],
      'free_attempts_used': body['free_attempts_used'] ?? 1,
      'free_attempts_limit': body['free_attempts_limit'] ?? 1,
    };
  }
}