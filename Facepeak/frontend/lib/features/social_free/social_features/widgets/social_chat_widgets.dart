import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ChatMessageStatus {
  sending,
  sent,
  delivered,
  seen,
  failed,
}

class ChatUi {
  static const Color bg = Color(0xFF02050A);
  static const Color surface = Color(0xF00A101B);
  static const Color gold = Color(0xFFFFC34D);
  static const Color gold2 = Color(0xFFFFE7A8);
  static const Color goldDeep = Color(0xFFC3922E);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purple2 = Color(0xFFA855F7);
  static const Color cyan = Color(0xFF8FD8FF);
  static const Color seenBlue = Color(0xFF5CCBFF);
  static const Color green = Color(0xFF74F2A8);
  static const Color danger = Color(0xFFFF4D67);
}

class ChatBackground extends StatelessWidget {
  const ChatBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF07101B),
                  Color(0xFF02050A),
                  Color(0xFF010309),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -170,
          left: -120,
          right: -120,
          child: Container(
            height: 430,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  ChatUi.purple2.withOpacity(0.18),
                  ChatUi.purple.withOpacity(0.065),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -210,
          left: -140,
          right: -140,
          child: Container(
            height: 430,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  ChatUi.gold.withOpacity(0.12),
                  ChatUi.gold.withOpacity(0.020),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ChatTopBar extends StatelessWidget {
  const ChatTopBar({
    super.key,
    required this.username,
    required this.imageUrl,
    required this.activeNow,
    required this.blocked,
    required this.statusText,
    required this.onBack,
    required this.onAvatarTap,
    this.onHeaderTap,
    this.onMenuTap,
  });

  final String username;
  final String imageUrl;
  final bool activeNow;
  final bool blocked;
  final String statusText;
  final VoidCallback onBack;
  final VoidCallback onAvatarTap;
  final VoidCallback? onHeaderTap;
  final VoidCallback? onMenuTap;

  Color get statusColor {
    if (blocked) return ChatUi.danger.withOpacity(0.86);
    if (activeNow) return ChatUi.green;
    return ChatUi.gold2.withOpacity(0.68);
  }

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.of(context).padding.top;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(14, topSafe + 8, 14, 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xF407101B),
                Color(0xDD07101B),
                Color(0xAA07101B),
              ],
            ),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.050)),
            ),
          ),
          child: Row(
            children: [
              ChatRoundButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBack,
              ),
              const SizedBox(width: 12),

              GestureDetector(
                onTap: onAvatarTap,
                child: ChatAvatar(
                  imageUrl: imageUrl,
                  size: 58,
                  ring: true,
                  activeNow: activeNow && !blocked,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onHeaderTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.50,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: activeNow && !blocked ? 8 : 7,
                              height: activeNow && !blocked ? 8 : 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: statusColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: statusColor.withOpacity(0.56),
                                    blurRadius: activeNow ? 13 : 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                blocked ? "You have been blocked" : statusText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12.3,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.05,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (onMenuTap != null) ...[
                const SizedBox(width: 10),
                ChatRoundButton(
                  icon: Icons.more_horiz_rounded,
                  onTap: onMenuTap!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.body,
    required this.isMe,
    required this.failed,
    required this.pending,
    required this.previousSameSender,
    required this.nextSameSender,
    required this.showStatus,
    required this.statusText,
    required this.statusType,
    required this.onRetry,
  });

  final String body;
  final bool isMe;
  final bool failed;
  final bool pending;
  final bool previousSameSender;
  final bool nextSameSender;
  final bool showStatus;
  final String statusText;
  final ChatMessageStatus statusType;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final topRadius = previousSameSender ? 15.0 : 24.0;
    final bottomRadius = nextSameSender ? 15.0 : 24.0;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: failed ? onRetry : null,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.76,
          ),
          margin: EdgeInsets.only(
            bottom: nextSameSender ? 4 : 12,
            top: previousSameSender ? 0 : 4,
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isMe ? topRadius : 24),
                    topRight: Radius.circular(isMe ? 24 : topRadius),
                    bottomLeft: Radius.circular(isMe ? 24 : bottomRadius),
                    bottomRight: Radius.circular(isMe ? bottomRadius : 24),
                  ),
                  gradient: isMe && !failed
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: pending
                              ? [
                                  ChatUi.gold.withOpacity(0.72),
                                  ChatUi.gold2.withOpacity(0.68),
                                ]
                              : const [
                                  ChatUi.gold,
                                  ChatUi.gold2,
                                ],
                        )
                      : null,
                  color: isMe ? null : Colors.white.withOpacity(0.086),
                  border: isMe
                      ? null
                      : Border.all(color: Colors.white.withOpacity(0.080)),
                  boxShadow: [
                    if (isMe)
                      BoxShadow(
                        color: ChatUi.gold.withOpacity(0.18),
                        blurRadius: 22,
                        offset: const Offset(0, 9),
                      )
                    else
                      BoxShadow(
                        color: ChatUi.purple.withOpacity(0.055),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                  ],
                ),
                child: Text(
                  body,
                  style: TextStyle(
                    color: isMe ? Colors.black : Colors.white,
                    fontSize: 16.2,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.15,
                  ),
                ),
              ),
              if (showStatus) ...[
                const SizedBox(height: 6),
                ChatMessageMeta(
                  body: body,
                  statusText: statusText,
                  type: statusType,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ChatMessageMeta extends StatelessWidget {
  const ChatMessageMeta({
    super.key,
    required this.body,
    required this.statusText,
    required this.type,
  });

  final String body;
  final String statusText;
  final ChatMessageStatus type;

  Color get color {
    switch (type) {
      case ChatMessageStatus.failed:
        return ChatUi.danger;
      case ChatMessageStatus.sending:
        return Colors.white.withOpacity(0.48);
      case ChatMessageStatus.seen:
        return ChatUi.seenBlue;
      case ChatMessageStatus.delivered:
        return ChatUi.gold2.withOpacity(0.82);
      case ChatMessageStatus.sent:
        return Colors.white.withOpacity(0.64);
    }
  }

  IconData get icon {
    switch (type) {
      case ChatMessageStatus.failed:
        return Icons.error_rounded;
      case ChatMessageStatus.sending:
        return Icons.more_horiz_rounded;
      case ChatMessageStatus.seen:
        return Icons.done_all_rounded;
      case ChatMessageStatus.delivered:
        return Icons.done_all_rounded;
      case ChatMessageStatus.sent:
        return Icons.done_rounded;
    }
  }

  @override
Widget build(BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(width: 5),
      Text(
        statusText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11.8,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.10,
          shadows: type == ChatMessageStatus.seen
              ? [
                  Shadow(
                    color: ChatUi.seenBlue.withOpacity(0.38),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
      ),
    ],
  );
}}

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.username,
    required this.blocked,
    required this.sending,
    required this.focused,
    required this.hasText,
    required this.onSend,
    required this.onBlockedTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String username;
  final bool blocked;
  final bool sending;
  final bool focused;
  final bool hasText;
  final VoidCallback onSend;
  final VoidCallback onBlockedTap;

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final bottomPad = keyboardOpen
        ? 8.0
        : bottomSafe > 0
            ? 8.0
            : 10.0;

    if (blocked) {
      return SafeArea(
        top: false,
        minimum: EdgeInsets.fromLTRB(14, 5, 14, bottomPad),
        child: GestureDetector(
          onTap: onBlockedTap,
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: ChatUi.surface,
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: ChatUi.danger.withOpacity(0.18)),
              boxShadow: [
                BoxShadow(
                  color: ChatUi.danger.withOpacity(0.060),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ChatUi.danger.withOpacity(0.13),
                    border: Border.all(
                      color: ChatUi.danger.withOpacity(0.20),
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: ChatUi.danger,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "You have been blocked",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      minimum: EdgeInsets.fromLTRB(14, 5, 14, bottomPad),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.fromLTRB(14, 7, 7, 7),
            decoration: BoxDecoration(
              color: focused
                  ? const Color(0xF00D1420)
                  : const Color(0xE00A101B),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: focused
                    ? ChatUi.gold2.withOpacity(0.22)
                    : Colors.white.withOpacity(0.085),
              ),
              boxShadow: [
                BoxShadow(
                  color: focused
                      ? ChatUi.gold.withOpacity(0.18)
                      : ChatUi.purple.withOpacity(0.075),
                  blurRadius: focused ? 32 : 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: ChatUi.gold2.withOpacity(focused ? 0.88 : 0.60),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: TextField(
                    focusNode: focusNode,
                    controller: controller,
                    enabled: !sending,
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    cursorColor: ChatUi.gold2,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      height: 1.18,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Message $username",
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.34),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                GestureDetector(
                  onTap: sending || !hasText ? null : onSend,
                  child: AnimatedScale(
                    scale: hasText ? 1 : 0.92,
                    duration: const Duration(milliseconds: 150),
                    child: AnimatedOpacity(
                      opacity: hasText ? 1 : 0.50,
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              ChatUi.gold2,
                              ChatUi.gold,
                              ChatUi.goldDeep,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: ChatUi.gold.withOpacity(
                                hasText ? 0.36 : 0.12,
                              ),
                              blurRadius: 19,
                            ),
                          ],
                        ),
                        child: sending
                            ? const Padding(
                                padding: EdgeInsets.all(13),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.black,
                                ),
                              )
                            : Icon(
                                Icons.arrow_upward_rounded,
                                color: Colors.black,
                                size: 24,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class ChatIncomingBanner extends StatelessWidget {
  const ChatIncomingBanner({
    super.key,
    required this.visible,
    required this.text,
    required this.imageUrl,
    required this.onTap,
  });

  final bool visible;
  final String text;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 16,
      right: 16,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xF00A101B),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: ChatUi.gold2.withOpacity(0.16)),
                  ),
                  child: Row(
                    children: [
                      ChatAvatar(imageUrl: imageUrl, size: 34),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: ChatUi.gold2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChatJumpButton extends StatelessWidget {
  const ChatJumpButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 18,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [ChatUi.gold, ChatUi.gold2],
            ),
            boxShadow: [
              BoxShadow(
                color: ChatUi.gold.withOpacity(0.32),
                blurRadius: 22,
              ),
            ],
          ),
          child: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class ChatBlockedBanner extends StatelessWidget {
  const ChatBlockedBanner({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: visible
          ? Container(
              margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: ChatUi.danger.withOpacity(0.10),
                border: Border.all(color: ChatUi.danger.withOpacity(0.22)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.block_rounded,
                    color: ChatUi.danger,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "You have been blocked. You can’t send messages to this user.",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontSize: 12.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    super.key,
    required this.imageUrl,
    required this.size,
    this.ring = false,
    this.activeNow = false,
  });

  final String imageUrl;
  final double size;
  final bool ring;
  final bool activeNow;

  @override
  Widget build(BuildContext context) {
    final avatar = ClipOval(
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ChatFallbackAvatar(size: size),
            )
          : ChatFallbackAvatar(size: size),
    );

    if (!ring) return avatar;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const SweepGradient(
          colors: [ChatUi.gold2, ChatUi.purple2, ChatUi.cyan, ChatUi.gold2],
        ),
        boxShadow: [
          BoxShadow(
            color: activeNow
                ? ChatUi.green.withOpacity(0.18)
                : ChatUi.gold.withOpacity(0.12),
            blurRadius: 18,
          ),
        ],
      ),
      child: avatar,
    );
  }
}

class ChatFallbackAvatar extends StatelessWidget {
  const ChatFallbackAvatar({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [ChatUi.gold2, ChatUi.purple2]),
      ),
      child: Icon(
        Icons.person_rounded,
        color: Colors.black54,
        size: size * 0.54,
      ),
    );
  }
}

class ChatAvatarPreview extends StatelessWidget {
  const ChatAvatarPreview({
    super.key,
    required this.imageUrl,
    required this.onClose,
  });

  final String imageUrl;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.84;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onClose,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: InteractiveViewer(
            minScale: 0.85,
            maxScale: 3.2,
            child: Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: [
                    ChatUi.gold2,
                    ChatUi.gold,
                    ChatUi.purple2,
                    ChatUi.cyan,
                    ChatUi.gold2,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: ChatUi.gold.withOpacity(0.24),
                    blurRadius: 48,
                  ),
                  BoxShadow(
                    color: ChatUi.purple.withOpacity(0.22),
                    blurRadius: 64,
                  ),
                ],
              ),
              child: ClipOval(
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            ChatFallbackAvatar(size: size),
                      )
                    : ChatFallbackAvatar(size: size),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({
    super.key,
    required this.username,
    required this.imageUrl,
  });

  final String username;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChatAvatar(imageUrl: imageUrl, size: 72, ring: true),
            const SizedBox(height: 18),
            Text(
              "Start with $username",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Say something simple.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.52),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatOlderLoader extends StatelessWidget {
  const ChatOlderLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            color: ChatUi.gold2,
            strokeWidth: 2.2,
          ),
        ),
      ),
    );
  }
}

