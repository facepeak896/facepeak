import 'package:flutter/material.dart';

enum SocialActionType {
  follow,
  match,
  message,
}

enum SocialActionVisualState {
  available,
  sent,
  accepted,
  blockedByMe,
  blockedMe,
  disabled,
}

class SocialActionState {
  final String label;
  final IconData icon;
  final bool enabled;
  final SocialActionVisualState visualState;

  const SocialActionState({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.visualState,
  });
}

class SocialActionStateHelper {
  static bool _b(dynamic v) => v == true;

  static String _s(dynamic v) {
    final value = v?.toString().trim().toLowerCase();
    if (value == null || value.isEmpty || value == "null") return "";
    return value;
  }

  static bool isMe(Map<String, dynamic>? user) {
    return _b(user?["is_me"]);
  }

  static bool blockedByMe(Map<String, dynamic>? user) {
    return _b(user?["blocked_by_me"]) ||
        _b(user?["is_blocked_by_me"]) ||
        _s(user?["block_status"]) == "blocked_by_me";
  }

  static bool blockedMe(Map<String, dynamic>? user) {
    return _b(user?["blocked_me"]) ||
        _b(user?["is_blocked_me"]) ||
        _s(user?["block_status"]) == "blocked_me";
  }

  static bool canInteract(Map<String, dynamic>? user) {
    if (user == null) return false;
    if (isMe(user)) return false;
    if (blockedByMe(user)) return false;
    if (blockedMe(user)) return false;
    return true;
  }

  static SocialActionState follow(Map<String, dynamic>? user) {
    debugPrint("❌ SOCIAL_ACTION_HELPER follow user=$user");

    if (isMe(user)) {
      return const SocialActionState(
        label: "You",
        icon: Icons.verified_rounded,
        enabled: false,
        visualState: SocialActionVisualState.disabled,
      );
    }

    if (blockedByMe(user)) {
      return const SocialActionState(
        label: "Blocked",
        icon: Icons.block_rounded,
        enabled: false,
        visualState: SocialActionVisualState.blockedByMe,
      );
    }

    if (blockedMe(user)) {
      return const SocialActionState(
        label: "Unavailable",
        icon: Icons.lock_rounded,
        enabled: false,
        visualState: SocialActionVisualState.blockedMe,
      );
    }

    final status = _s(user?["follow_status"]);

    final accepted = _b(user?["is_following"]) ||
        _b(user?["following"]) ||
        _b(user?["following_user"]) ||
        _b(user?["has_followed"]) ||
        status == "accepted";

    if (accepted) {
      return const SocialActionState(
        label: "Following",
        icon: Icons.check_rounded,
        enabled: false,
        visualState: SocialActionVisualState.accepted,
      );
    }

    if (status == "pending" || _b(user?["follow_pending"])) {
      return const SocialActionState(
        label: "Sent",
        icon: Icons.check_rounded,
        enabled: false,
        visualState: SocialActionVisualState.sent,
      );
    }

    final canRequest =
        user?["can_follow_request"] == true || user?["can_follow_request"] == null;

    return SocialActionState(
      label: "Follow",
      icon: Icons.person_add_alt_1_rounded,
      enabled: canRequest,
      visualState: canRequest
          ? SocialActionVisualState.available
          : SocialActionVisualState.disabled,
    );
  }

  static SocialActionState match(Map<String, dynamic>? user) {
    debugPrint("❌ SOCIAL_ACTION_HELPER match user=$user");

    if (!canInteract(user)) {
      return SocialActionState(
        label: blockedByMe(user) ? "Blocked" : "Unavailable",
        icon: blockedByMe(user) ? Icons.block_rounded : Icons.lock_rounded,
        enabled: false,
        visualState: blockedByMe(user)
            ? SocialActionVisualState.blockedByMe
            : SocialActionVisualState.blockedMe,
      );
    }

    final status = _s(user?["match_status"]);

    final accepted = _b(user?["is_matched"]) ||
        _b(user?["has_match"]) ||
        status == "accepted";

    if (accepted) {
      return const SocialActionState(
        label: "Matched",
        icon: Icons.check_rounded,
        enabled: false,
        visualState: SocialActionVisualState.accepted,
      );
    }

    if (status == "pending" || _b(user?["match_pending"])) {
      return const SocialActionState(
        label: "Sent",
        icon: Icons.check_rounded,
        enabled: false,
        visualState: SocialActionVisualState.sent,
      );
    }

    final canRequest =
        user?["can_match_request"] == true || user?["can_match_request"] == null;

    return SocialActionState(
      label: "Match",
      icon: Icons.favorite_rounded,
      enabled: canRequest,
      visualState: canRequest
          ? SocialActionVisualState.available
          : SocialActionVisualState.disabled,
    );
  }

  static SocialActionState message(Map<String, dynamic>? user) {
    debugPrint("❌ SOCIAL_ACTION_HELPER message user=$user");

    if (!canInteract(user)) {
      return SocialActionState(
        label: blockedByMe(user) ? "Blocked" : "Unavailable",
        icon: blockedByMe(user) ? Icons.block_rounded : Icons.lock_rounded,
        enabled: false,
        visualState: blockedByMe(user)
            ? SocialActionVisualState.blockedByMe
            : SocialActionVisualState.blockedMe,
      );
    }

    final reqStatus = _s(user?["message_request_status"]);
    final dmStatus = _s(user?["dm_status"]);

    final accepted = _b(user?["has_conversation"]) ||
        reqStatus == "accepted" ||
        dmStatus == "accepted";

    if (accepted) {
      return const SocialActionState(
        label: "Chat",
        icon: Icons.chat_bubble_rounded,
        enabled: false,
        visualState: SocialActionVisualState.accepted,
      );
    }

    if (reqStatus == "pending" || dmStatus == "pending") {
      return const SocialActionState(
        label: "Sent",
        icon: Icons.check_rounded,
        enabled: false,
        visualState: SocialActionVisualState.sent,
      );
    }

    final canRequest =
        user?["can_dm_request"] == true || user?["can_dm_request"] == null;

    return SocialActionState(
      label: "Message",
      icon: Icons.chat_bubble_rounded,
      enabled: canRequest,
      visualState: canRequest
          ? SocialActionVisualState.available
          : SocialActionVisualState.disabled,
    );
  }

  static Map<String, dynamic> markPending(
    Map<String, dynamic>? user,
    SocialActionType action,
  ) {
    final base = {...?user};

    switch (action) {
      case SocialActionType.follow:
        return {
          ...base,
          "can_follow_request": false,
          "follow_status": "pending",
          "follow_pending": true,
        };

      case SocialActionType.match:
        return {
          ...base,
          "can_match_request": false,
          "match_status": "pending",
          "match_pending": true,
        };

      case SocialActionType.message:
        return {
          ...base,
          "can_dm_request": false,
          "message_request_status": "pending",
          "dm_status": "pending",
        };
    }
  }
}