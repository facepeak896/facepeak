import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum DmConversationVisualState {
  unread,
  active,
  sent,
  delivered,
  seen,
  blocked,
  normal,
}

class DmUi {
  static const Color bg = Color(0xFF02050A);
  static const Color panel = Color(0xD00A101B);
  static const Color deepPanel = Color(0xFF0A101B);
  static const Color card = Color(0xE60B111D);

  static const Color gold = Color(0xFFFFC34D);
  static const Color gold2 = Color(0xFFFFE7A8);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purple2 = Color(0xFFA855F7);
  static const Color cyan = Color(0xFF8FD8FF);
  static const Color green = Color(0xFF74F2A8);
  static const Color seenBlue = Color(0xFF5CCBFF);
  static const Color muted = Color(0xFF8B92A1);

  static Color statusColor(DmConversationVisualState state) {
    switch (state) {
      case DmConversationVisualState.unread:
        return gold2;
      case DmConversationVisualState.active:
        return green;
      case DmConversationVisualState.seen:
        return seenBlue;
      case DmConversationVisualState.delivered:
        return gold2.withOpacity(0.74);
      case DmConversationVisualState.sent:
        return gold2.withOpacity(0.58);
      case DmConversationVisualState.blocked:
        return muted.withOpacity(0.52);
      case DmConversationVisualState.normal:
        return muted.withOpacity(0.90);
    }
  }
}

