import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:frontend/features/social_free/social_flow_screen.dart';

class DmScreenPreviewLocked extends StatefulWidget {
  const DmScreenPreviewLocked({super.key});

  @override
  State<DmScreenPreviewLocked> createState() => _DmScreenPreviewLockedState();
}

class _DmScreenPreviewLockedState extends State<DmScreenPreviewLocked> {
  static const Color bg = Color(0xFF02050A);
  static const Color panel = Color(0xCC0A101B);
  static const Color card = Color(0xF0060A12);
  static const Color gold = Color(0xFFFFC34D);
  static const Color gold2 = Color(0xFFFFE7A8);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purple2 = Color(0xFFA855F7);
  static const Color blue = Color(0xFF8FD8FF);

  final List<String> _typingHints = [
    "new match message...",
    "profile interaction...",
    "someone viewed you...",
    "reply waiting...",
  ];

  Timer? _timer;
  int _hintIndex = 0;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
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
                      _search(),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: previewHeight,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _liveInboxPreview(),
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
                colors: [Colors.white, gold2, purple2],
              ).createShader(rect);
            },
            child: const Text(
              "Messages",
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
              ),
            ),
          ),
        ),
        _liveBadge(),
      ],
    );
  }

  Widget _liveBadge() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        gradient: LinearGradient(
          colors: [
            purple.withOpacity(0.36),
            gold.withOpacity(0.18),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: gold.withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(
        Icons.bolt_rounded,
        color: gold2,
        size: 26,
      ),
    );
  }

  Widget _search() {
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
                color: purple.withOpacity(0.07),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: gold2.withOpacity(0.72),
                size: 25,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: Text(
                    _typingHints[_hintIndex],
                    key: ValueKey(_typingHints[_hintIndex]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.42),
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

  Widget _liveInboxPreview() {
    return IgnorePointer(
      child: ShaderMask(
        shaderCallback: (rect) {
          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.92),
              Colors.white.withOpacity(0.72),
              Colors.white.withOpacity(0.12),
            ],
            stops: const [0.0, 0.58, 1.0],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 9,
          itemBuilder: (_, i) => _ghostMessageRow(i),
        ),
      ),
    );
  }

  Widget _ghostMessageRow(int i) {
    final hot = i == 0 || i == 2;
    final colors = _avatarColors(i);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.94, end: 1),
      duration: Duration(milliseconds: 620 + (i % 4) * 90),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) {
        return Transform.scale(scale: v, child: child);
      },
      child: Opacity(
        opacity: i > 5 ? 0.42 : 0.72,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(1.1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [
                hot ? gold.withOpacity(0.52) : colors.first.withOpacity(0.28),
                hot ? purple2.withOpacity(0.22) : Colors.white.withOpacity(0.05),
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
                height: 92,
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
                          _line(width: i.isEven ? 0.38 : 0.30, opacity: hot ? 0.28 : 0.18),
                          const SizedBox(height: 11),
                          _line(width: i.isEven ? 0.62 : 0.48, opacity: hot ? 0.16 : 0.10),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (hot)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [gold, gold2]),
                          boxShadow: [
                            BoxShadow(
                              color: gold.withOpacity(0.62),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: 30,
                        height: 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.white.withOpacity(0.08),
                        ),
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

  Widget _line({required double width, required double opacity}) {
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
      padding: const EdgeInsets.all(1.4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            colors.first,
            colors.last,
            purple2,
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
      [purple, purple2],
      [blue, const Color(0xFF6EA8FF)],
      [const Color(0xFFFF8A66), gold],
      [const Color(0xFF66FFD1), blue],
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
                  color: gold.withOpacity(0.15),
                  blurRadius: 42,
                ),
                BoxShadow(
                  color: purple.withOpacity(0.16),
                  blurRadius: 44,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _messageBadge(),
                const SizedBox(height: 20),
                const Text(
                  "🔥 Messages are waiting",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.9,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Go live to receive real messages from matches and profile interactions.",
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

  Widget _messageBadge() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (_, v, __) {
        return Transform.scale(
          scale: v,
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [gold, gold2]),
              boxShadow: [
                BoxShadow(
                  color: gold.withOpacity(0.38),
                  blurRadius: 36,
                ),
              ],
            ),
            child: const Icon(
              Icons.chat_bubble_rounded,
              color: Colors.black,
              size: 42,
            ),
          ),
        );
      },
    );
  }

  Widget _cta() {
    return GestureDetector(
      onTap: _goLive,
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
                  blue.withOpacity(0.13),
                  purple.withOpacity(0.08),
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
                  purple2.withOpacity(0.09),
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