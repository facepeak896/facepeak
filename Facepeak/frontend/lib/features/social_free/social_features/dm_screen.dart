import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:frontend/features/social_free/services/dm_engagement_service.dart';
import 'package:frontend/features/social_free/services/social_match_service.dart';
import 'package:frontend/features/social_free/services/social_message_service.dart';
import 'package:frontend/features/social_free/social_features/social_api.dart';
import 'package:frontend/features/social_free/social_features/social_chat_screen.dart';
import 'package:frontend/features/social_free/social_features/social_chat_socket_service.dart';

import 'widgets/dm_screen_widgets.dart';

class DmScreen extends StatefulWidget {
  const DmScreen({super.key});

  @override
  State<DmScreen> createState() => _DmScreenState();
}

class _DmScreenState extends State<DmScreen> {
  static const int _conversationLimit = 20;

  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _searchFocus = FocusNode();

  Timer? _poller;
  Timer? _pulseTimer;
  Timer? _reconcileTimer;
  int? _activeConversationId;
  StreamSubscription<Map<String, dynamic>>? _socketSub;

  bool _loading = true;
  bool _silentLoading = false;
  bool _loadingMoreConversations = false;
  bool _hasMoreConversations = true;

  int _nextConversationOffset = 0;
  int? _recentPulseConversationId;
  int? _lastConversationOffsetRequested;
  String _query = "";

  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _matches = [];
  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();

    _scrollCtrl.addListener(_onScroll);

    _searchFocus.addListener(() {
      if (!mounted) return;
      setState(() {});
      if (_searchFocus.hasFocus) HapticFeedback.selectionClick();
    });

    _load();
    _initSocket();