class DmBackground extends StatelessWidget {
  const DmBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: Container(color: DmUi.bg)),
        Positioned(
          top: -165,
          left: -120,
          right: -120,
          child: Container(
            height: 430,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  DmUi.purple2.withOpacity(0.16),
                  DmUi.purple.withOpacity(0.055),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 70,
          right: -145,
          child: Container(
            width: 310,
            height: 310,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  DmUi.cyan.withOpacity(0.045),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -190,
          left: -130,
          right: -130,
          child: Container(
            height: 440,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  DmUi.gold.withOpacity(0.105),
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

class DmEnter extends StatelessWidget {
  const DmEnter({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + index * 55),
      curve: Curves.easeOutCubic,
      builder: (_, t, __) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}

class DmStagger extends StatelessWidget {
  const DmStagger({
    super.key,
    required this.index,
    required this.child,
    this.horizontal = false,
  });

  final int index;
  final Widget child;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final safeIndex = index.clamp(0, 8);

    return TweenAnimationBuilder<double>(
      key: ValueKey("dm_stagger_${horizontal}_$index"),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + safeIndex * 38),
      curve: Curves.easeOutCubic,
      builder: (_, t, __) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: horizontal
                ? Offset(10 * (1 - t), 0)
                : Offset(0, 12 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}

class DmTopBar extends StatelessWidget {
  const DmTopBar({
    super.key,
    required this.unreadCount,
  });

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ShaderMask(
            shaderCallback: (rect) {
              return const LinearGradient(
                colors: [
                  Colors.white,
                  Color(0xFFFFF2C7),
                  DmUi.gold2,
                ],
              ).createShader(rect);
            },
            child: const Text(
              "Messages",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.25,
                height: 1.02,
              ),
            ),
          ),
        ),

        Stack(
          clipBehavior: Clip.none,
          children: [
            IgnorePointer(
              ignoring: true,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: Colors.white.withOpacity(0.065),
                      border: Border.all(
                        color: DmUi.gold2.withOpacity(0.10),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: DmUi.purple.withOpacity(0.16),
                          blurRadius: 24,
                        ),
                        BoxShadow(
                          color: DmUi.gold.withOpacity(0.06),
                          blurRadius: 22,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.chat_bubble_rounded,
                      color: DmUi.gold2.withOpacity(0.78),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),

            if (unreadCount > 0)
              Positioned(
                right: -3,
                top: -3,
                child: IgnorePointer(
                  ignoring: true,
                  child: DmBadge(
                    count: unreadCount,
                    hot: true,
                    small: true,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class DmSearchBar extends StatelessWidget {
  const DmSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;
    final hasText = query.trim().isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 210),
      curve: Curves.easeOutCubic,
      height: focused ? 52 : 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: DmUi.gold.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 210),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: DmUi.panel.withOpacity(focused ? 0.96 : 0.90),
              borderRadius: BorderRadius.circular(23),
              border: Border.all(
                color: focused
                    ? DmUi.gold2.withOpacity(0.22)
                    : Colors.white.withOpacity(0.070),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: focused
                      ? DmUi.gold2.withOpacity(0.86)
                      : Colors.white.withOpacity(0.32),
                  size: 25,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    focusNode: focusNode,
                    controller: controller,
                    autofocus: false,
                    textInputAction: TextInputAction.search,
                    cursorColor: DmUi.gold2,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.25,
                    ),
                    onChanged: onChanged,
                    onSubmitted: (_) => focusNode.unfocus(),
                    onEditingComplete: () => focusNode.unfocus(),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Search people & chats",
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.30),
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: hasText
                      ? GestureDetector(
                          key: const ValueKey("clear"),
                          onTap: onClear,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.055),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white.withOpacity(0.55),
                              size: 20,
                            ),
                          ),
                        )
                      : const SizedBox(
                          key: ValueKey("empty_clear"),
                          width: 22,
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

class DmReplyNowBanner extends StatelessWidget {
  const DmReplyNowBanner({
    super.key,
    required this.unreadCount,
    required this.name,
    required this.onTap,
  });

  final int unreadCount;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DmPressable(
      onTap: onTap,
      scale: 0.985,
      child: DmGoldenPulse(
        child: Container(
          height: 18,
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              colors: [
                DmUi.gold.withOpacity(0.12),
                DmUi.purple2.withOpacity(0.08),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: DmUi.gold.withOpacity(0.18),
                blurRadius: 34,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: DmUi.purple.withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DmSectionTitle extends StatelessWidget {
  const DmSectionTitle({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    this.elite = false,
    this.unreadEnergy = false,
  });

  final String title;
  final int count;
  final IconData icon;
  final bool elite;
  final bool unreadEnergy;

  @override
  Widget build(BuildContext context) {
    final hot = elite || unreadEnergy;

    return Row(
      children: [
        DmSectionIcon(icon: icon, elite: elite, hot: hot),
        const SizedBox(width: 9),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(hot ? 0.96 : 0.78),
            fontSize: elite ? 20 : 18.5,
            fontWeight: FontWeight.w900,
            letterSpacing: elite ? 0.65 : -0.35,
          ),
        ),
        const SizedBox(width: 10),
        DmBadge(count: count, hot: hot),
      ],
    );
  }
}

class DmBadge extends StatelessWidget {
  const DmBadge({
    super.key,
    required this.count,
    this.hot = false,
    this.small = false,
  });

  final int count;
  final bool hot;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? "99+" : count.toString();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey("badge_${label}${hot}$small"),
        constraints: BoxConstraints(
          minWidth: small ? 22 : 29,
          minHeight: small ? 22 : 29,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: small ? 6 : 8,
          vertical: small ? 3 : 5,
        ),
        decoration: BoxDecoration(
          shape: count < 10 ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: count < 10 ? null : BorderRadius.circular(99),
          gradient: hot
              ? LinearGradient(
                  colors: [
                    DmUi.purple.withOpacity(0.50),
                    DmUi.gold.withOpacity(0.22),
                  ],
                )
              : null,
          color: hot ? null : DmUi.purple.withOpacity(0.18),
          border: Border.all(
            color: hot
                ? DmUi.gold2.withOpacity(0.18)
                : Colors.white.withOpacity(0.08),
          ),
          boxShadow: hot
              ? [
                  BoxShadow(
                    color: DmUi.gold.withOpacity(0.15),
                    blurRadius: 16,
                  ),
                  BoxShadow(
                    color: DmUi.purple.withOpacity(0.20),
                    blurRadius: 18,
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: DmUi.gold2,
              fontSize: small ? 10.5 : 11.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class DmMatchBubble extends StatelessWidget {
  const DmMatchBubble({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.activeNow,
    required this.animateRing,
    required this.avatarTag,
    required this.fallbackIndex,
    required this.onTap,
    required this.onAvatarTap,
  });

  final String name;
  final String imageUrl;
  final bool activeNow;
  final bool animateRing;
  final String avatarTag;
  final int fallbackIndex;
  final VoidCallback onTap;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 94,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              DmSweepRing(
                size: 86,
                animate: animateRing,
                child: DmAvatar(
                  imageUrl: imageUrl,
                  size: 80,
                  tag: avatarTag,
                  fallbackIndex: fallbackIndex,
                  onTap: onAvatarTap,
                ),
              ),

              if (activeNow)
                Positioned(
                  left: 7,
                  bottom: 9,
                  child: IgnorePointer(
                    child: DmOnlineDot(
                      borderColor: const Color(0xFF0B111D),
                      size: 15,
                    ),
                  ),
                ),

              Positioned(
                right: -1,
                bottom: 8,
                child: IgnorePointer(
                  child: DmPulsingBubble(
                    enabled: activeNow,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF111827),
                        border: Border.all(
                          color: DmUi.gold2.withOpacity(0.26),
                        ),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: DmUi.gold2,
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.2,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.48,
            ),
          ),
        ],
      ),
    );
  }
}

class DmRequestCard extends StatelessWidget {
  const DmRequestCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.avatarTag,
    required this.fallbackIndex,
    required this.onTap,
    required this.onAvatarTap,
  });

  final String name;
  final String imageUrl;
  final String avatarTag;
  final int fallbackIndex;
  final VoidCallback onTap;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return DmPressable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(1.1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [
              DmUi.purple2.withOpacity(0.42),
              DmUi.gold.withOpacity(0.22),
              Colors.white.withOpacity(0.045),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: DmUi.purple.withOpacity(0.12),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Container(
          height: 90,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(27),
            color: DmUi.card,
          ),
          child: Row(
            children: [
              DmAvatar(
                imageUrl: imageUrl,
                size: 60,
                tag: avatarTag,
                fallbackIndex: fallbackIndex,
                onTap: onAvatarTap,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "sent you a message request",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: DmUi.gold2.withOpacity(0.78),
                        fontSize: 13.8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_rounded,
                color: DmUi.gold2.withOpacity(0.85),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DmConversationCard extends StatelessWidget {
  const DmConversationCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.message,
    required this.status,
    required this.time,
    required this.visualState,
    required this.activeNow,
    required this.unread,
    required this.lastIsMine,
    required this.pulsing,
    required this.avatarTag,
    required this.fallbackIndex,
    required this.onTap,
    required this.onAvatarTap,
  });

  final String name;
  final String imageUrl;
  final String message;
  final String status;
  final String time;
  final DmConversationVisualState visualState;
  final bool activeNow;
  final bool unread;
  final bool lastIsMine;
  final bool pulsing;
  final String avatarTag;
  final int fallbackIndex;
  final VoidCallback onTap;
  final VoidCallback onAvatarTap;

  bool get blocked => visualState == DmConversationVisualState.blocked;
  bool get seen => visualState == DmConversationVisualState.seen;
  bool get delivered => visualState == DmConversationVisualState.delivered;
  bool get sent => visualState == DmConversationVisualState.sent;

  @override
  Widget build(BuildContext context) {
    final statusColor = DmUi.statusColor(visualState);

    return DmPressable(
      onTap: onTap,
      scale: 0.982,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(1.15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: _outerGradient(),
          boxShadow: _outerShadow(),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          height: 112,
          padding: const EdgeInsets.fromLTRB(14, 0, 13, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(31),
            color: blocked ? DmUi.card.withOpacity(0.55) : DmUi.card,
            border: Border.all(
              color: unread
                  ? DmUi.gold2.withOpacity(0.13)
                  : Colors.white.withOpacity(0.055),
            ),
            gradient: _innerGradient(),
          ),
          child: Opacity(
            opacity: blocked ? 0.55 : 1,
            child: Row(
              children: [
                _avatarBlock(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _topRow(),
                      const SizedBox(height: 7),
                      _messageLine(),
                      const SizedBox(height: 7),
                      _metaLine(statusColor),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _actionButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarBlock() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.all(unread ? 2.2 : 1.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: unread
                ? const SweepGradient(
                    colors: [
                      DmUi.gold2,
                      DmUi.gold,
                      DmUi.purple2,
                      DmUi.cyan,
                      DmUi.gold2,
                    ],
                  )
                : LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.11),
                      Colors.white.withOpacity(0.025),
                    ],
                  ),
            boxShadow: unread
                ? [
                    BoxShadow(
                      color: DmUi.gold.withOpacity(pulsing ? 0.32 : 0.18),
                      blurRadius: pulsing ? 25 : 16,
                    ),
                  ]
                : [],
          ),
          child: DmAvatar(
            imageUrl: imageUrl,
            size: 66,
            tag: avatarTag,
            fallbackIndex: fallbackIndex,
            onTap: onAvatarTap,
          ),
        ),
        if (activeNow && !blocked)
          Positioned(
            right: 1,
            bottom: 3,
            child: DmOnlineDot(
              borderColor: DmUi.card,
              size: 16,
            ),
          ),
        if (unread)
          Positioned(
            right: -1,
            top: 0,
            child: DmUnreadDot(pulsing: pulsing),
          ),
      ],
    );
  }

  Widget _topRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(blocked ? 0.66 : 1),
              fontSize: 19.8,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.60,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          time.isEmpty ? "now" : time,
          maxLines: 1,
          style: TextStyle(
            color: unread
                ? DmUi.gold2.withOpacity(0.98)
                : Colors.white.withOpacity(0.50),
            fontSize: 12.3,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.12,
            height: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _messageLine() {
    return Row(
      children: [
        if (lastIsMine && !unread) ...[
          Icon(
            seen
                ? Icons.done_all_rounded
                : delivered
                    ? Icons.done_all_rounded
                    : Icons.done_rounded,
            size: 17,
            color: seen
                ? DmUi.seenBlue.withOpacity(0.95)
                : DmUi.gold2.withOpacity(0.72),
          ),
          const SizedBox(width: 7),
        ],
        Expanded(
          child: Text(
            message,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unread
                  ? Colors.white
                  : Colors.white.withOpacity(blocked ? 0.40 : 0.88),
              fontSize: unread ? 18.0 : 17.2,
              fontWeight: unread
    ? FontWeight.w900
    : FontWeight.w600,
              letterSpacing: -0.30,
              height: 1.02,
            ),
          ),
        ),
      ],
    );
  }

  Widget _metaLine(Color statusColor) {
    final cleanStatus = status
        .replaceAll("✓✓", "")
        .replaceAll("✓", "")
        .trim();

    return Row(
      children: [
        _miniStatusDot(statusColor),
        const SizedBox(width: 6),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              cleanStatus,
              key: ValueKey(cleanStatus),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: statusColor.withOpacity(unread ? 0.98 : 0.78),
                fontSize: 13.6,
                fontWeight: unread ? FontWeight.w900 : FontWeight.w800,
                letterSpacing: -0.14,
                height: 1.05,
                shadows: [
                  if (!blocked)
                    Shadow(
                      color: statusColor.withOpacity(0.18),
                      blurRadius: 7,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniStatusDot(Color color) {
    IconData icon;

    switch (visualState) {
      case DmConversationVisualState.unread:
        icon = Icons.bolt_rounded;
        break;
      case DmConversationVisualState.active:
        icon = Icons.circle;
        break;
      case DmConversationVisualState.seen:
        icon = Icons.done_all_rounded;
        break;
      case DmConversationVisualState.delivered:
        icon = Icons.done_all_rounded;
        break;
      case DmConversationVisualState.sent:
        icon = Icons.done_rounded;
        break;
      case DmConversationVisualState.blocked:
        icon = Icons.lock_rounded;
        break;
      case DmConversationVisualState.normal:
        icon = Icons.schedule_rounded;
        break;
    }

    return Icon(
      icon,
      color: color.withOpacity(0.90),
      size: visualState == DmConversationVisualState.active ? 7 : 15,
    );
  }

  Widget _actionButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 230),
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: unread
            ? const LinearGradient(
                colors: [DmUi.gold2, DmUi.gold],
              )
            : null,
        color: unread ? null : Colors.white.withOpacity(0.045),
        border: Border.all(
          color: unread
              ? DmUi.gold2.withOpacity(0.30)
              : Colors.white.withOpacity(0.065),
        ),
        boxShadow: unread
            ? [
                BoxShadow(
                  color: DmUi.gold.withOpacity(0.22),
                  blurRadius: 20,
                ),
              ]
            : [],
      ),
      child: Icon(
        blocked
            ? Icons.lock_rounded
            : unread
                ? Icons.arrow_forward_rounded
                : Icons.chevron_right_rounded,
        color: unread ? Colors.black : Colors.white.withOpacity(0.46),
        size: blocked ? 19 : 27,
      ),
    );
  }

  Gradient _outerGradient() {
    if (blocked) {
      return LinearGradient(
        colors: [
          Colors.white.withOpacity(0.035),
          Colors.white.withOpacity(0.018),
        ],
      );
    }

    if (unread) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          DmUi.gold2.withOpacity(0.58),
          DmUi.gold.withOpacity(0.28),
          DmUi.purple2.withOpacity(0.17),
          Colors.white.withOpacity(0.040),
        ],
      );
    }

    if (seen) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          DmUi.seenBlue.withOpacity(0.23),
          DmUi.purple2.withOpacity(0.13),
          Colors.white.withOpacity(0.038),
        ],
      );
    }

    if (activeNow) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          DmUi.green.withOpacity(0.20),
          DmUi.purple2.withOpacity(0.13),
          Colors.white.withOpacity(0.038),
        ],
      );
    }

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        DmUi.purple2.withOpacity(0.25),
        DmUi.cyan.withOpacity(0.075),
        Colors.white.withOpacity(0.036),
      ],
    );
  }

  List<BoxShadow> _outerShadow() {
    if (blocked) return [];

    if (unread) {
      return [
        BoxShadow(
          color: DmUi.gold.withOpacity(pulsing ? 0.32 : 0.19),
          blurRadius: pulsing ? 42 : 30,
          offset: const Offset(0, 13),
        ),
        BoxShadow(
          color: DmUi.purple.withOpacity(0.12),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];
    }

    return [
      BoxShadow(
        color: DmUi.purple.withOpacity(pulsing ? 0.20 : 0.095),
        blurRadius: pulsing ? 32 : 23,
        offset: const Offset(0, 12),
      ),
    ];
  }

  Gradient? _innerGradient() {
    if (unread) {
      return RadialGradient(
        center: Alignment.centerRight,
        radius: 1.15,
        colors: [
          DmUi.gold.withOpacity(pulsing ? 0.17 : 0.105),
          DmUi.card,
          DmUi.card,
        ],
      );
    }

    if (activeNow && !blocked) {
      return RadialGradient(
        center: Alignment.centerLeft,
        radius: 1.22,
        colors: [
          DmUi.green.withOpacity(0.055),
          DmUi.card,
          DmUi.card,
        ],
      );
    }

    if (seen) {
      return RadialGradient(
        center: Alignment.centerRight,
        radius: 1.22,
        colors: [
          DmUi.seenBlue.withOpacity(0.045),
          DmUi.card,
          DmUi.card,
        ],
      );
    }

    return null;
  }
}

class DmOnlineDot extends StatelessWidget {
  const DmOnlineDot({
    super.key,
    required this.borderColor,
    this.size = 16,
  });

  final Color borderColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DmPulseOrb(
      size: size,
      subtle: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: DmUi.green,
          border: Border.all(color: borderColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: DmUi.green.withOpacity(0.45),
              blurRadius: 10,
            ),
          ],
        ),
      ),
    );
  }
}