class ChatRoundButton extends StatelessWidget {
  const ChatRoundButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          color: Colors.white.withOpacity(0.060),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class ChatActionsSheet extends StatelessWidget {
  const ChatActionsSheet({
    super.key,
    required this.username,
    required this.imageUrl,
    required this.blocked,
    required this.onRemove,
    required this.onBlock,
    required this.onUnblock,
    required this.onReport,
  });

  final String username;
  final String imageUrl;
  final bool blocked;
  final VoidCallback onRemove;
  final VoidCallback onBlock;
  final VoidCallback onUnblock;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return ChatSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ChatSheetHandle(),
          const SizedBox(height: 18),
          Row(
            children: [
              ChatAvatar(imageUrl: imageUrl, size: 58),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ChatActionTile(
            icon: Icons.delete_outline_rounded,
            title: "Remove chat",
            subtitle: "Hide this conversation only for you",
            color: ChatUi.gold2,
            onTap: onRemove,
          ),
          const SizedBox(height: 10),
          ChatActionTile(
            icon: Icons.report_gmailerrorred_rounded,
            title: "Report user",
            subtitle: "Send this user to admin review",
            color: ChatUi.cyan,
            onTap: onReport,
          ),
          const SizedBox(height: 10),
          ChatActionTile(
            icon: blocked ? Icons.lock_open_rounded : Icons.block_rounded,
            title: blocked ? "Unblock user" : "Block user",
            subtitle: blocked
                ? "Allow messages and requests again"
                : "Stop messages, matches and requests",
            color: blocked ? ChatUi.gold2 : ChatUi.danger,
            onTap: blocked ? onUnblock : onBlock,
          ),
        ],
      ),
    );
  }
}

