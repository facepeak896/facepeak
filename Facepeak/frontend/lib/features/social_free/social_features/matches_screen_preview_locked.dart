import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:frontend/features/social_free/social_flow_screen.dart';

class MatchesScreenPreviewLocked extends StatefulWidget {
  const MatchesScreenPreviewLocked({super.key});

  @override
  State<MatchesScreenPreviewLocked> createState() =>
      _MatchesScreenPreviewLockedState();
}

class _MatchesScreenPreviewLockedState
    extends State<MatchesScreenPreviewLocked> {
  static const Color bg = Color(0xFF02050A);
  static const Color panel = Color(0xCC0A101B);
  static const Color card = Color(0xF0060A12);
  static const Color gold = Color(0xFFFFC34D);
  static const Color gold2 = Color(0xFFFFE7A8);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purple2 = Color(0xFFA855F7);
  static const Color pink = Color(0xFFFF4FD8);
  static const Color cyan = Color(0xFF8FD8FF);

  final List<String> _typingHints = [
    "matching energy...",
    "elite profiles nearby...",
    "someone could match you...",
    "ranked profiles active...",
    "your next match starts here...",
  ];

  Timer? _timer;
  int _hintIndex = 0;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(milliseconds: 1450), (_) {
      if (!mounted) return;
      setState(() {
        _hintIndex = (_hintIndex + 1) % _typingHints.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goLive() {
    HapticFeedback.mediumImpact();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SocialFlow(),
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  final media = MediaQuery.of(context);
  final bottom = media.padding.bottom;

  return Scaffold(
    backgroundColor: bg,
    body: Stack(
      children: [
        Positioned.fill(child: _background()),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentHeight = constraints.maxHeight;
              final previewHeight =
                  (contentHeight * 0.70).clamp(440.0, 560.0);

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  22,
                  14,
                  22,
                  24 + bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: contentHeight,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _top(),
                      const SizedBox(height: 16),
                      _liveSearchStrip(),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: previewHeight,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _matchWorldPreview(),
                            _lockCard(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

  Widget _top() {
    return Row(
      children: [
        Expanded(
          child: ShaderMask(
            shaderCallback: (rect) {
              return const LinearGradient(
                colors: [Colors.white, gold2, pink],
              ).createShader(rect);
            },
            child: const Text(
              "Matches",
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
              ),
            ),
          ),
        ),
        _heartPulse(),
      ],
    );
  }

  Widget _heartPulse() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (_, v, __) {
        return Transform.scale(
          scale: v,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              gradient: LinearGradient(
                colors: [
                  pink.withOpacity(0.36),
                  gold.withOpacity(0.22),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
              boxShadow: [
                BoxShadow(
                  color: pink.withOpacity(0.20),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: gold.withOpacity(0.16),
                  blurRadius: 24,
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: gold2,
              size: 25,
            ),
          ),
        );
      },
    );
  }

  Widget _liveSearchStrip() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: pink.withOpacity(0.07),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: gold2.withOpacity(0.82),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (child, anim) {
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.16),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    _typingHints[_hintIndex],
                    key: ValueKey(_typingHints[_hintIndex]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.44),
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: gold2,
                  boxShadow: [
                    BoxShadow(
                      color: gold.withOpacity(0.65),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _matchWorldPreview() {
    return IgnorePointer(
      child: ShaderMask(
        shaderCallback: (rect) {
          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.95),
              Colors.white.withOpacity(0.72),
              Colors.white.withOpacity(0.14),
            ],
            stops: const [0.0, 0.58, 1.0],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 9,
          itemBuilder: (_, i) => _ghostMatchRow(i),
        ),
      ),
    );
  }

  Widget _ghostMatchRow(int i) {
    final hot = i == 0 || i == 1 || i == 3;
    final colors = _avatarColors(i);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.94, end: 1),
      duration: Duration(milliseconds: 620 + (i % 4) * 90),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) {
        return Transform.scale(scale: v, child: child);
      },
      child: Opacity(
        opacity: i > 5 ? 0.42 : 0.74,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(1.1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [
                hot ? gold.withOpacity(0.50) : colors.first.withOpacity(0.28),
                hot ? pink.withOpacity(0.20) : purple.withOpacity(0.14),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: (hot ? gold : colors.first).withOpacity(0.13),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(27),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 6.5, sigmaY: 6.5),
              child: Container(
                height: 94,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: panel,
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    _fakeAvatar(i),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _line(
                            width: i.isEven ? 0.38 : 0.30,
                            opacity: hot ? 0.28 : 0.18,
                          ),
                          const SizedBox(height: 11),
                          _line(
                            width: i.isEven ? 0.58 : 0.46,
                            opacity: hot ? 0.16 : 0.10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 26,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: hot
                            ? const LinearGradient(colors: [gold, gold2])
                            : null,
                        color: hot ? null : Colors.white.withOpacity(0.08),
                        border: Border.all(
                          color: hot
                              ? Colors.transparent
                              : Colors.white.withOpacity(0.08),
                        ),
                        boxShadow: hot
                            ? [
                                BoxShadow(
                                  color: gold.withOpacity(0.24),
                                  blurRadius: 16,
                                ),
                              ]
                            : null,
                      ),
                      child: hot
                          ? const Icon(
                              Icons.favorite_rounded,
                              color: Colors.black,
                              size: 15,
                            )
                          : null,
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

  Widget _line({
    required double width,
    required double opacity,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * width,
      height: 13,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }

  Widget _fakeAvatar(int i) {
    final colors = _avatarColors(i);

    return Container(
      width: 60,
      height: 60,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            colors.first,
            colors.last,
            pink,
            colors.first,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.30),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.35, -0.45),
              radius: 1.0,
              colors: [
                colors.last.withOpacity(0.95),
                colors.first.withOpacity(0.72),
                const Color(0xFF05080E),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _avatarColors(int i) {
    final sets = [
      [gold2, gold],
      [pink, purple2],
      [cyan, const Color(0xFF6EA8FF)],
      [const Color(0xFFFF8A66), gold],
      [const Color(0xFF66FFD1), cyan],
    ];

    return sets[i % sets.length];
  }

  Widget _lockCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 560),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) {
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - v)),
            child: Transform.scale(
              scale: 0.96 + (0.04 * v),
              child: child,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: gold2.withOpacity(0.16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.44),
                  blurRadius: 36,
                  offset: const Offset(0, 22),
                ),
                BoxShadow(
                  color: pink.withOpacity(0.14),
                  blurRadius: 42,
                ),
                BoxShadow(
                  color: gold.withOpacity(0.12),
                  blurRadius: 44,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _matchBadge(),
                const SizedBox(height: 20),
                const Text(
                  "🔥 Matches are close",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.9,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Go live so people can discover you, react to your profile and turn attention into matches.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.60),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    height: 1.26,
                  ),
                ),
                const SizedBox(height: 22),
                _cta(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _matchBadge() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (_, v, __) {
        return Transform.scale(
          scale: v,
          child: Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [gold, gold2]),
              boxShadow: [
                BoxShadow(
                  color: gold.withOpacity(0.38),
                  blurRadius: 36,
                ),
                BoxShadow(
                  color: pink.withOpacity(0.20),
                  blurRadius: 34,
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.black,
              size: 44,
            ),
          ),
        );
      },
    );
  }

  Widget _cta() {
    return GestureDetector(
      onTap: _goLive,
      onTapDown: (_) => HapticFeedback.selectionClick(),
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(colors: [gold, gold2]),
          boxShadow: [
            BoxShadow(
              color: gold.withOpacity(0.30),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_pin_circle_rounded,
              color: Colors.black,
              size: 22,
            ),
            SizedBox(width: 9),
            Text(
              "Go live from Profile",
              style: TextStyle(
                color: Colors.black,
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _background() {
    return Stack(
      children: [
        Positioned.fill(child: Container(color: bg)),
        Positioned(
          top: -160,
          left: -110,
          right: -110,
          child: Container(
            height: 430,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  pink.withOpacity(0.13),
                  purple.withOpacity(0.10),
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
            height: 450,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  gold.withOpacity(0.15),
                  gold.withOpacity(0.035),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 230,
          right: -130,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  purple2.withOpacity(0.10),
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