class DmUnreadDot extends StatelessWidget {
  const DmUnreadDot({
    super.key,
    required this.pulsing,
  });

  final bool pulsing;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: DmUi.gold2,
        boxShadow: [
          BoxShadow(
            color: DmUi.gold.withOpacity(0.65),
            blurRadius: 10,
          ),
        ],
      ),
    );

    if (!pulsing) return dot;

    return DmPulseOrb(size: 12, child: dot);
  }
}

class DmAvatar extends StatelessWidget {
  const DmAvatar({
    super.key,
    required this.imageUrl,
    required this.size,
    required this.tag,
    required this.fallbackIndex,
    this.onTap,
  });

  final String imageUrl;
  final double size;
  final String tag;
  final int fallbackIndex;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = Hero(
      tag: tag,
      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return DmAvatarFallback(index: fallbackIndex, size: size);
                },
              )
            : DmAvatarFallback(index: fallbackIndex, size: size),
      ),
    );

    if (onTap == null) return avatar;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: avatar,
    );
  }
}

class DmAvatarFallback extends StatelessWidget {
  const DmAvatarFallback({
    super.key,
    required this.index,
    required this.size,
  });

  final int index;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = [
      [DmUi.gold2, DmUi.gold],
      [DmUi.purple, DmUi.purple2],
      [DmUi.cyan, const Color(0xFF6EA8FF)],
      [const Color(0xFFFF8A66), DmUi.gold],
    ][index % 4];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: colors),
      ),
      child: Icon(
        Icons.person_rounded,
        color: Colors.black54,
        size: size * 0.52,
      ),
    );
  }
}

