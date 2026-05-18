import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BottomTabBarElite extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabChange;

  final bool showSocialBadge;
  final VoidCallback? onSocialBadgeSeen;

  final int messageBadgeCount;
  final int matchBadgeCount;
  final int followBadgeCount;

  final VoidCallback? onMessageBadgeSeen;
  final VoidCallback? onMatchBadgeSeen;
  final VoidCallback? onFollowBadgeSeen;

  const BottomTabBarElite({
    super.key,
    required this.currentIndex,
    required this.onTabChange,
    this.showSocialBadge = false,
    this.onSocialBadgeSeen,
    this.messageBadgeCount = 0,
    this.matchBadgeCount = 0,
    this.followBadgeCount = 0,
    this.onMessageBadgeSeen,
    this.onMatchBadgeSeen,
    this.onFollowBadgeSeen,
  });

  @override
  State<BottomTabBarElite> createState() => _BottomTabBarEliteState();
}

class _BottomTabBarEliteState extends State<BottomTabBarElite>
    with TickerProviderStateMixin {
  late final AnimationController _socialCtrl;
  late final AnimationController _messagePopCtrl;
  late final AnimationController _matchPopCtrl;
  late final AnimationController _followPopCtrl;

  int _lastMessageAnimatedCount = 0;
  int _lastMatchAnimatedCount = 0;
  int _lastFollowAnimatedCount = 0;

  DateTime? _lastMessageAnimAt;
  DateTime? _lastMatchAnimAt;
  DateTime? _lastFollowAnimAt;

  static const Color _bg = Color(0xFF05070D);

  static const Color _goldLight = Color(0xFFF8EFCB);
  static const Color _gold = Color(0xFFE8C76A);
  static const Color _goldDeep = Color(0xFFC3922E);

  static const Color _purple = Color(0xFF7C3AED);
  static const Color _purpleLight = Color(0xFFA855F7);

  static const Color _pink2 = Color(0xFFFF7AE6);

  static const Color _cyan = Color(0xFF8FD8FF);
  static const Color _blue = Color(0xFF3B82F6);

  static const Color _red = Color(0xFFFF3B6B);
  static const Color _red2 = Color(0xFFFF8A9E);

  @override
  void initState() {
    super.initState();

    _socialCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _messagePopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _matchPopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _followPopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    if (widget.showSocialBadge) _socialCtrl.forward(from: 0);

    _lastMessageAnimatedCount = widget.messageBadgeCount;
    _lastMatchAnimatedCount = widget.matchBadgeCount;
    _lastFollowAnimatedCount = widget.followBadgeCount;
  }

  @override
  void didUpdateWidget(covariant BottomTabBarElite oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.showSocialBadge && widget.showSocialBadge) {
      _socialCtrl.forward(from: 0);
    }

    final now = DateTime.now();

    if (_shouldAnimateBadge(
      oldCount: oldWidget.messageBadgeCount,
      newCount: widget.messageBadgeCount,
      lastAnimatedCount: _lastMessageAnimatedCount,
      lastAnimAt: _lastMessageAnimAt,
    )) {
      _lastMessageAnimatedCount = widget.messageBadgeCount;
      _lastMessageAnimAt = now;
      _messagePopCtrl.forward(from: 0);
    }

    if (_shouldAnimateBadge(
      oldCount: oldWidget.matchBadgeCount,
      newCount: widget.matchBadgeCount,
      lastAnimatedCount: _lastMatchAnimatedCount,
      lastAnimAt: _lastMatchAnimAt,
    )) {
      _lastMatchAnimatedCount = widget.matchBadgeCount;
      _lastMatchAnimAt = now;
      _matchPopCtrl.forward(from: 0);
    }

    if (_shouldAnimateBadge(
      oldCount: oldWidget.followBadgeCount,
      newCount: widget.followBadgeCount,
      lastAnimatedCount: _lastFollowAnimatedCount,
      lastAnimAt: _lastFollowAnimAt,
    )) {
      _lastFollowAnimatedCount = widget.followBadgeCount;
      _lastFollowAnimAt = now;
      _followPopCtrl.forward(from: 0);
    }
  }

  bool _shouldAnimateBadge({
    required int oldCount,
    required int newCount,
    required int lastAnimatedCount,
    required DateTime? lastAnimAt,
  }) {
    if (newCount <= 0) return false;
    if (newCount <= oldCount) return false;
    if (newCount <= lastAnimatedCount) return false;

    final now = DateTime.now();
    if (lastAnimAt != null &&
        now.difference(lastAnimAt).inMilliseconds < 650) {
      return false;
    }

    return true;
  }

  @override
  void dispose() {
    _socialCtrl.dispose();
    _messagePopCtrl.dispose();
    _matchPopCtrl.dispose();
    _followPopCtrl.dispose();
    super.dispose();
  }

  int _cap(int count) => count.clamp(0, 99);

  void _stopBadgeAnimation(int index) {
    if (index == 1) {
      _messagePopCtrl.stop();
      _messagePopCtrl.value = 0;
    }

    if (index == 3) {
      _matchPopCtrl.stop();
      _matchPopCtrl.value = 0;
    }

    if (index == 4) {
      _followPopCtrl.stop();
      _followPopCtrl.value = 0;
    }
  }

  void _go(int index) {
    _stopBadgeAnimation(index);

    if (index == 1 && widget.messageBadgeCount > 0) {
      widget.onMessageBadgeSeen?.call();
    }

    if (index == 3 && widget.matchBadgeCount > 0) {
      widget.onMatchBadgeSeen?.call();
    }

    if (index == 4 && widget.followBadgeCount > 0) {
      widget.onFollowBadgeSeen?.call();
    }

    if ((index == 1 || index == 2 || index == 3 || index == 4) &&
        widget.showSocialBadge) {
      widget.onSocialBadgeSeen?.call();
    }

    widget.onTabChange(index);
  }

  IconData _iconFor(int index) {
    switch (index) {
      case 0:
        return Icons.home_outlined;
      case 1:
        return Icons.chat_bubble_outline_rounded;
      case 2:
        return Icons.search_rounded;
      case 3:
        return Icons.favorite_border_rounded;
      case 4:
        return Icons.person_outline_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  String _countText(int count) {
    final c = _cap(count);
    return c >= 99 ? "99+" : c.toString();
  }

  Widget _attachedBadge({
    required int count,
    required Color color,
    required Color color2,
    required AnimationController? controller,
  }) {
    if (count <= 0) return const SizedBox.shrink();

    final c = _cap(count);

    return AnimatedBuilder(
      animation: controller ?? kAlwaysDismissedAnimation,
      builder: (_, child) {
        final raw = controller?.value ?? 0.0;

        final pop = controller?.isAnimating == true
            ? Curves.elasticOut.transform(raw.clamp(0.0, 1.0))
            : 1.0;

        final scale = controller?.isAnimating == true ? 0.82 + pop * 0.18 : 1.0;

        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        constraints: BoxConstraints(
          minWidth: c > 99 ? 27 : c > 9 ? 25 : 20,
          minHeight: 20,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: c > 9 ? 6 : 0,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color2, color],
          ),
          border: Border.all(
            color: _bg,
            width: 2.2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.52),
              blurRadius: 10,
              spreadRadius: 0.3,
            ),
          ],
        ),
        child: Center(
          child: Text(
            _countText(c),
            maxLines: 1,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.8,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialBadge() {
    return AnimatedBuilder(
      animation: _socialCtrl,
      builder: (context, _) {
        final raw = _socialCtrl.value.clamp(0.0, 1.0);

        final appear = Curves.easeOutBack.transform(
          (raw / 0.28).clamp(0.0, 1.0),
        );

        final settle = Curves.easeOutCubic.transform(
          ((raw - 0.50) / 0.50).clamp(0.0, 1.0),
        );

        final width = 36 - (16 * settle);
        final height = 24 - (4 * settle);
        final scale = 0.78 + appear * 0.22;

        return Opacity(
          opacity: appear,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  colors: [_goldLight, _gold, _goldDeep],
                ),
                border: Border.all(color: _bg, width: 2.1),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withOpacity(0.52),
                    blurRadius: 13,
                  ),
                ],
              ),
              child: Center(
                child: settle < 0.65
                    ? const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.black,
                        size: 13,
                      )
                    : const Text(
                        "!",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _iconWithBadge({
    required Widget icon,
    required int count,
    required Color badgeColor,
    required Color badgeColor2,
    required AnimationController? controller,
    bool socialBadge = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        icon,

        if (count > 0)
          Positioned(
            top: -8,
            right: -10,
            child: _attachedBadge(
              count: count,
              color: badgeColor,
              color2: badgeColor2,
              controller: controller,
            ),
          ),

        if (socialBadge)
          Positioned(
            top: -8,
            right: -11,
            child: _socialBadge(),
          ),
      ],
    );
  }

  Widget _tab(int index) {
    final active = index == widget.currentIndex;
    final isSearch = index == 2;
    final isMessage = index == 1;
    final isMatch = index == 3;
    final isProfile = index == 4;

    final count = isMessage
        ? widget.messageBadgeCount
        : isMatch
            ? widget.matchBadgeCount
            : isProfile
                ? widget.followBadgeCount
                : 0;

    final badgeColor = isMessage
        ? _blue
        : isMatch
            ? _purple
            : isProfile
                ? _red
                : _goldDeep;

    final badgeColor2 = isMessage
        ? _cyan
        : isMatch
            ? _pink2
            : isProfile
                ? _red2
                : _goldLight;

    final popController = isMessage
        ? _messagePopCtrl
        : isMatch
            ? _matchPopCtrl
            : isProfile
                ? _followPopCtrl
                : null;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _go(index),
        child: TweenAnimationBuilder<double>(
          tween: Tween(
            begin: 1,
            end: active
                ? isSearch
                    ? 1.14
                    : 1.10
                : 1,
          ),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          builder: (_, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(vertical: isSearch ? 3 : 6),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (active)
                  Container(
                    width: isSearch ? 64 : 54,
                    height: isSearch ? 64 : 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          (isSearch ? _purpleLight : _gold).withOpacity(0.18),
                          (isSearch ? _purple : _goldDeep).withOpacity(0.07),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                if (isSearch)
                  Container(
                    width: active ? 64 : 58,
                    height: active ? 64 : 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: active
                            ? [
                                _goldLight.withOpacity(0.95),
                                _gold.withOpacity(0.95),
                              ]
                            : [
                                Colors.white.withOpacity(0.075),
                                Colors.white.withOpacity(0.035),
                              ],
                      ),
                      border: Border.all(
                        color: active
                            ? _goldLight.withOpacity(0.38)
                            : Colors.white.withOpacity(0.07),
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: _gold.withOpacity(0.36),
                                blurRadius: 22,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: _purple.withOpacity(0.22),
                                blurRadius: 24,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      size: active ? 34 : 31,
                      color: active
                          ? Colors.black
                          : Colors.white.withOpacity(0.56),
                    ),
                  )
                else
                  _iconWithBadge(
                    count: count,
                    badgeColor: badgeColor,
                    badgeColor2: badgeColor2,
                    controller: popController,
                    socialBadge: index == 4 && widget.showSocialBadge,
                    icon: Icon(
                      _iconFor(index),
                      size: active ? 34 : 31,
                      color: active
                          ? _goldLight
                          : Colors.white.withOpacity(0.38),
                      shadows: active
                          ? [
                              Shadow(
                                color: _goldDeep.withOpacity(0.45),
                                blurRadius: 10,
                              ),
                              Shadow(
                                color: _gold.withOpacity(0.26),
                                blurRadius: 16,
                              ),
                            ]
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final bottomInset = media.padding.bottom;
    final tabWidth = width / 5;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: _bg,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return SizedBox(
      width: double.infinity,
      height: 88 + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: Container(color: _bg)),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 18,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _gold.withOpacity(0.065),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset > 0 ? bottomInset : 10,
            child: SizedBox(
              height: 88,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    bottom: 8,
                    left: (tabWidth * widget.currentIndex) +
                        (tabWidth / 2) -
                        19,
                    child: Container(
                      width: 38,
                      height: 5.5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          colors: [_goldDeep, _gold, _goldLight],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _gold.withOpacity(0.68),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _tab(0),
                      _tab(1),
                      _tab(2),
                      _tab(3),
                      _tab(4),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}