class ChatReportSheet extends StatelessWidget {
  const ChatReportSheet({
    super.key,
    required this.onReport,
  });

  final ValueChanged<String> onReport;

  @override
  Widget build(BuildContext context) {
    return ChatSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ChatSheetHandle(),
          const SizedBox(height: 18),
          const Text(
            "Report reason",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          ChatActionTile(
            icon: Icons.flag_rounded,
            title: "Harassment",
            subtitle: "Submit report",
            color: ChatUi.gold2,
            onTap: () => onReport("Harassment"),
          ),
          const SizedBox(height: 10),
          ChatActionTile(
            icon: Icons.flag_rounded,
            title: "Spam or fake profile",
            subtitle: "Submit report",
            color: ChatUi.gold2,
            onTap: () => onReport("Spam or fake profile"),
          ),
          const SizedBox(height: 10),
          ChatActionTile(
            icon: Icons.flag_rounded,
            title: "Inappropriate messages",
            subtitle: "Submit report",
            color: ChatUi.gold2,
            onTap: () => onReport("Inappropriate messages"),
          ),
          const SizedBox(height: 10),
          ChatActionTile(
            icon: Icons.flag_rounded,
            title: "Other",
            subtitle: "Submit report",
            color: ChatUi.gold2,
            onTap: () => onReport("Other"),
          ),
        ],
      ),
    );
  }
}

class ChatSheet extends StatelessWidget {
  const ChatSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: size.height * 0.84),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            decoration: BoxDecoration(
              color: const Color(0xF0060A12),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.10)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.42),
                  blurRadius: 42,
                  offset: const Offset(0, -14),
                ),
                BoxShadow(
                  color: ChatUi.purple.withOpacity(0.16),
                  blurRadius: 34,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 16),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChatSheetHandle extends StatelessWidget {
  const ChatSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 5,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.18),
      ),
    );
  }
}

class ChatActionTile extends StatelessWidget {
  const ChatActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white.withOpacity(0.055),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.48),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.34),
            ),
          ],
        ),
      ),
    );
  }
}