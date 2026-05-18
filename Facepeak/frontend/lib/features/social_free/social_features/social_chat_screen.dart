import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:frontend/features/social_free/services/social_message_service.dart';
import 'package:frontend/features/social_free/social_features/social_api.dart';
import 'package:frontend/features/social_free/social_features/social_chat_socket_service.dart';
import 'package:frontend/features/social_free/social_features/search_main_screen.dart';
import 'widgets/social_chat_widgets.dart';

class SocialChatScreen extends StatefulWidget {
  final int conversationId;
  final int userId;
  final String username;
  final String imageUrl;
  final bool activeNow;
  final String? lastActiveAt;

  const SocialChatScreen({
    super.key,
    required this.conversationId,
    required this.userId,
    required this.username,
    required this.imageUrl,
    this.activeNow = false,
    this.lastActiveAt,
  });

  @override
  State<SocialChatScreen> createState() => _SocialChatScreenState();
}

class _SocialChatScreenState extends State<SocialChatScreen> {
  static const int _pageLimit = 45;

  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();

  StreamSubscription<Map<String, dynamic>>? _socketSub;
  Timer? _seenDebounce;
  Timer? _rateLimitResetTimer;
  Timer? _activeTicker;

  bool _loading = true;
  bool _loadingOlder = false;
  bool _hasMoreOlder = true;
  bool _sending = false;
  bool _blocked = false;
  bool _nearBottom = true;
  bool _inputHasText = false;
  bool _focused = false;
  bool _showIncomingBanner = false;

  bool _rateLimitReady = false;
  bool _rateLimitLoading = false;
  int _dailyLimit = 15;
  int _dailyRemaining = 15;
  DateTime? _dailyResetAt;

  bool _activeNow = false;
  String? _liveLastActiveAt;
  String _incomingBannerText = "";

  bool _removedResult = false;
  bool _blockedResult = false;
  bool _unblockedResult = false;
  int? _lastOlderCursorRequested;

  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _dmLastMessageOverride;

  @override
  void initState() {
    super.initState();

    _activeNow = widget.activeNow;
    _liveLastActiveAt = widget.lastActiveAt;

    _activeTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });

    _scroll.addListener(_onScroll);

    _focus.addListener(() {
      if (!mounted) return;

      setState(() => _focused = _focus.hasFocus);

      if (_focus.hasFocus) {
        _jumpBottom(animated: true);

        Future.delayed(const Duration(milliseconds: 120), () {
          if (mounted) _jumpBottom(animated: false);
        });

        Future.delayed(const Duration(milliseconds: 280), () {
          if (mounted) _jumpBottom(animated: true);
        });

        Future.delayed(const Duration(milliseconds: 450), () {
          if (mounted) _jumpBottom(animated: false);
        });
      }
    });

    _ctrl.addListener(_onTextChanged);

    _loadBackendRateLimit();
    _loadInitial();
    _initSocket();
    _markSeenDebounced();
  }

  @override
void dispose() {
  _socketSub?.cancel();
  _seenDebounce?.cancel();
  _activeTicker?.cancel();
  _rateLimitResetTimer?.cancel();

  _ctrl.dispose();
  _focus.dispose();
  _scroll.dispose();

  super.dispose();
}

  Future<void> _loadBackendRateLimit({bool silent = true}) async {
    if (_rateLimitLoading) return;

    _rateLimitLoading = true;

    try {
      final data = await SocialMessageService.getDailyMessageLimitStatus();

      if (!mounted) return;

      _applyRateLimitStatus(data);
    } catch (e) {
      debugPrint("❌ CHAT rate limit status ERROR = $e");

      if (!mounted) return;

      if (!silent) {
        _toast("Could not check message limit. Please try again.");
      }

      setState(() {
        _rateLimitReady = true;
      });
    } finally {
      _rateLimitLoading = false;
    }
  }

  void _applyRateLimitStatus(Map<String, dynamic> data) {
  final limitRaw = data["limit"] ?? data["daily_limit"] ?? 15;

  final remainingRaw = data["remaining"] ??
      data["messages_left"] ??
      data["left"] ??
      data["available"] ??
      15;

  final resetRaw = data["reset_at"] ??
      data["resetAt"] ??
      data["window_reset_at"] ??
      data["next_available_at"];

  final limit = limitRaw is num
      ? limitRaw.toInt()
      : int.tryParse(limitRaw.toString()) ?? 15;

  final remaining = remainingRaw is num
      ? remainingRaw.toInt()
      : int.tryParse(remainingRaw.toString()) ?? limit;

  final resetAt =
      resetRaw == null ? null : DateTime.tryParse(resetRaw.toString());

  setState(() {
    _dailyLimit = limit.clamp(1, 999);
    _dailyRemaining = remaining.clamp(0, _dailyLimit);
    _dailyResetAt = resetAt?.toLocal();
    _rateLimitReady = true;
  });

  _startRateLimitResetTimer();
  }
  void _startRateLimitResetTimer() {
  _rateLimitResetTimer?.cancel();

  final resetAt = _dailyResetAt;

  if (resetAt == null) return;

  final delay = resetAt.difference(DateTime.now());

  if (delay <= Duration.zero) {
    unawaited(_loadBackendRateLimit(silent: true));
    return;
  }

  _rateLimitResetTimer = Timer(delay, () async {
    if (!mounted) return;

    await _loadBackendRateLimit(silent: true);

    if (!mounted) return;

    setState(() {});
  });
}

