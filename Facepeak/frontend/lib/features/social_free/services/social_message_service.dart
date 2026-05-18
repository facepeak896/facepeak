import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/features/social_free/social_features/social_api.dart';
import 'package:frontend/features/social_free/social_features/social_auth_guard.dart';
import 'package:frontend/features/social_free/social_features/social_message_api.dart';

class SocialMessageService {
  static Future<String> _token() async {
    final token = await SocialAuthGuard.ensureBackendToken();

    debugPrint("💬 MESSAGE_SERVICE token exists = ${token != null}");

    if (token == null || token.trim().isEmpty) {
      debugPrint("💬 MESSAGE_SERVICE NO VALID TOKEN");
      throw Exception("NO_VALID_TOKEN");
    }

    return token.trim();
  }

  // 🔥 NEW: used by WebSocket service
  static Future<String> getAuthTokenForSocket() async {
    return _token();
  }

  static List<Map<String, dynamic>> _itemsFromPage(Map<String, dynamic> page) {
    final raw = page["items"];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  static Future<Map<String, dynamic>> sendMessageRequest({
    required int targetUserId,
  }) async {
    final token = await _token();

    return SocialMessageApi.sendMessageRequest(
      token: token,
      targetUserId: targetUserId,
    );
  }

  static Future<List<Map<String, dynamic>>> getIncomingRequests({
    int limit = 30,
    int offset = 0,
  }) async {
    final token = await _token();

    return SocialMessageApi.getIncomingMessageRequests(
      token: token,
      limit: limit,
      offset: offset,
    );
  }

  static Future<Map<String, dynamic>> acceptRequest({
    required int requestId,
  }) async {
    final token = await _token();

    return SocialMessageApi.acceptMessageRequest(
      token: token,
      requestId: requestId,
    );
  }

  static Future<Map<String, dynamic>> rejectRequest({
    required int requestId,
  }) async {
    final token = await _token();

    return SocialMessageApi.rejectMessageRequest(
      token: token,
      requestId: requestId,
    );
  }

  static Future<Map<String, dynamic>> cancelRequest({
    required int requestId,
  }) async {
    final token = await _token();

    return SocialMessageApi.cancelMessageRequest(
      token: token,
      requestId: requestId,
    );
  }

  static Future<Map<String, dynamic>> getConversationsPage({
    int limit = 20,
    int offset = 0,
  }) async {
    final token = await _token();

    final page = await SocialMessageApi.getConversationsPage(
      token: token,
      limit: limit,
      offset: offset,
    );

    debugPrint(
      "💬 MESSAGE_SERVICE conversations page count = ${_itemsFromPage(page).length}",
    );

    return page;
  }

  static Future<List<Map<String, dynamic>>> getConversations({
    int limit = 20,
    int offset = 0,
  }) async {
    final page = await getConversationsPage(
      limit: limit,
      offset: offset,
    );

    return _itemsFromPage(page);
  }

  static Future<Map<String, dynamic>> getMessagesPage({
    required int conversationId,
    int limit = 40,
    int? beforeMessageId,
  }) async {
    final token = await _token();

    final page = await SocialMessageApi.getMessagesPage(
      token: token,
      conversationId: conversationId,
      limit: limit,
      beforeMessageId: beforeMessageId,
    );

    debugPrint(
      "💬 MESSAGE_SERVICE messages page count = ${_itemsFromPage(page).length}",
    );

    return page;
  }
  static Future<Map<String, dynamic>> getDailyMessageLimitStatus() async {
  final token = await _token();

  final res = await http.get(
    Uri.parse("${SocialApi.baseUrl}/api/v1/social/messages/rate-limit/status"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  if (res.statusCode != 200) {
    try {
      final body = jsonDecode(res.body);
      throw Exception(
        body["detail"] ?? "MESSAGE_RATE_LIMIT_STATUS_FAILED",
      );
    } catch (_) {
      throw Exception("MESSAGE_RATE_LIMIT_STATUS_FAILED");
    }
  }

  final body = jsonDecode(res.body);

  return Map<String, dynamic>.from(body);
}

  static Future<List<Map<String, dynamic>>> getMessages({
    required int conversationId,
    int limit = 40,
    int? beforeMessageId,
  }) async {
    final page = await getMessagesPage(
      conversationId: conversationId,
      limit: limit,
      beforeMessageId: beforeMessageId,
    );

    return _itemsFromPage(page);
  }

  static Future<Map<String, dynamic>> sendMessage({
    required int conversationId,
    required String body,
  }) async {
    final clean = body.trim();

    if (clean.isEmpty) {
      throw Exception("EMPTY_MESSAGE");
    }

    final token = await _token();

    return SocialMessageApi.sendMessage(
      token: token,
      conversationId: conversationId,
      body: clean,
    );
  }

  static Future<Map<String, dynamic>> markSeen({
    required int conversationId,
  }) async {
    final token = await _token();

    return SocialMessageApi.markConversationSeen(
      token: token,
      conversationId: conversationId,
    );
  }

  static Future<Map<String, dynamic>> blockUser({
    required int targetUserId,
  }) async {
    final token = await _token();

    return SocialMessageApi.blockUser(
      token: token,
      targetUserId: targetUserId,
    );
  }

  static Future<Map<String, dynamic>> unblockUser({
    required int targetUserId,
  }) async {
    final token = await _token();

    return SocialMessageApi.unblockUser(
      token: token,
      targetUserId: targetUserId,
    );
  }

  static Future<Map<String, dynamic>> removeConversation({
    required int conversationId,
  }) async {
    final token = await _token();

    return SocialMessageApi.removeConversation(
      token: token,
      conversationId: conversationId,
    );
  }

  static Future<Map<String, dynamic>> reportUser({
    required int targetUserId,
    required String reason,
    String? details,
  }) async {
    final cleanReason = reason.trim();
    final cleanDetails = details?.trim();

    if (cleanReason.isEmpty) {
      throw Exception("EMPTY_REPORT_REASON");
    }

    final token = await _token();

    return SocialMessageApi.reportUser(
      token: token,
      targetUserId: targetUserId,
      reason: cleanReason,
      details: cleanDetails?.isEmpty == true ? null : cleanDetails,
    );
  }
}