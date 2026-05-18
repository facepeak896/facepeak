import 'dart:math';

class DmEngagementService {
  static final Random _r = Random();

  static int unreadCount(List<Map<String, dynamic>> conversations) {
    int count = 0;

    for (final c in conversations) {
      final blocked = c["is_blocked"] == true ||
          c["blocked"] == true ||
          c["blocked_by_me"] == true;

      if (blocked) continue;

      final last = c["last_message"];

      if (last is Map) {
        final isMine = last["is_me"] == true;
        final seen = last["seen_at"];

        if (!isMine && (seen == null || seen.toString().isEmpty)) {
          count++;
        }
      }
    }

    return count;
  }

  static bool shouldShowNextStep({
    required int requestsCount,
    required int matchesCount,
    required int conversationsCount,
    required int unreadCount,
  }) {
    if (unreadCount > 0) return true;
    if (requestsCount > 0) return true;
    if (matchesCount > 0) return true;
    if (conversationsCount == 0) return true;
    return true;
  }

  static String nextStepTitle({
    required int requestsCount,
    required int matchesCount,
    required int conversationsCount,
    required int unreadCount,
  }) {
    if (unreadCount > 0) return "Reply while the moment is hot";
    if (requestsCount > 0) return "Someone wants to enter your DMs";
    if (matchesCount > 0 && conversationsCount == 0) return "Start your first elite chat";
    if (matchesCount > 0) return "Turn a match into a conversation";
    if (conversationsCount == 0) return "Your inbox is warming up";
    return "Keep your social layer active";
  }

  static String nextStepSubtitle({
    required int requestsCount,
    required int matchesCount,
    required int conversationsCount,
    required int unreadCount,
  }) {
    if (unreadCount > 0) return "Fast replies make conversations feel alive.";
    if (requestsCount > 0) return "Accept the best request and start the loop.";
    if (matchesCount > 0 && conversationsCount == 0) {
      return "Open a match and send the first message.";
    }
    if (matchesCount > 0) return "A small message can start momentum.";
    if (conversationsCount == 0) return "Interact with people to unlock real conversations.";
    return "Check new activity and keep momentum going.";
  }

  static String nextStepCta({
    required int requestsCount,
    required int matchesCount,
    required int conversationsCount,
    required int unreadCount,
  }) {
    if (unreadCount > 0) return "Open chat";
    if (requestsCount > 0) return "Review";
    if (matchesCount > 0) return "Start";
    if (conversationsCount == 0) return "Explore";
    return "Continue";
  }

  static String liveSignal({
    required int requestsCount,
    required int matchesCount,
    required int conversationsCount,
    required int unreadCount,
  }) {
    if (unreadCount > 0) return "👀 $unreadCount unread ${unreadCount == 1 ? "message" : "messages"}";
    if (requestsCount > 0) return "🔥 $requestsCount DM ${requestsCount == 1 ? "request" : "requests"} waiting";
    if (matchesCount > 0) return "✨ $matchesCount elite ${matchesCount == 1 ? "match" : "matches"} active";
    if (conversationsCount > 0) return "💬 Social layer is live";
    return "🔥 Your inbox is warming up";
  }

  static String floatingHint({
    required int requestsCount,
    required int matchesCount,
    required int conversationsCount,
    required int unreadCount,
  }) {
    if (unreadCount > 0) return "👀 Reply waiting";
    if (requestsCount > 0) return "🔥 New request energy";
    if (matchesCount > 0 && conversationsCount == 0) return "💬 Start your first chat";
    if (matchesCount > 0) return "✨ Match momentum is ready";

    final safeHints = [
      "👀 People are active right now",
      "🔥 Activity is picking up",
      "✨ Your social layer is warming up",
      "💬 One good message can start momentum",
    ];

    return safeHints[_r.nextInt(safeHints.length)];
  }

  static String conversationPreview({
    required Map<String, dynamic> conversation,
    required bool unread,
    required bool blocked,
  }) {
    if (blocked) return "Blocked conversation";
    if (unread) return "👀 Tap to reply";

    final last = conversation["last_message"];

    if (last is Map) {
      final body = (last["body"] ?? "").toString().trim();
      if (body.isNotEmpty) return body;
    }

    return "Tap to start the chat";
  }
}