bool get _dailyMessageLimitReached {
  return _rateLimitReady && _dailyRemaining <= 0;
}


  String _dailyLimitResetText() {
    final resetAt = _dailyResetAt;
    if (resetAt == null) return "soon";

    final remaining = resetAt.difference(DateTime.now());

    if (remaining <= Duration.zero) return "now";

    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60);

    if (h > 0) return "${h}h ${m.toString().padLeft(2, '0')}m";
    return "${m.toString().padLeft(2, '0')}m";
  }

  String _dailyLimitToastText() {
    return "Daily message limit reached. You can send more messages in ${_dailyLimitResetText()}.";
  }

  Future<bool> _checkBackendMessageAllowed() async {
    await _loadBackendRateLimit(silent: false);

    if (_dailyMessageLimitReached) {
      HapticFeedback.mediumImpact();
      _toast(_dailyLimitToastText());
      return false;
    }

    return true;
  }

  void _softConsumeOneMessageLocally() {
    if (!_rateLimitReady) return;

    setState(() {
      _dailyRemaining = (_dailyRemaining - 1).clamp(0, _dailyLimit);
    });
  }

  Map<String, dynamic>? _latestMessageForDm() {
    if (_dmLastMessageOverride != null) {
      return Map<String, dynamic>.from(_dmLastMessageOverride!);
    }

    if (_messages.isEmpty) return null;

    return Map<String, dynamic>.from(_messages.last);
  }

  Map<String, dynamic>? _popResult() {
    if (_removedResult) return {"removed": true};
    if (_blockedResult) return {"blocked": true};
    if (_unblockedResult) return {"unblocked": true};

    final last = _latestMessageForDm();

    if (last != null) {
      return {
        "last_message": last,
        "updated_at": last["created_at"] ?? DateTime.now().toIso8601String(),
      };
    }

    return null;
  }

  void _leave() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, _popResult());
    }
  }

  Future<void> _initSocket() async {
    await SocialChatSocketService.instance.connect();

    _socketSub = SocialChatSocketService.instance.events.listen((event) {
      if (!mounted) return;
      _handleSocketEvent(event);
    });
  }

  void _handleSocketEvent(Map<String, dynamic> event) {
    final type = event["type"]?.toString();

    if (!_eventBelongsToThisConversation(event)) {
      if (type == "user_presence") _applyPresence(event);
      return;
    }

    switch (type) {
      case "new_message":
      case "receive_message":
        final raw = event["message"];
        if (raw is Map) _applyIncomingMessage(Map<String, dynamic>.from(raw));
        break;
      case "message_sent":
        final raw = event["message"];
        if (raw is Map) _applyConfirmedMessage(Map<String, dynamic>.from(raw));
        break;
      case "delivered":
        _applyDelivered(event);
        break;
      case "seen":
        _applySeen(event);
        break;
      case "user_presence":
        _applyPresence(event);
        break;
    }
  }

  bool _eventBelongsToThisConversation(Map<String, dynamic> event) {
    final cid = (event["conversation_id"] as num?)?.toInt();
    if (cid != null) return cid == widget.conversationId;

    final raw = event["message"];
    if (raw is Map) {
      final midCid = (raw["conversation_id"] as num?)?.toInt();
      return midCid == widget.conversationId;
    }

    return false;
  }

  void _applyIncomingMessage(Map<String, dynamic> msg) {
    final id = _msgId(msg);
    if (id != null && _messages.any((m) => _msgId(m) == id)) return;

    setState(() {
      _messages = _mergeMessages(_messages, [
        {...msg, "is_me": false}
      ]);
    });

    if (id != null && id > 0) {
      SocialChatSocketService.instance.sendDeliveredAck(messageId: id);
    }

    SocialChatSocketService.instance.sendSeen(
      conversationId: widget.conversationId,
    );

    _markSeenDebounced();

    if (_nearBottom) {
      _jumpBottom();
    } else {
      _showIncoming(msg);
    }
  }

  void _applyConfirmedMessage(Map<String, dynamic> real) {
    final realMessage = {
      ...real,
      "is_me": true,
      "_pending": false,
    };

    _dmLastMessageOverride = realMessage;

    setState(() {
      _messages = _mergeMessages(_messages, [realMessage]);
    });

    _jumpBottom();
  }

  void _openProfile() {
    _focus.unfocus();
    HapticFeedback.selectionClick();

    if (widget.userId <= 0) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchMainScreen(userId: widget.userId),
      ),
    );
  }

  void _applyDelivered(Map<String, dynamic> event) {
    final messageId = (event["message_id"] as num?)?.toInt();
    final deliveredAt = _safeIso(event["delivered_at"]);

    if (messageId == null) return;

    setState(() {
      _messages = _messages.map((m) {
        if (_msgId(m) != messageId) return m;
        if (!_isMine(m)) return m;

        final updated = {
          ...m,
          "delivered_at": deliveredAt,
          "_pending": false,
        };

        _dmLastMessageOverride = updated;
        return updated;
      }).toList();
    });
  }

  void _applySeen(Map<String, dynamic> event) {
    final messageId = (event["message_id"] as num?)?.toInt();
    final seenAt = _safeIso(event["seen_at"]);

    setState(() {
      _messages = _messages.map((m) {
        if (!_isMine(m)) return m;
        if (messageId != null && _msgId(m) != messageId) return m;

        final updated = {
          ...m,
          "seen_at": seenAt,
          "_pending": false,
        };

        _dmLastMessageOverride = updated;
        return updated;
      }).toList();
    });
  }

  void _applyPresence(Map<String, dynamic> event) {
    final userId = (event["user_id"] as num?)?.toInt();
    if (userId != null && userId != widget.userId) return;

    setState(() {
      _activeNow = event["active_now"] == true || event["online"] == true;
      _liveLastActiveAt =
          event["last_active_at"]?.toString() ?? _liveLastActiveAt;
    });
  }

  String _safeIso(dynamic raw) {
    final s = raw?.toString();
    if (s == null || s.isEmpty || s == "null") {
      return DateTime.now().toIso8601String();
    }
    return s;
  }

  void _onTextChanged() {
    final has = _ctrl.text.trim().isNotEmpty;
    if (has != _inputHasText && mounted) {
      setState(() => _inputHasText = has);
    }
  }

  String _imageUrl() {
    final raw = widget.imageUrl.trim();
    if (raw.isEmpty) return "";
    if (raw.startsWith("http://") || raw.startsWith("https://")) return raw;
    if (raw.startsWith("/")) return "${SocialApi.baseUrl}$raw";
    return raw;
  }

  int? _msgId(Map<String, dynamic> m) {
    final id = m["id"];
    if (id is num) return id.toInt();
    return null;
  }

  String? _clientId(Map<String, dynamic> m) {
    final v = m["client_id"] ?? m["temp_id"] ?? m["_client_id"];
    final s = v?.toString();
    if (s == null || s.isEmpty || s == "null") return null;
    return s;
  }

  bool _isMine(Map<String, dynamic> m) => m["is_me"] == true;

  int? get _oldestMessageId {
    final ids =
        _messages.map(_msgId).whereType<int>().where((e) => e > 0).toList();
    if (ids.isEmpty) return null;
    ids.sort();
    return ids.first;
  }

  bool get _hasRealMessages {
    return _messages.any((m) {
      final id = _msgId(m);
      return id != null && id > 0;
    });
  }

  int? get _lastMineMessageId {
    for (final m in _messages.reversed) {
      if (_isMine(m)) return _msgId(m);
    }
    return null;
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;

    final pos = _scroll.position;
    final newNearBottom = pos.pixels > pos.maxScrollExtent - 190;

    if (newNearBottom != _nearBottom && mounted) {
      setState(() => _nearBottom = newNearBottom);
    }

    if (_loadingOlder) return;
    if (!_hasMoreOlder) return;
    if (!_hasRealMessages) return;

    if (pos.pixels < 220) {
      _loadOlder();
    }
  }

  Future<void> _loadInitial() async {
    try {
      final page = await SocialMessageService.getMessagesPage(
        conversationId: widget.conversationId,
        limit: _pageLimit,
      );

      final items = _items(page);

      if (!mounted) return;

      setState(() {
        _messages = _sortMessages(items);
        _hasMoreOlder = page["has_more"] == true;
        _lastOlderCursorRequested = null;
        _loading = false;
      });

      _jumpBottom(animated: false);
    } catch (e) {
      debugPrint("❌ CHAT initial ERROR = $e");

      if (e.toString().contains("USER_BLOCKED")) {
        if (!mounted) return;
        setState(() {
          _blocked = true;
          _blockedResult = true;
          _loading = false;
        });
        return;
      }

      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadOlder() async {
    final before = _oldestMessageId;

    if (before == null) return;
    if (_loadingOlder) return;
    if (!_hasMoreOlder) return;
    if (!_hasRealMessages) return;

    if (_lastOlderCursorRequested == before) {
      return;
    }

    _lastOlderCursorRequested = before;

    setState(() => _loadingOlder = true);

    final oldPixels = _scroll.hasClients ? _scroll.position.pixels : 0;
    final oldMax = _scroll.hasClients ? _scroll.position.maxScrollExtent : 0;
    final oldOldest = _oldestMessageId;

    try {
      final page = await SocialMessageService.getMessagesPage(
        conversationId: widget.conversationId,
        limit: _pageLimit,
        beforeMessageId: before,
      );

      final older = _items(page);

      if (!mounted) return;

      if (older.isEmpty) {
        setState(() {
          _hasMoreOlder = false;
        });
        return;
      }

      final merged = _mergeMessages(older, _messages);

      setState(() {
        _messages = merged;
        _hasMoreOlder = page["has_more"] == true;
      });

      final newOldest = _oldestMessageId;

      if (newOldest == oldOldest) {
        if (!mounted) return;
        setState(() {
          _hasMoreOlder = false;
        });
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;

        final newMax = _scroll.position.maxScrollExtent;
        final nextOffset = oldPixels + (newMax - oldMax);

        _scroll.jumpTo(
          nextOffset.clamp(
            _scroll.position.minScrollExtent,
            _scroll.position.maxScrollExtent,
          ),
        );
      });
    } catch (e) {
      debugPrint("❌ CHAT older ERROR = $e");
      _lastOlderCursorRequested = null;
    } finally {
      if (mounted) {
        setState(() => _loadingOlder = false);
      }
    }
  }

  List<Map<String, dynamic>> _items(Map<String, dynamic> page) {
    final raw = page["items"];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  List<Map<String, dynamic>> _sortMessages(List<Map<String, dynamic>> list) {
    final copy = [...list];
    copy.sort((a, b) {
      final ai = _msgId(a) ?? 999999999;
      final bi = _msgId(b) ?? 999999999;
      return ai.compareTo(bi);
    });
    return copy;
  }

  List<Map<String, dynamic>> _mergeMessages(
    List<Map<String, dynamic>> base,
    List<Map<String, dynamic>> incoming,
  ) {
    final byId = <int, Map<String, dynamic>>{};
    final pending = <Map<String, dynamic>>[];

    for (final raw in [...base, ...incoming]) {
      final m = Map<String, dynamic>.from(raw);
      final id = _msgId(m);
      final cid = _clientId(m);

      if (id != null && id > 0) {
        byId[id] = {...?byId[id], ...m};

        if (cid != null) {
          pending.removeWhere((p) => _clientId(p) == cid);
        }
      } else {
        final exists = pending.any((p) {
          final pc = _clientId(p);
          if (pc != null && pc == cid) return true;
          return _msgId(p) == id;
        });

        if (!exists) pending.add(m);
      }
    }

    return _sortMessages([...byId.values, ...pending]);
  }

  Future<void> _send() async {
    if (_blocked) {
      _toast("You have been blocked");
      return;
    }

    final body = _ctrl.text.trim();
    if (body.isEmpty || _sending) return;

    final allowed = await _checkBackendMessageAllowed();
    if (!allowed) return;

    HapticFeedback.lightImpact();

    final now = DateTime.now().toIso8601String();
    final clientId = "client_${DateTime.now().microsecondsSinceEpoch}";
    final tempId = -DateTime.now().microsecondsSinceEpoch;

    final tempMessage = {
      "id": tempId,
      "client_id": clientId,
      "_client_id": clientId,
      "body": body,
      "is_me": true,
      "_pending": true,
      "created_at": now,
    };

    _dmLastMessageOverride = tempMessage;

    setState(() {
      _sending = true;
      _messages.add(tempMessage);
      _ctrl.clear();
      _inputHasText = false;
    });

    _jumpBottom();

    try {
      final sent = await SocialMessageService.sendMessage(
        conversationId: widget.conversationId,
        body: body,
      );

      final realMessage = {
        ...sent,
        "is_me": true,
        "client_id": sent["client_id"] ?? clientId,
        "_client_id": clientId,
        "_pending": false,
        "created_at": sent["created_at"] ?? now,
      };

      final rateLimit = sent["rate_limit"];
      if (rateLimit is Map) {
        _applyRateLimitStatus(Map<String, dynamic>.from(rateLimit));
      } else {
        _softConsumeOneMessageLocally();
        unawaited(_loadBackendRateLimit());
      }

      _dmLastMessageOverride = realMessage;

      if (!mounted) return;

      setState(() {
        _messages.removeWhere((m) => m["id"] == tempId);
        _messages = _mergeMessages(_messages, [realMessage]);
      });

      _jumpBottom();
    } catch (e) {
      debugPrint("❌ CHAT send ERROR = $e");

      if (!mounted) return;

      final error = e.toString().toLowerCase();

      if (error.contains("daily_message_limit_reached") ||
          error.contains("message_limit") ||
          error.contains("rate_limit") ||
          error.contains("429")) {
        setState(() {
          _messages.removeWhere((m) => m["id"] == tempId);
        });

        _dmLastMessageOverride = null;

        await _loadBackendRateLimit(silent: true);

        if (!mounted) return;

        _toast(_dailyLimitToastText());
        return;
      }

      if (e.toString().contains("USER_BLOCKED")) {
        setState(() {
          _blocked = true;
          _blockedResult = true;
          _messages.removeWhere((m) => m["id"] == tempId);
        });

        _dmLastMessageOverride = null;
        _toast("You have been blocked");
        return;
      }

      final failedMessage = {
        ...tempMessage,
        "_failed": true,
        "_pending": false,
      };

      _dmLastMessageOverride = failedMessage;

      setState(() {
        _messages = _messages.map((m) {
          if (m["id"] != tempId) return m;
          return failedMessage;
        }).toList();
      });

      _toast("Message failed. Tap to retry.");
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _retryMessage(Map<String, dynamic> m) async {
    if (_blocked) {
      _toast("You have been blocked");
      return;
    }

    final body = (m["body"] ?? "").toString().trim();
    if (body.isEmpty) return;

    setState(() {
      _messages.removeWhere((x) => x["id"] == m["id"]);
      _ctrl.text = body;
    });

    await _send();
  }

  void _markSeenDebounced() {
    _seenDebounce?.cancel();
    _seenDebounce = Timer(const Duration(milliseconds: 650), () async {
      if (_blocked) return;

      try {
        await SocialMessageService.markSeen(
          conversationId: widget.conversationId,
        );
      } catch (e) {
        debugPrint("❌ CHAT seen ERROR = $e");
      }
    });
  }

  void _jumpBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;

      final target = _scroll.position.maxScrollExtent;

      if (!animated) {
        _scroll.jumpTo(target);
        return;
      }

      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );

      Future.delayed(const Duration(milliseconds: 120), () {
        if (!_scroll.hasClients || !mounted) return;

        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    });
  }

  void _showIncoming(Map<String, dynamic> msg) {
    final body = (msg["body"] ?? "").toString().trim();

    setState(() {
      _incomingBannerText =
          body.isEmpty ? "New message from ${widget.username}" : body;
      _showIncomingBanner = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showIncomingBanner = false);
    });
  }

  ChatMessageStatus _statusType(Map<String, dynamic> m) {
    if (m["_failed"] == true) return ChatMessageStatus.failed;
    if (m["_pending"] == true) return ChatMessageStatus.sending;

    final seen = m["seen_at"];
    final delivered = m["delivered_at"];

    if (seen != null && seen.toString().trim().isNotEmpty) {
      return ChatMessageStatus.seen;
    }

    if (delivered != null && delivered.toString().trim().isNotEmpty) {
      return ChatMessageStatus.delivered;
    }

    return ChatMessageStatus.sent;
  }

  String _statusText(Map<String, dynamic> m) {
    final type = _statusType(m);

    switch (type) {
      case ChatMessageStatus.failed:
        return _blocked ? "You have been blocked" : "Tap to retry";
      case ChatMessageStatus.sending:
        return "Sending…";
      case ChatMessageStatus.seen:
        return "Seen ${_relativeShort(m["seen_at"])}";
      case ChatMessageStatus.delivered:
        return "Delivered ${_relativeShort(m["delivered_at"])}";
      case ChatMessageStatus.sent:
        return "Sent ${_relativeShort(m["created_at"])}";
    }
  }

  String _relativeShort(dynamic raw) {
    final dt = DateTime.tryParse(raw?.toString() ?? "");
    if (dt == null) return "now";

    final diff = DateTime.now().difference(dt.toLocal());

    if (diff.inSeconds < 45) return "now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";

    return "${dt.day}/${dt.month}";
  }

  String _lastActiveText() {
    if (_blocked) return "You have been blocked";

    final raw = _liveLastActiveAt;
    final dt = raw == null || raw.trim().isEmpty || raw == "null"
        ? null
        : DateTime.tryParse(raw);

    if (_activeNow) {
      if (dt != null) {
        final diff = DateTime.now().difference(dt.toLocal());

        if (diff.inMinutes > 3) {
          return "Recently active";
        }
      }

      return "Active now";
    }

    if (dt == null) return "Recently active";

    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    String two(int v) => v.toString().padLeft(2, "0");
    final time = "${two(local.hour)}:${two(local.minute)}";

    if (diff.inMinutes < 2) return "Active now";
    if (diff.inMinutes < 60) return "Active ${diff.inMinutes}m ago";
    if (diff.inHours < 24 && now.day == local.day) {
      return "Active today at $time";
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.day == local.day &&
        yesterday.month == local.month &&
        yesterday.year == local.year) {
      return "Active yesterday at $time";
    }

    if (diff.inDays < 365) {
      return "Active ${local.day}/${local.month} at $time";
    }

    return "Active ${local.day}/${local.month}/${local.year}";
  }

  Future<void> _removeChat() async {
    try {
      await SocialMessageService.removeConversation(
        conversationId: widget.conversationId,
      );

      if (!mounted) return;
      _removedResult = true;
      _leave();
    } catch (_) {
      if (mounted) _toast("Could not remove chat");
    }
  }

  Future<void> _blockUser() async {
    try {
      await SocialMessageService.blockUser(targetUserId: widget.userId);

      if (!mounted) return;

      setState(() {
        _blocked = true;
        _blockedResult = true;
        _unblockedResult = false;
      });

      Navigator.pop(context);
      _toast("${widget.username} blocked");
    } catch (_) {
      if (mounted) _toast("Could not block user");
    }
  }

  Future<void> _unblockUser() async {
    try {
      await SocialMessageService.unblockUser(targetUserId: widget.userId);

      if (!mounted) return;

      setState(() {
        _blocked = false;
        _unblockedResult = true;
        _blockedResult = false;
      });

      Navigator.pop(context);
      _toast("Chat unlocked");
    } catch (_) {
      if (mounted) _toast("Could not unblock user");
    }
  }

  Future<void> _reportUser(String reason) async {
    try {
      await SocialMessageService.reportUser(
        targetUserId: widget.userId,
        reason: reason,
      );

      if (!mounted) return;
      Navigator.pop(context);
      _toast("Report sent");
    } catch (_) {
      if (mounted) _toast("Could not report");
    }
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF111827),
      ),
    );
  }

  void _openAvatarPreview() {
    _focus.unfocus();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "avatar_preview",
      barrierColor: Colors.black.withOpacity(0.90),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, __) {
        return ChatAvatarPreview(
          imageUrl: _imageUrl(),
          onClose: () => Navigator.of(dialogContext).maybePop(),
        );
      },
    );
  }

  void _openActions() {
    _focus.unfocus();
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.58),
      builder: (_) {
        return ChatActionsSheet(
          username: widget.username,
          imageUrl: _imageUrl(),
          blocked: _blocked,
          onRemove: _removeChat,
          onBlock: _blockUser,
          onUnblock: _unblockUser,
          onReport: _openReportSheet,
        );
      },
    );
  }

  void _openReportSheet() {
    Navigator.pop(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.58),
      builder: (_) {
        return ChatReportSheet(
          onReport: _reportUser,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return WillPopScope(
      onWillPop: () async {
        _leave();
        return false;
      },
      child: Scaffold(
        backgroundColor: ChatUi.bg,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            const Positioned.fill(child: ChatBackground()),
            Column(
              children: [
                ChatTopBar(
                  username: widget.username,
                  imageUrl: _imageUrl(),
                  activeNow: _activeNow,
                  blocked: _blocked,
                  statusText: _lastActiveText(),
                  onBack: _leave,
                  onAvatarTap: _openAvatarPreview,
                  onHeaderTap: _openProfile,
                  onMenuTap: null,
                ),
                ChatBlockedBanner(visible: _blocked),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: ChatUi.gold2,
                          ),
                        )
                      : Stack(
                          children: [
                            _messages.isEmpty
                                ? ChatEmptyState(
                                    username: widget.username,
                                    imageUrl: _imageUrl(),
                                  )
                                : ListView.builder(
                                    controller: _scroll,
                                    keyboardDismissBehavior:
                                        ScrollViewKeyboardDismissBehavior.onDrag,
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      14,
                                      16,
                                      32,
                                    ),
                                    itemCount: _messages.length +
                                        (_loadingOlder ? 1 : 0),
                                    itemBuilder: (_, i) {
                                      if (_loadingOlder && i == 0) {
                                        return const ChatOlderLoader();
                                      }

                                      final index = _loadingOlder ? i - 1 : i;
                                      final msg = _messages[index];

                                      final prev = index > 0
                                          ? _messages[index - 1]
                                          : null;

                                      final next =
                                          index < _messages.length - 1
                                              ? _messages[index + 1]
                                              : null;

                                      final isMe = _isMine(msg);
                                      final prevSame =
                                          prev != null && _isMine(prev) == isMe;
                                      final nextSame =
                                          next != null && _isMine(next) == isMe;

                                      final showStatus = isMe &&
                                          _msgId(msg) == _lastMineMessageId;

                                      return ChatBubble(
                                        body: (msg["body"] ?? "").toString(),
                                        isMe: isMe,
                                        failed: msg["_failed"] == true,
                                        pending: msg["_pending"] == true,
                                        previousSameSender: prevSame,
                                        nextSameSender: nextSame,
                                        showStatus: showStatus,
                                        statusText: _statusText(msg),
                                        statusType: _statusType(msg),
                                        onRetry: () => _retryMessage(msg),
                                      );
                                    },
                                  ),
                            ChatIncomingBanner(
                              visible: _showIncomingBanner,
                              text: _incomingBannerText,
                              imageUrl: _imageUrl(),
                              onTap: () {
                                setState(() => _showIncomingBanner = false);
                                _jumpBottom();
                              },
                            ),
                            if (!_nearBottom && _messages.isNotEmpty)
                              ChatJumpButton(
                                onTap: _jumpBottom,
                              ),
                          ],
                        ),
                ),
                if (_rateLimitReady && _dailyRemaining <= 3)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _dailyMessageLimitReached
                            ? const Color(0xFF7F1D1D).withOpacity(0.92)
                            : const Color(0xFF111827).withOpacity(0.92),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _dailyMessageLimitReached
                              ? Colors.redAccent.withOpacity(0.35)
                              : ChatUi.gold2.withOpacity(0.24),
                        ),
                      ),
                      child: Text(
                        _dailyMessageLimitReached
                            ? "Daily message limit reached • resets in ${_dailyLimitResetText()}"
                            : "$_dailyRemaining messages left today",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                AnimatedPadding(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: ChatInputBar(
                    controller: _ctrl,
                    focusNode: _focus,
                    username: widget.username,
                    blocked: _blocked || _dailyMessageLimitReached,
                    sending: _sending || _rateLimitLoading,
                    focused: _focused,
                    hasText: _inputHasText,
                    onSend: _send,
                    onBlockedTap: () {
                      if (_dailyMessageLimitReached) {
                        _toast(_dailyLimitToastText());
                        return;
                      }

                      _toast("You have been blocked");
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}