class DmAvatarPreview extends StatelessWidget {
  const DmAvatarPreview({
    super.key,
    required this.tag,
    required this.imageUrl,
    required this.fallbackIndex,
    required this.onClose,
  });

  final String tag;
  final String imageUrl;
  final int fallbackIndex;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.82;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onClose,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Center(
              child: Container(
                width: size * 0.88,
                height: size * 0.88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      DmUi.gold.withOpacity(0.18),
                      DmUi.purple.withOpacity(0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: InteractiveViewer(
                minScale: 0.85,
                maxScale: 3.2,
                child: Hero(
                  tag: tag,
                  child: Container(
                    width: size,
                    height: size,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const SweepGradient(
                        colors: [
                          DmUi.gold2,
                          DmUi.purple2,
                          DmUi.cyan,
                          DmUi.gold2,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: DmUi.gold.withOpacity(0.26),
                          blurRadius: 54,
                        ),
                        BoxShadow(
                          color: DmUi.purple.withOpacity(0.18),
                          blurRadius: 64,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return DmAvatarFallback(
                                  index: fallbackIndex,
                                  size: size,
                                );
                              },
                            )
                          : DmAvatarFallback(
                              index: fallbackIndex,
                              size: size,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DmStartChatSheet extends StatelessWidget {
  const DmStartChatSheet({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.onOpen,
  });

  final String name;
  final String imageUrl;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (_, scale, child) {
        return Transform.scale(
          scale: scale,
          alignment: Alignment.bottomCenter,
          child: child,
        );
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              decoration: BoxDecoration(
                color: const Color(0xF20A101B),
                border: Border(
                  top: BorderSide(color: DmUi.gold2.withOpacity(0.16)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: DmUi.gold.withOpacity(0.14),
                    blurRadius: 42,
                    offset: const Offset(0, -16),
                  ),
                  BoxShadow(
                    color: DmUi.purple.withOpacity(0.20),
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
                        DmAvatar(
                          imageUrl: imageUrl,
                          size: 62,
                          tag: "dm_start_chat_$name",
                          fallbackIndex: 0,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Start the conversation",
                                style: TextStyle(
                                  color: DmUi.gold2.withOpacity(0.95),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        DmPressable(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            onOpen();
                          },
                          scale: 0.94,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [DmUi.gold2, DmUi.gold],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: DmUi.gold.withOpacity(0.24),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.black,
                              size: 26,
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
        ),
      ),
    );
  }
}

class DmEmptyState extends StatelessWidget {
  const DmEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.16),
        Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: DmUi.panel.withOpacity(0.76),
              border: Border.all(color: DmUi.gold2.withOpacity(0.10)),
              boxShadow: [
                BoxShadow(
                  color: DmUi.gold.withOpacity(0.08),
                  blurRadius: 34,
                ),
                BoxShadow(
                  color: DmUi.purple.withOpacity(0.10),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Column(
              children: [
                DmPulseOrb(
                  size: 58,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          DmUi.gold2.withOpacity(0.95),
                          DmUi.gold.withOpacity(0.82),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: DmUi.gold.withOpacity(0.20),
                          blurRadius: 25,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: Colors.black,
                      size: 25,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "No messages yet",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.65,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  "Go live, match, and start conversations.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.58),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class DmLoadingSkeleton extends StatelessWidget {
  const DmLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const DmSkeletonBlock(height: 82, radius: 28),
        const SizedBox(height: 22),
        Row(
          children: [
            Container(
              width: 160,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        ...List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: DmSkeletonBlock(height: 112, radius: 30),
          ),
        ),
      ],
    );
  }
}

class DmSkeletonBlock extends StatefulWidget {
  const DmSkeletonBlock({
    super.key,
    required this.height,
    required this.radius,
  });

  final double height;
  final double radius;

  @override
  State<DmSkeletonBlock> createState() => _DmSkeletonBlockState();
}

class _DmSkeletonBlockState extends State<DmSkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1150),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final t = _controller.value;

          return Container(
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              gradient: LinearGradient(
                begin: Alignment(-1.6 + 3.2 * t, -1),
                end: Alignment(-0.2 + 3.2 * t, 1),
                colors: [
                  Colors.white.withOpacity(0.035),
                  DmUi.gold.withOpacity(0.055),
                  DmUi.purple.withOpacity(0.045),
                  Colors.white.withOpacity(0.035),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.045),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DmPressable extends StatefulWidget {
  const DmPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.985,
  });

  final Widget child;
  final VoidCallback onTap;
  final double scale;

  @override
  State<DmPressable> createState() => _DmPressableState();
}

class _DmPressableState extends State<DmPressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 105),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class DmSectionIcon extends StatefulWidget {
  const DmSectionIcon({
    super.key,
    required this.icon,
    required this.elite,
    required this.hot,
  });

  final IconData icon;
  final bool elite;
  final bool hot;

  @override
  State<DmSectionIcon> createState() => _DmSectionIconState();
}

class _DmSectionIconState extends State<DmSectionIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.elite && !widget.hot) {
      return Icon(
        widget.icon,
        color: DmUi.gold2.withOpacity(0.72),
        size: 19,
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final pulse = 0.72 + (_controller.value * 0.28);

          return Transform.scale(
            scale: widget.elite ? 0.98 + _controller.value * 0.035 : 1,
            child: Icon(
              widget.icon,
              color: DmUi.gold2.withOpacity(pulse),
              size: widget.elite ? 21 : 19,
            ),
          );
        },
      ),
    );
  }
}

class DmSweepRing extends StatefulWidget {
  const DmSweepRing({
    super.key,
    required this.size,
    required this.child,
    this.animate = true,
  });

  final double size;
  final Widget child;
  final bool animate;

  @override
  State<DmSweepRing> createState() => _DmSweepRingState();
}

class _DmSweepRingState extends State<DmSweepRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant DmSweepRing oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.animate && !_controller.isAnimating) _controller.repeat();
    if (!widget.animate && _controller.isAnimating) _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _ring({required double rotation}) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: widget.size,
        height: widget.size,
        padding: const EdgeInsets.all(2.2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const SweepGradient(
            colors: [
              DmUi.gold2,
              DmUi.purple2,
              DmUi.cyan,
              DmUi.gold2,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: DmUi.purple.withOpacity(0.20),
              blurRadius: 24,
            ),
            BoxShadow(
              color: DmUi.gold.withOpacity(0.13),
              blurRadius: 26,
            ),
          ],
        ),
        child: Transform.rotate(
          angle: -rotation,
          child: widget.child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return RepaintBoundary(child: _ring(rotation: 0));
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return _ring(rotation: _controller.value * pi * 2);
        },
      ),
    );
  }
}

class DmPulsingBubble extends StatefulWidget {
  const DmPulsingBubble({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<DmPulsingBubble> createState() => _DmPulsingBubbleState();
}

class _DmPulsingBubbleState extends State<DmPulsingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1450),
  );

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant DmPulsingBubble oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }

    if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          return Transform.scale(
            scale: 1 + _controller.value * 0.045,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class DmPulseOrb extends StatefulWidget {
  const DmPulseOrb({
    super.key,
    required this.child,
    required this.size,
    this.subtle = false,
  });

  final Widget child;
  final double size;
  final bool subtle;

  @override
  State<DmPulseOrb> createState() => _DmPulseOrbState();
}

class _DmPulseOrbState extends State<DmPulseOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.subtle ? 1800 : 1350),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intensity = widget.subtle ? 0.035 : 0.060;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          return Transform.scale(
            scale: 1 + _controller.value * intensity,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class DmGoldenPulse extends StatefulWidget {
  const DmGoldenPulse({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<DmGoldenPulse> createState() => _DmGoldenPulseState();
}

class _DmGoldenPulseState extends State<DmGoldenPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          final t = _controller.value;

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: DmUi.gold.withOpacity(0.055 + 0.055 * t),
                  blurRadius: 22 + 10 * t,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}