    // WebSocket is primary. Polling is only fallback.
    _poller = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!mounted || _silentLoading) return;
      _load(silent: true, preserveMissingConversations: true);
    });
  }

  @override
  void dispose() {
    _poller?.cancel();
    _pulseTimer?.cancel();
    _reconcileTimer?.cancel();
    _socketSub?.cancel();
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  bool get _hasAnyContent =>
      _requests.isNotEmpty || _matches.isNotEmpty || _conversations.isNotEmpty;

  int get _unreadCount => DmEngagementService.unreadCount(_conversations);

  Map<String, dynamic>? get _latestUnreadConversation {
    for (final c in _conversations) {
      if (_isUnread(c)) return c;
    }
    return null;
  }

  int? _conversationId(Map<String, dynamic> c) {
    return (c["conversation_id"] as num?)?.toInt();
  }
  int? _requestId(Map<String, dynamic> r) {
  return (r["request_id"] as num?)?.toInt() ??
      (r["message_request_id"] as num?)?.toInt() ??
      (r["id"] as num?)?.toInt();
}

  int? _userId(Map<String, dynamic> c) {
    return (c["user_id"] as num?)?.toInt() ?? (c["id"] as num?)?.toInt();
  }

  Map<String, dynamic>? _lastMap(Map<String, dynamic> c) {
    final last = c["last_message"];
    if (last is Map) return Map<String, dynamic>.from(last);
    return null;
  }

  String _name(Map<String, dynamic> u) {
    final raw = (u["username"] ?? u["display_name"] ?? u["name"] ?? "User")
        .toString()
        .trim();
    return raw.isEmpty ? "User" : raw;
  }

  String _image(Map<String, dynamic> u) {
    final raw =
        (u["profile_image_url"] ?? u["image"] ?? u["local_image_path"] ?? "")
            .toString()
            .trim();

    if (raw.isEmpty) return "";
    if (raw.startsWith("http://") || raw.startsWith("https://")) return raw;
    if (raw.startsWith("/")) return "${SocialApi.baseUrl}$raw";
    return raw;
  }

  bool _isBlockedConversation(Map<String, dynamic> c) {
    return c["is_blocked"] == true ||
        c["blocked"] == true ||
        c["blocked_by_me"] == true;
  }

  bool _isUnread(Map<String, dynamic> c) {
    if (_isBlockedConversation(c)) return false;

    final last = _lastMap(c);
    if (last == null) return false;

    final isMine = last["is_me"] == true;
    final seen = last["seen_at"];

    return !isMine && (seen == null || seen.toString().isEmpty);
  }

  bool _lastIsMine(Map<String, dynamic> c) {
    final last = _lastMap(c);
    return last?["is_me"] == true;
  }

  String _messageText(Map<String, dynamic> c) {
    final last = _lastMap(c);
    if (last == null) return "Start the conversation";

    final body = (last["body"] ?? "").toString().trim();
    if (body.isEmpty) return "Message unavailable";

    return body;
  }

  DateTime? _parseTime(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString();
    if (s.isEmpty || s == "null") return null;
    return DateTime.tryParse(s)?.toLocal();
  }

  DateTime? _lastUpdatedAt(Map<String, dynamic> c) {
    final last = _lastMap(c);

    return _parseTime(last?["seen_at"]) ??
        _parseTime(last?["delivered_at"]) ??
        _parseTime(last?["created_at"]) ??
        _parseTime(c["updated_at"]) ??
        _parseTime(c["last_active_at"]);
  }

  String _relativeFromDate(DateTime? dt) {
    if (dt == null) return "";

    final diff = DateTime.now().difference(dt);

    if (diff.inSeconds < 45) return "now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    if (diff.inDays < 7) return "${diff.inDays}d";

    return "${dt.day}/${dt.month}";
  }

  String _relativeLong(dynamic raw) {
    final dt = _parseTime(raw);
    if (dt == null) return "";

    final diff = DateTime.now().difference(dt);

    if (diff.inSeconds < 45) return "now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";

    return "${dt.day}/${dt.month}";
  }

  String _lastActiveText(Map<String, dynamic> c) {
    if (c["active_now"] == true) return "Active now";

    final raw = c["last_active_at"]?.toString();
    final dt = _parseTime(raw);

    if (dt == null) return "Recently active";

    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 2) return "Active now";
    if (diff.inMinutes < 60) return "Active ${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "Active ${diff.inHours}h ago";
    if (diff.inDays < 7) return "Active ${diff.inDays}d ago";

    return "Active ${dt.day}/${dt.month}";
  }

  String _inboxStatus(Map<String, dynamic> c) {
    if (_isBlockedConversation(c)) return "Blocked";

    final last = _lastMap(c);
    final active = c["active_now"] == true;

    if (last == null) {
      return active ? "Active now" : _lastActiveText(c);
    }

    final isMine = last["is_me"] == true;
    final seen = last["seen_at"];
    final delivered = last["delivered_at"];
    final created = last["created_at"];

    if (!isMine) {
      if (_isUnread(c) && active) return "Reply now · Active now";
      if (_isUnread(c)) return "Reply now";
      return active ? "Active now" : _lastActiveText(c);
    }

    if (seen != null && seen.toString().isNotEmpty) {
      return "Seen ${_relativeLong(seen)}";
    }

    if (delivered != null && delivered.toString().isNotEmpty) {
      return "Delivered ${_relativeLong(delivered)}";
    }

    return "Sent ${_relativeLong(created)}";
  }

  String _inboxTime(Map<String, dynamic> c) {
    return _relativeFromDate(_lastUpdatedAt(c));
  }

  DmConversationVisualState _visualState(Map<String, dynamic> c) {
    if (_isBlockedConversation(c)) return DmConversationVisualState.blocked;
    if (_isUnread(c)) return DmConversationVisualState.unread;

    final last = _lastMap(c);
    if (last == null) {
      return c["active_now"] == true
          ? DmConversationVisualState.active
          : DmConversationVisualState.normal;
    }

    if (last["is_me"] == true) {
      final seen = last["seen_at"];
      final delivered = last["delivered_at"];

      if (seen != null && seen.toString().isNotEmpty) {
        return DmConversationVisualState.seen;
      }

      if (delivered != null && delivered.toString().isNotEmpty) {
        return DmConversationVisualState.delivered;
      }

      return DmConversationVisualState.sent;
    }

    if (c["active_now"] == true) return DmConversationVisualState.active;

    return DmConversationVisualState.normal;
  }

  List<Map<String, dynamic>> get _filteredRequests {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _requests;
    return _requests.where((e) => _name(e).toLowerCase().contains(q)).toList();
  }

  List<Map<String, dynamic>> get _filteredMatches {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _matches;
    return _matches.where((e) => _name(e).toLowerCase().contains(q)).toList();
  }

  List<Map<String, dynamic>> get _filteredConversations {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _conversations;

    return _conversations.where((e) {
      return _name(e).toLowerCase().contains(q) ||
          _messageText(e).toLowerCase().contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> _itemsFromPage(Map<String, dynamic> page) {
    final raw = page["items"];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  void _onScroll() {
  if (!_scrollCtrl.hasClients) return;
  if (_loadingMoreConversations) return;
  if (!_hasMoreConversations) return;
  if (_query.trim().isNotEmpty) return;

  final pos = _scrollCtrl.position;

  if (pos.pixels > pos.maxScrollExtent - 420) {
    _loadMoreConversations();
  }
}

  void _markRealtimePulse(int? conversationId, {bool haptic = false}) {
    if (!mounted || conversationId == null) return;

    _pulseTimer?.cancel();

    setState(() => _recentPulseConversationId = conversationId);

    if (haptic) HapticFeedback.lightImpact();

    _pulseTimer = Timer(const Duration(milliseconds: 1250), () {
      if (!mounted) return;
      if (_recentPulseConversationId != conversationId) return;
      setState(() => _recentPulseConversationId = null);
    });
  }
  void _scheduleReconcile({int delayMs = 650}) {
  _reconcileTimer?.cancel();

  _reconcileTimer = Timer(Duration(milliseconds: delayMs), () {
    if (!mounted || _silentLoading) return;

    _load(
      silent: true,
      preserveMissingConversations: true,
    );
  });
}

void _markConversationSeenLocal(int conversationId) {
  final now = DateTime.now().toIso8601String();

  setState(() {
    _conversations = _conversations.map((c) {
      if (_conversationId(c) != conversationId) return c;

      final last = _lastMap(c);
      if (last == null) return c;
      if (last["is_me"] == true) return c;

      return {
        ...c,
        "last_message": {
          ...last,
          "seen_at": last["seen_at"] ?? now,
        },
      };
    }).toList();
  });
}

  Future<void> _initSocket() async {
    try {
      await SocialChatSocketService.instance.connect();

      _socketSub = SocialChatSocketService.instance.events.listen((event) {
        if (!mounted) return;

        final type = event["type"];

        if (type == "receive_message" || type == "new_message") {
          final raw = event["message"];
          if (raw is Map) {
            _applyIncomingMessage(Map<String, dynamic>.from(raw));
          }
          return;
        }

        if (type == "message_sent") {
          final raw = event["message"];
          if (raw is Map) {
            _applyConfirmedMessage(Map<String, dynamic>.from(raw));
          }
          return;
        }

        if (type == "delivered") {
          _applyDelivered(event);
          return;
        }

        if (type == "seen") {
          _applySeen(event);
          return;
        }

        if (type == "user_presence") {
          _applyPresence(event);
          return;
        }
      });
    } catch (e) {
      debugPrint("❌ DM_SOCKET init failed: $e");
    }
  }

  void _applyIncomingMessage(Map<String, dynamic> message) {
  final conversationId = (message["conversation_id"] as num?)?.toInt();
  final messageId = (message["id"] as num?)?.toInt();

  if (conversationId == null) return;

  final index = _conversations.indexWhere(
    (c) => _conversationId(c) == conversationId,
  );

  if (index == -1) {
    _scheduleReconcile(delayMs: 250);

    if (messageId != null && messageId > 0) {
      SocialChatSocketService.instance.sendDeliveredAck(
        messageId: messageId,
      );
    }

    _markRealtimePulse(conversationId, haptic: true);
    return;
  }

  final now = DateTime.now().toIso8601String();
  final isActive = _activeConversationId == conversationId;

  setState(() {
    final old = _conversations[index];

    final updated = {
      ...old,
      "last_message": {
        ...message,
        "is_me": false,
        if (isActive) "seen_at": now,
      },
      "updated_at": message["created_at"] ?? now,
    };

    _conversations.removeAt(index);
    _conversations.insert(0, updated);
  });

  _markRealtimePulse(conversationId, haptic: true);
  _scheduleReconcile();

  if (messageId != null && messageId > 0) {
    SocialChatSocketService.instance.sendDeliveredAck(
      messageId: messageId,
    );
  }
}

  void _applyConfirmedMessage(Map<String, dynamic> message) {
  final conversationId = (message["conversation_id"] as num?)?.toInt();
  if (conversationId == null) return;

  final index = _conversations.indexWhere(
    (c) => _conversationId(c) == conversationId,
  );

  if (index == -1) {
    _scheduleReconcile(delayMs: 250);
    return;
  }

  final now = DateTime.now().toIso8601String();

  setState(() {
    final old = _conversations[index];

    final updated = {
      ...old,
      "last_message": {
        ...message,
        "is_me": true,
      },
      "updated_at": message["created_at"] ?? now,
    };

    _conversations.removeAt(index);
    _conversations.insert(0, updated);
  });

  _markRealtimePulse(conversationId);
  _scheduleReconcile();
}

  void _applyDelivered(Map<String, dynamic> event) {
    final conversationId = (event["conversation_id"] as num?)?.toInt();
    final messageId = (event["message_id"] as num?)?.toInt();
    final deliveredAt = event["delivered_at"]?.toString();

    if (conversationId == null || messageId == null) return;
    if (deliveredAt == null || deliveredAt.isEmpty || deliveredAt == "null") {
      return;
    }

    setState(() {
      _conversations = _conversations.map((c) {
        if (_conversationId(c) != conversationId) return c;

        final last = _lastMap(c);
        if (last == null) return c;
        if (last["is_me"] != true) return c;

        final lastId = (last["id"] as num?)?.toInt();
        if (lastId != messageId) return c;

        return {
          ...c,
          "last_message": {
            ...last,
            "delivered_at": deliveredAt,
          },
          "updated_at": deliveredAt,
        };
      }).toList();
    });

    _markRealtimePulse(conversationId);
  }

  void _applySeen(Map<String, dynamic> event) {
    final conversationId = (event["conversation_id"] as num?)?.toInt();
    final seenAt = event["seen_at"]?.toString();

    if (conversationId == null) return;
    if (seenAt == null || seenAt.isEmpty || seenAt == "null") return;

    setState(() {
      _conversations = _conversations.map((c) {
        if (_conversationId(c) != conversationId) return c;

        final last = _lastMap(c);
        if (last == null) return c;
        if (last["is_me"] != true) return c;

        return {
          ...c,
          "last_message": {
            ...last,
            "seen_at": seenAt,
          },
          "updated_at": seenAt,
        };
      }).toList();
    });

    _markRealtimePulse(conversationId);
  }

  void _applyPresence(Map<String, dynamic> event) {
    final userId = (event["user_id"] as num?)?.toInt();
    if (userId == null) return;

    setState(() {
      _conversations = _conversations.map((c) {
        final otherId = _userId(c);
        if (otherId != userId) return c;

        return {
          ...c,
          "active_now": event["active_now"] == true || event["online"] == true,
          "last_active_at":
              event["last_active_at"]?.toString() ?? c["last_active_at"],
        };
      }).toList();

      _matches = _matches.map((m) {
        final id = _userId(m);
        if (id != userId) return m;

        return {
          ...m,
          "active_now": event["active_now"] == true || event["online"] == true,
          "last_active_at":
              event["last_active_at"]?.toString() ?? m["last_active_at"],
        };
      }).toList();
    });
  }

  List<Map<String, dynamic>> _mergePreservedConversations(
    List<Map<String, dynamic>> fresh,
  ) {
    final freshIds = fresh.map(_conversationId).whereType<int>().toSet();

    final preserved = _conversations.where((old) {
      final id = _conversationId(old);
      if (id == null) return false;
      if (freshIds.contains(id)) return false;

      return old["is_blocked"] == true ||
          old["blocked"] == true ||
          old["blocked_by_me"] == true;
    }).map((old) {
      return {
        ...old,
        "is_blocked": true,
        "blocked": true,
      };
    }).toList();

    return [...fresh, ...preserved];
  }

  Future<void> _load({
    bool silent = false,
    bool preserveMissingConversations = false,
  }) async {
    if (silent || _hasAnyContent) {
      _silentLoading = true;
    } else {
      if (mounted) setState(() => _loading = true);
    }

    try {
      final requests = await SocialMessageService.getIncomingRequests();

      final conversationsPage = await SocialMessageService.getConversationsPage(
        limit: _conversationLimit,
        offset: 0,
      );

      final freshConversations = _itemsFromPage(conversationsPage);
      final matches = await SocialMatchService.getMatches();

      final conversations = preserveMissingConversations
          ? _mergePreservedConversations(freshConversations)
          : freshConversations;

      final hasMore = conversationsPage["has_more"] == true;
      final nextOffset =
          (conversationsPage["next_offset"] as num?)?.toInt() ??
              freshConversations.length;

      if (!mounted) return;

      setState(() {
        _requests = requests;
        _conversations = conversations;
        _lastConversationOffsetRequested = null;
        _matches = matches;
        _hasMoreConversations = hasMore;
        _nextConversationOffset = nextOffset;
        _loading = false;
      });
    } catch (e, s) {
      debugPrint("❌ DM_SCREEN load ERROR=$e");
      debugPrint("❌ DM_SCREEN load STACK=$s");

      if (!mounted) return;
      if (!silent) setState(() => _loading = false);
    } finally {
      _silentLoading = false;
    }
  }

  Future<void> _loadMoreConversations() async {
  if (_loadingMoreConversations) return;
  if (!_hasMoreConversations) return;
  if (_query.trim().isNotEmpty) return;

  final offset = _nextConversationOffset;

  if (_lastConversationOffsetRequested == offset) {
    return;
  }

  _lastConversationOffsetRequested = offset;

  setState(() => _loadingMoreConversations = true);

  try {
    final page = await SocialMessageService.getConversationsPage(
      limit: _conversationLimit,
      offset: offset,
    );

    final items = _itemsFromPage(page);
    final existingIds =
        _conversations.map(_conversationId).whereType<int>().toSet();

    final fresh = items.where((c) {
      final id = _conversationId(c);
      return id != null && !existingIds.contains(id);
    }).toList();

    final nextOffset =
        (page["next_offset"] as num?)?.toInt() ?? offset + items.length;

    if (!mounted) return;

    setState(() {
      if (fresh.isNotEmpty) {
        _conversations.addAll(fresh);
      }

      _hasMoreConversations =
          page["has_more"] == true && nextOffset > offset;

      _nextConversationOffset = nextOffset;
    });

    if (items.isEmpty || nextOffset <= offset) {
      setState(() {
        _hasMoreConversations = false;
      });
    }
  } catch (e, s) {
    debugPrint("❌ DM_SCREEN loadMore ERROR=$e");
    debugPrint("❌ DM_SCREEN loadMore STACK=$s");

    _lastConversationOffsetRequested = null;
  } finally {
    if (mounted) {
      setState(() => _loadingMoreConversations = false);
    }
  }
}

  Future<void> _openConversation(Map<String, dynamic> c) async {
  _searchFocus.unfocus();
  HapticFeedback.lightImpact();

  final conversationId = _conversationId(c);

  if (conversationId == null || conversationId <= 0) {
    _showStartChatPrompt(c);
    return;
  }

  if (_isUnread(c)) {
    _markConversationSeenLocal(conversationId);
  }

  _activeConversationId = conversationId;

  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SocialChatScreen(
        conversationId: conversationId,
        userId: _userId(c) ?? 0,
        username: _name(c),
        imageUrl: _image(c),
        activeNow: c["active_now"] == true,
        lastActiveAt: c["last_active_at"]?.toString(),
      ),
    ),
  );

  _activeConversationId = null;

  if (!mounted) return;

  if (result is Map) {
    if (result["removed"] == true) {
      setState(() {
        _conversations.removeWhere(
          (x) => _conversationId(x) == conversationId,
        );
      });
      return;
    }

    if (result["blocked"] == true || result["is_blocked"] == true) {
      setState(() {
        _conversations = _conversations.map((x) {
          if (_conversationId(x) != conversationId) return x;

          return {
            ...x,
            "is_blocked": true,
            "blocked": true,
          };
        }).toList();
      });
      return;
    }

    if (result["unblocked"] == true) {
      await _load(
        silent: true,
        preserveMissingConversations: true,
      );
      return;
    }

    final last = result["last_message"];

    if (last is Map) {
      setState(() {
        final updated = _conversations.map((x) {
          if (_conversationId(x) != conversationId) return x;

          return {
            ...x,
            "last_message": Map<String, dynamic>.from(last),
            "updated_at":
                result["updated_at"] ?? DateTime.now().toIso8601String(),
          };
        }).toList();

        final index = updated.indexWhere(
          (x) => _conversationId(x) == conversationId,
        );

        if (index != -1) {
          final item = updated.removeAt(index);
          updated.insert(0, item);
        }

        _conversations = updated;
      });

      _scheduleReconcile();
      return;
    }
  }

  _scheduleReconcile();
}
  Future<void> _acceptMessageRequest(Map<String, dynamic> req) async {
  HapticFeedback.mediumImpact();

  final requestId = _requestId(req);
  if (requestId == null) return;

  try {
    final accepted = await SocialMessageService.acceptRequest(
      requestId: requestId,
    );

    if (!mounted) return;

    setState(() {
      _requests.removeWhere((r) => _requestId(r) == requestId);
    });

    await _load(
      silent: true,
      preserveMissingConversations: true,
    );

    final conversationId =
        (accepted["conversation_id"] as num?)?.toInt() ??
            ((accepted["conversation"] is Map)
                ? (accepted["conversation"]["id"] as num?)?.toInt()
                : null);

    if (conversationId != null) {
      _markRealtimePulse(conversationId, haptic: true);
    }
  } catch (e) {
    debugPrint("❌ accept message request failed: $e");
  }
}

Future<void> _rejectMessageRequest(Map<String, dynamic> req) async {
  HapticFeedback.selectionClick();

  final requestId = _requestId(req);
  if (requestId == null) return;

  try {
    await SocialMessageService.rejectRequest(
      requestId: requestId,
    );

    if (!mounted) return;

    setState(() {
      _requests.removeWhere((r) => _requestId(r) == requestId);
    });
  } catch (e) {
    debugPrint("❌ reject message request failed: $e");
  }
  }
  void _showRequestDecision(Map<String, dynamic> req) {
  _searchFocus.unfocus();
  HapticFeedback.selectionClick();

  final requestId = _requestId(req) ?? 0;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.78),
    isScrollControlled: true,
    builder: (_) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            decoration: BoxDecoration(
              color: DmUi.deepPanel,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: DmUi.gold2.withOpacity(0.14),
              ),
              boxShadow: [
                BoxShadow(
                  color: DmUi.gold.withOpacity(0.14),
                  blurRadius: 34,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                DmAvatar(
                  imageUrl: _image(req),
                  size: 76,
                  tag: "request_decision_$requestId",
                  fallbackIndex: requestId,
                ),
                const SizedBox(height: 16),
                Text(
                  _name(req),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "sent you a message request",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.58),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _rejectMessageRequest(req);
                        },
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              "Decline",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _acceptMessageRequest(req);
                        },
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: [
                                DmUi.gold2,
                                DmUi.gold,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: DmUi.gold.withOpacity(0.28),
                                blurRadius: 22,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              "Accept",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  void _showStartChatPrompt(Map<String, dynamic> user) {
  _searchFocus.unfocus();
  HapticFeedback.lightImpact();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.74),
    isScrollControlled: true,
    builder: (_) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.92, end: 1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        builder: (_, scale, child) {
          return Transform.scale(
            scale: scale,
            alignment: Alignment.bottomCenter,
            child: Opacity(
              opacity: scale,
              child: child,
            ),
          );
        },
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(34),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                decoration: BoxDecoration(
                  color: const Color(0xF40A101B),
                  border: Border(
                    top: BorderSide(
                      color: DmUi.gold2.withOpacity(0.12),
                    ),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      DmUi.gold.withOpacity(0.04),
                      const Color(0xF40A101B),
                      const Color(0xF40A101B),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DmUi.gold.withOpacity(0.14),
                      blurRadius: 42,
                      offset: const Offset(0, -16),
                    ),
                    BoxShadow(
                      color: DmUi.purple.withOpacity(0.18),
                      blurRadius: 38,
                      offset: const Offset(0, -12),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),

                      Row(
                        children: [
                          Hero(
                            tag: "dm_avatar${_name(user)}0",
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const SweepGradient(
                                  colors: [
                                    DmUi.gold2,
                                    DmUi.gold,
                                    DmUi.purple2,
                                    DmUi.cyan,
                                    DmUi.gold2,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: DmUi.gold.withOpacity(0.24),
                                    blurRadius: 22,
                                  ),
                                ],
                              ),
                              child: DmAvatar(
                                imageUrl: _image(user),
                                size: 70,
                                tag: "start_chat_avatar_${_name(user)}",
                                fallbackIndex: 0,
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Start conversation",
                                  style: TextStyle(
                                    color: DmUi.gold2.withOpacity(0.92),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.1,
                                  ),
                                ),

                                const SizedBox(height: 5),

                                Text(
                                  _name(user),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.9,
                                    height: 1,
                                  ),
                                ),

                                const SizedBox(height: 7),

                                Text(
                                  "Open chat and send your first message.",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.52),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  DmUi.gold2,
                                  DmUi.gold,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: DmUi.gold.withOpacity(0.28),
                                  blurRadius: 26,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.black,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

  void _openAvatarPreview(Map<String, dynamic> user, int i) {
  _searchFocus.unfocus();

  final img = _image(user);
  final tag = "dm_avatar${_name(user)}$i";

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "avatar_preview",
    barrierColor: Colors.black.withOpacity(0.90),
    transitionDuration: const Duration(milliseconds: 240),
    transitionBuilder: (_, anim, __, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: anim,
          curve: Curves.easeOut,
        ),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.92,
            end: 1,
          ).animate(
            CurvedAnimation(
              parent: anim,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: child,
        ),
      );
    },
    pageBuilder: (dialogContext, _, __) {
      return PopScope(
        canPop: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final nav = Navigator.of(dialogContext);

            if (nav.canPop()) {
              nav.pop();
            }
          },
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.1,
                        colors: [
                          DmUi.purple.withOpacity(0.12),
                          Colors.black,
                        ],
                      ),
                    ),
                  ),
                ),

                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.96, end: 1),
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    builder: (_, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: Container(
                      width: MediaQuery.of(dialogContext).size.width * 0.84,
                      height: MediaQuery.of(dialogContext).size.width * 0.84,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const SweepGradient(
                          colors: [
                            DmUi.gold2,
                            DmUi.gold,
                            DmUi.purple2,
                            DmUi.cyan,
                            DmUi.gold2,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: DmUi.gold.withOpacity(0.24),
                            blurRadius: 48,
                          ),
                          BoxShadow(
                            color: DmUi.purple.withOpacity(0.22),
                            blurRadius: 64,
                          ),
                        ],
                      ),
                      child: Hero(
                        tag: tag,
                        child: ClipOval(
                          child: img.isNotEmpty
                              ? InteractiveViewer(
                                  minScale: 1,
                                  maxScale: 3.8,
                                  child: Image.network(
                                    img,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) {
                                      return DmAvatarFallback(
                                        size: 280,
                                        index: i,
                                      );
                                    },
                                  ),
                                )
                              : DmAvatarFallback(
                                  size: 280,
                                  index: i,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: MediaQuery.of(dialogContext).padding.top + 14,
                  right: 18,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withOpacity(0.85),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  @override
Widget build(BuildContext context) {
  final bottomSafe = MediaQuery.of(context).padding.bottom;
  final latestUnread = _latestUnreadConversation;

  return GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: () {
      if (_searchFocus.hasFocus) _searchFocus.unfocus();
    },
    child: Scaffold(
      backgroundColor: DmUi.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: DmBackground()),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DmEnter(
                    index: 0,
                    child: DmTopBar(unreadCount: _unreadCount),
                  ),
                  const SizedBox(height: 17),
                  DmEnter(
                    index: 1,
                    child: DmSearchBar(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      query: _query,
                      onChanged: (value) {
                        setState(() => _query = value);
                      },
                      onClear: () {
                        HapticFeedback.selectionClick();
                        _searchCtrl.clear();
                        _searchFocus.unfocus();
                        setState(() => _query = "");
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _loading && !_hasAnyContent
                        ? const DmLoadingSkeleton()
                        : RefreshIndicator(
                            color: DmUi.gold2,
                            backgroundColor: DmUi.deepPanel,
                            onRefresh: () => _load(
                              silent: true,
                              preserveMissingConversations: true,
                            ),
                            child: !_hasAnyContent
                                ? const DmEmptyState()
                                : ListView(
                                    controller: _scrollCtrl,
                                    keyboardDismissBehavior:
                                        ScrollViewKeyboardDismissBehavior.onDrag,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(
                                      parent: BouncingScrollPhysics(),
                                    ),
                                    padding: EdgeInsets.only(
                                      bottom: 120 + bottomSafe,
                                    ),
                                    children: [
                                      if (latestUnread != null &&
                                          _query.trim().isEmpty) ...[
                                        DmEnter(
                                          index: 2,
                                          child: DmReplyNowBanner(
                                            unreadCount: _unreadCount,
                                            name: _name(latestUnread),
                                            onTap: () {
                                              HapticFeedback.mediumImpact();
                                              _openConversation(latestUnread);
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 22),
                                      ],
                                      if (_filteredRequests.isNotEmpty) ...[
                                        DmSectionTitle(
                                          title: "Requests",
                                          count: _filteredRequests.length,
                                          icon: Icons.bolt_rounded,
                                        ),
                                        const SizedBox(height: 14),
                                        ...List.generate(
                                          _filteredRequests.length,
                                          (i) {
                                            final req = _filteredRequests[i];

                                            return DmStagger(
                                              index: i,
                                              child: DmRequestCard(
                                                name: _name(req),
                                                imageUrl: _image(req),
                                                avatarTag:
                                                    "dm_avatar_${_name(req)}$i",
                                                fallbackIndex: i,
                                                onTap: () =>
                                                    _showRequestDecision(req),
                                                onAvatarTap: () {
                                                  HapticFeedback
                                                      .selectionClick();
                                                  _openAvatarPreview(req, i);
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 24),
                                      ],
                                      if (_filteredMatches.isNotEmpty) ...[
                                        DmSectionTitle(
                                          title: "ELITE MATCHES",
                                          count: _filteredMatches.length,
                                          icon: Icons.auto_awesome_rounded,
                                          elite: true,
                                        ),
                                        const SizedBox(height: 15),
                                        SizedBox(
                                          height: 130,
                                          child: ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            keyboardDismissBehavior:
                                                ScrollViewKeyboardDismissBehavior
                                                    .onDrag,
                                            physics:
                                                const BouncingScrollPhysics(),
                                            itemCount:
                                                _filteredMatches.length,
                                            separatorBuilder: (_, __) =>
                                                const SizedBox(width: 16),
                                            itemBuilder: (_, i) {
                                              final match =
                                                  _filteredMatches[i];

                                              return DmStagger(
                                                index: i,
                                                horizontal: true,
                                                child: DmMatchBubble(
                                                  name: _name(match),
                                                  imageUrl: _image(match),
                                                  activeNow:
                                                      match["active_now"] ==
                                                          true,
                                                  animateRing: i < 6 ||
                                                      match["active_now"] ==
                                                          true,
                                                  avatarTag:
                                                      "dm_avatar_${_name(match)}$i",
                                                  fallbackIndex: i,
                                                  onTap: () =>
                                                      _openConversation(match),
                                                  onAvatarTap: () {
                                                    HapticFeedback
                                                        .selectionClick();
                                                    _openAvatarPreview(
                                                      match,
                                                      i,
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 34),
                                      ],
                                      if (_filteredConversations
                                          .isNotEmpty) ...[
                                        DmSectionTitle(
                                          title: "Messages",
                                          count: _unreadCount > 0
                                              ? _unreadCount
                                              : _filteredConversations.length,
                                          icon: Icons.chat_bubble_rounded,
                                          unreadEnergy: _unreadCount > 0,
                                        ),
                                        const SizedBox(height: 15),
                                        ...List.generate(
                                          _filteredConversations.length,
                                          (i) {
                                            final c =
                                                _filteredConversations[i];
                                            final id = _conversationId(c);

                                            return DmStagger(
                                              index: i,
                                              child: DmConversationCard(
                                                name: _name(c),
                                                imageUrl: _image(c),
                                                message: _messageText(c),
                                                status: _inboxStatus(c),
                                                time: _inboxTime(c),
                                                visualState: _visualState(c),
                                                activeNow:
                                                    c["active_now"] == true,
                                                unread: _isUnread(c),
                                                lastIsMine: _lastIsMine(c),
                                                pulsing: id != null &&
                                                    id ==
                                                        _recentPulseConversationId,
                                                avatarTag:
                                                    "dm_avatar_${_name(c)}$i",
                                                fallbackIndex: i,
                                                onTap: () =>
                                                    _openConversation(c),
                                                onAvatarTap: () {
                                                  HapticFeedback
                                                      .selectionClick();
                                                  _openAvatarPreview(c, i);
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                      if (_loadingMoreConversations) ...[
                                        const SizedBox(height: 20),
                                        const Center(
                                          child: SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: DmUi.gold2,
                                              strokeWidth: 2.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}}