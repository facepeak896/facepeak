import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SocialMessageApi {
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

  static Future<Map<String, dynamic>> sendMessageRequest({
    required String token,
    required int targetUserId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/v1/social/users/$targetUserId/message-request',
    );

    try {
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API sendRequest START");
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API targetUserId = $targetUserId");

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

      debugPrint("❌❌❌ SOCIAL_MESSAGE_API sendRequest status = ${res.statusCode}");
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API sendRequest body = ${res.body}");

      final data = _decodeMap(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return data;
      }

      throw Exception(
        data["detail"] ??
            data["message"] ??
            "MESSAGE_REQUEST_FAILED_${res.statusCode}",
      );
    } on TimeoutException {
      throw Exception("MESSAGE_REQUEST_TIMEOUT");
    } catch (e) {
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API sendRequest ERROR = $e");
      throw Exception("MESSAGE_REQUEST_ERROR: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> getIncomingMessageRequests({
    required String token,
    int limit = 30,
    int offset = 0,
  }) async {
    final safeLimit = limit.clamp(1, 50);
    final safeOffset = offset < 0 ? 0 : offset;

    final url = Uri.parse(
      '$baseUrl/api/v1/social/message-requests/incoming?limit=$safeLimit&offset=$safeOffset',
    );

    try {
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API getIncoming START");

      final res = await http
          .get(
            url,
            headers: {
              "Authorization": "Bearer ${token.trim()}",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint("❌❌❌ SOCIAL_MESSAGE_API incoming status = ${res.statusCode}");
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API incoming body = ${res.body}");

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
            "GET_MESSAGE_REQUESTS_FAILED_${res.statusCode}",
      );
    } on TimeoutException {
      throw Exception("GET_MESSAGE_REQUESTS_TIMEOUT");
    } catch (e) {
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API getIncoming ERROR = $e");
      throw Exception("GET_MESSAGE_REQUESTS_ERROR: $e");
    }
  }

  static Future<Map<String, dynamic>> acceptMessageRequest({
    required String token,
    required int requestId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/v1/social/message-requests/$requestId/accept',
    );

    try {
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API accept START requestId=$requestId");

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

      debugPrint("❌❌❌ SOCIAL_MESSAGE_API accept status = ${res.statusCode}");
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API accept body = ${res.body}");

      final data = _decodeMap(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return data;
      }

      throw Exception(
        data["detail"] ??
            data["message"] ??
            "ACCEPT_MESSAGE_REQUEST_FAILED_${res.statusCode}",
      );
    } on TimeoutException {
      throw Exception("ACCEPT_MESSAGE_REQUEST_TIMEOUT");
    } catch (e) {
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API accept ERROR = $e");
      throw Exception("ACCEPT_MESSAGE_REQUEST_ERROR: $e");
    }
  }

  static Future<Map<String, dynamic>> rejectMessageRequest({
    required String token,
    required int requestId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/v1/social/message-requests/$requestId/reject',
    );

    try {
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API reject START requestId=$requestId");

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

      debugPrint("❌❌❌ SOCIAL_MESSAGE_API reject status = ${res.statusCode}");
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API reject body = ${res.body}");

      final data = _decodeMap(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return data;
      }

      throw Exception(
        data["detail"] ??
            data["message"] ??
            "REJECT_MESSAGE_REQUEST_FAILED_${res.statusCode}",
      );
    } on TimeoutException {
      throw Exception("REJECT_MESSAGE_REQUEST_TIMEOUT");
    } catch (e) {
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API reject ERROR = $e");
      throw Exception("REJECT_MESSAGE_REQUEST_ERROR: $e");
    }
  }

  static Future<Map<String, dynamic>> cancelMessageRequest({
    required String token,
    required int requestId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/v1/social/message-requests/$requestId',
    );

    try {
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API cancel START requestId=$requestId");

      final res = await http
          .delete(
            url,
            headers: {
              "Authorization": "Bearer ${token.trim()}",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint("❌❌❌ SOCIAL_MESSAGE_API cancel status = ${res.statusCode}");
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API cancel body = ${res.body}");

      final data = _decodeMap(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return data;
      }

      throw Exception(
        data["detail"] ??
            data["message"] ??
            "CANCEL_MESSAGE_REQUEST_FAILED_${res.statusCode}",
      );
    } on TimeoutException {
      throw Exception("CANCEL_MESSAGE_REQUEST_TIMEOUT");
    } catch (e) {
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API cancel ERROR = $e");
      throw Exception("CANCEL_MESSAGE_REQUEST_ERROR: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> getConversations({
    required String token,
    int limit = 30,
    int offset = 0,
  }) async {
    final safeLimit = limit.clamp(1, 50);
    final safeOffset = offset < 0 ? 0 : offset;

    final url = Uri.parse(
      '$baseUrl/api/v1/social/conversations?limit=$safeLimit&offset=$safeOffset',
    );

    try {
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API getConversations START");

      final res = await http
          .get(
            url,
            headers: {
              "Authorization": "Bearer ${token.trim()}",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint("❌❌❌ SOCIAL_MESSAGE_API conversations status = ${res.statusCode}");
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API conversations body = ${res.body}");

      final data = _decodeMap(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final raw = data["conversations"];
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
            "GET_CONVERSATIONS_FAILED_${res.statusCode}",
      );
    } on TimeoutException {
      throw Exception("GET_CONVERSATIONS_TIMEOUT");
    } catch (e) {
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API getConversations ERROR = $e");
      throw Exception("GET_CONVERSATIONS_ERROR: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> getMessages({
    required String token,
    required int conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    final safeLimit = limit.clamp(1, 100);
    final safeOffset = offset < 0 ? 0 : offset;

    final url = Uri.parse(
      '$baseUrl/api/v1/social/conversations/$conversationId/messages?limit=$safeLimit&offset=$safeOffset',
    );

    try {
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API getMessages START conversationId=$conversationId");

      final res = await http
          .get(
            url,
            headers: {
              "Authorization": "Bearer ${token.trim()}",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint("❌❌❌ SOCIAL_MESSAGE_API messages status = ${res.statusCode}");
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API messages body = ${res.body}");

      final data = _decodeMap(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final raw = data["messages"];
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
            "GET_MESSAGES_FAILED_${res.statusCode}",
      );
    } on TimeoutException {
      throw Exception("GET_MESSAGES_TIMEOUT");
    } catch (e) {
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API getMessages ERROR = $e");
      throw Exception("GET_MESSAGES_ERROR: $e");
    }
  }

  static Future<Map<String, dynamic>> sendMessage({
    required String token,
    required int conversationId,
    required String body,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/v1/social/conversations/$conversationId/messages',
    );

    try {
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API sendMessage START conversationId=$conversationId");

      final res = await http
          .post(
            url,
            headers: {
              "Authorization": "Bearer ${token.trim()}",
              "Accept": "application/json",
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "body": body,
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint("❌❌❌ SOCIAL_MESSAGE_API sendMessage status = ${res.statusCode}");
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API sendMessage body = ${res.body}");

      final data = _decodeMap(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final raw = data["message"];
        if (raw is Map) {
          return Map<String, dynamic>.from(raw);
        }
        return data;
      }

      throw Exception(
        data["detail"] ??
            data["message"] ??
            "SEND_MESSAGE_FAILED_${res.statusCode}",
      );
    } on TimeoutException {
      throw Exception("SEND_MESSAGE_TIMEOUT");
    } catch (e) {
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API sendMessage ERROR = $e");
      throw Exception("SEND_MESSAGE_ERROR: $e");
    }
  }
  static Future<Map<String, dynamic>> getMessagesPage({
  required String token,
  required int conversationId,
  int limit = 40,
  int? beforeMessageId,
}) async {
  final safeLimit = limit.clamp(1, 100);

  final query = beforeMessageId == null
      ? 'limit=$safeLimit'
      : 'limit=$safeLimit&before_message_id=$beforeMessageId';

  final url = Uri.parse(
    '$baseUrl/api/v1/social/conversations/$conversationId/messages?$query',
  );

  try {
    final res = await http
        .get(
          url,
          headers: {
            "Authorization": "Bearer ${token.trim()}",
            "Accept": "application/json",
          },
        )
        .timeout(const Duration(seconds: 10));

    final data = _decodeMap(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final raw = data["messages"];

      final items = raw is List
          ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];

      int? oldestId;

      for (final msg in items) {
        final id = msg["id"];
        if (id is int) {
          oldestId = oldestId == null ? id : (id < oldestId ? id : oldestId);
        }
      }

      return {
        "items": items,
        "has_more": items.length == safeLimit,
        "oldest_message_id": oldestId,
      };
    }

    throw Exception(
      data["detail"] ?? data["message"] ?? "GET_MESSAGES_FAILED_${res.statusCode}",
    );
  } on TimeoutException {
    throw Exception("GET_MESSAGES_TIMEOUT");
  } catch (e) {
    throw Exception("GET_MESSAGES_ERROR: $e");
  }
}

  static Future<Map<String, dynamic>> markConversationSeen({
    required String token,
    required int conversationId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/v1/social/conversations/$conversationId/seen',
    );

    try {
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API seen START conversationId=$conversationId");

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

      debugPrint("❌❌❌ SOCIAL_MESSAGE_API seen status = ${res.statusCode}");
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API seen body = ${res.body}");

      final data = _decodeMap(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return data;
      }

      throw Exception(
        data["detail"] ??
            data["message"] ??
            "SEEN_FAILED_${res.statusCode}",
      );
    } on TimeoutException {
      throw Exception("SEEN_TIMEOUT");
    } catch (e) {
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API seen ERROR = $e");
      throw Exception("SEEN_ERROR: $e");
    }
  }
  static Future<Map<String, dynamic>> getConversationsPage({
  required String token,
  int limit = 20,
  int offset = 0,
}) async {
  final safeLimit = limit.clamp(1, 50);
  final safeOffset = offset < 0 ? 0 : offset;

  final url = Uri.parse(
    '$baseUrl/api/v1/social/conversations?limit=$safeLimit&offset=$safeOffset',
  );

  try {
    final res = await http
        .get(
          url,
          headers: {
            "Authorization": "Bearer ${token.trim()}",
            "Accept": "application/json",
          },
        )
        .timeout(const Duration(seconds: 10));

    final data = _decodeMap(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final raw = data["conversations"];

      final items = raw is List
          ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];

      return {
        "items": items,
        "has_more": items.length == safeLimit,
        "next_offset": safeOffset + items.length,
      };
    }

    throw Exception(
      data["detail"] ?? data["message"] ?? "GET_CONVERSATIONS_FAILED_${res.statusCode}",
    );
  } on TimeoutException {
    throw Exception("GET_CONVERSATIONS_TIMEOUT");
  } catch (e) {
    throw Exception("GET_CONVERSATIONS_ERROR: $e");
  }
}

  static Future<Map<String, dynamic>> blockUser({
    required String token,
    required int targetUserId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/v1/social/users/$targetUserId/block',
    );

    try {
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API block START target=$targetUserId");

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

      debugPrint("❌❌❌ SOCIAL_MESSAGE_API block status = ${res.statusCode}");
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API block body = ${res.body}");

      final data = _decodeMap(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return data;
      }

      throw Exception(
        data["detail"] ??
            data["message"] ??
            "BLOCK_FAILED_${res.statusCode}",
      );
    } on TimeoutException {
      throw Exception("BLOCK_TIMEOUT");
    } catch (e) {
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API block ERROR = $e");
      throw Exception("BLOCK_ERROR: $e");
    }
  }
  static Future<Map<String, dynamic>> unblockUser({
  required String token,
  required int targetUserId,
}) async {
  final url = Uri.parse(
    '$baseUrl/api/v1/social/users/$targetUserId/block',
  );

  try {
    debugPrint("❌❌❌ SOCIAL_MESSAGE_API unblock START target=$targetUserId");

    final res = await http
        .delete(
          url,
          headers: {
            "Authorization": "Bearer ${token.trim()}",
            "Accept": "application/json",
          },
        )
        .timeout(const Duration(seconds: 10));

    debugPrint("❌❌❌ SOCIAL_MESSAGE_API unblock status = ${res.statusCode}");
    debugPrint("❌❌❌ SOCIAL_MESSAGE_API unblock body = ${res.body}");

    final data = _decodeMap(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }

    throw Exception(
      data["detail"] ?? data["message"] ?? "UNBLOCK_FAILED_${res.statusCode}",
    );
  } on TimeoutException {
    throw Exception("UNBLOCK_TIMEOUT");
  } catch (e) {
    debugPrint("❌❌❌ SOCIAL_MESSAGE_API unblock ERROR = $e");
    throw Exception("UNBLOCK_ERROR: $e");
  }
}

static Future<Map<String, dynamic>> removeConversation({
  required String token,
  required int conversationId,
}) async {
  final url = Uri.parse(
    '$baseUrl/api/v1/social/conversations/$conversationId',
  );

  try {
    debugPrint(
      "❌❌❌ SOCIAL_MESSAGE_API removeConversation START conversationId=$conversationId",
    );

    final res = await http
        .delete(
          url,
          headers: {
            "Authorization": "Bearer ${token.trim()}",
            "Accept": "application/json",
          },
        )
        .timeout(const Duration(seconds: 10));

    debugPrint("❌❌❌ SOCIAL_MESSAGE_API removeConversation status = ${res.statusCode}");
    debugPrint("❌❌❌ SOCIAL_MESSAGE_API removeConversation body = ${res.body}");

    final data = _decodeMap(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }

    throw Exception(
      data["detail"] ??
          data["message"] ??
          "REMOVE_CONVERSATION_FAILED_${res.statusCode}",
    );
  } on TimeoutException {
    throw Exception("REMOVE_CONVERSATION_TIMEOUT");
  } catch (e) {
    debugPrint("❌❌❌ SOCIAL_MESSAGE_API removeConversation ERROR = $e");
    throw Exception("REMOVE_CONVERSATION_ERROR: $e");
  }
}

  static Future<Map<String, dynamic>> reportUser({
    required String token,
    required int targetUserId,
    required String reason,
    String? details,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/v1/social/users/$targetUserId/report',
    );

    try {
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API report START target=$targetUserId");

      final res = await http
          .post(
            url,
            headers: {
              "Authorization": "Bearer ${token.trim()}",
              "Accept": "application/json",
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "reason": reason,
              "details": details,
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint("❌❌❌ SOCIAL_MESSAGE_API report status = ${res.statusCode}");
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API report body = ${res.body}");

      final data = _decodeMap(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return data;
      }

      throw Exception(
        data["detail"] ??
            data["message"] ??
            "REPORT_FAILED_${res.statusCode}",
      );
    } on TimeoutException {
      throw Exception("REPORT_TIMEOUT");
    } catch (e) {
      debugPrint("❌❌❌ SOCIAL_MESSAGE_API report ERROR = $e");
      throw Exception("REPORT_ERROR: $e");
    }
  }
}