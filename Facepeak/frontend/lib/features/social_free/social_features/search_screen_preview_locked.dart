import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/features/social_free/social_flow_screen.dart';

class SearchScreenPreviewLocked extends StatefulWidget {
  const SearchScreenPreviewLocked({super.key});

  @override
  State<SearchScreenPreviewLocked> createState() =>
      _SearchScreenPreviewLockedState();
}

class _SearchScreenPreviewLockedState extends State<SearchScreenPreviewLocked> {
  static const Color bg = Color(0xFF02050A);
  static const Color panel = Color(0xD00A101B);
  static const Color card = Color(0xEE080D16);
  static const Color gold = Color(0xFFFFC34D);
  static const Color gold2 = Color(0xFFFFE7A8);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purple2 = Color(0xFFA855F7);
  static const Color cyan = Color(0xFF8FD8FF);

  final List<String> _typingHints = [
    "people near you",
    "top 10%",
    "#rank",
    "elite profiles",
    "new live users",
  ];

  Timer? _typingTimer;
  int _typingIndex = 0;

  @override
  void initState() {
    super.initState();

    _typingTimer = Timer.periodic(const Duration(milliseconds: 1450), (_) {
      if (!mounted) return;
      setState(() {
        _typingIndex = (_typingIndex + 1) % _typingHints.length;
      });
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
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
                  (contentHeight * 0.68).clamp(430.0, 540.0);

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
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
                      const SizedBox(height: 18),
                      _searchBar(),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: previewHeight,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _blurredFeed(),
                            _lockedCard(),
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
              "Search",
              style: TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.4,
              ),
            ),
          ),
        ),
        _liveIcon(),
      ],
    );
  }

  Widget _liveIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.88, end: 1),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeInOut,
      builder: (_, v, __) {
        return Transform.scale(
          scale: v,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  purple.withOpacity(0.42),
                  gold.withOpacity(0.22),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
              boxShadow: [
                BoxShadow(
                  color: gold.withOpacity(0.24),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: gold2,
              size: 28,
            ),
          ),
        );
      },
    );
  }

  Widget _searchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withOpacity(0.09)),
            boxShadow: [
              BoxShadow(
                color: purple.withOpacity(0.11),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: gold2.withOpacity(0.86),
                size: 28,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.18),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    _typingHints[_typingIndex],
                    key: ValueKey(_typingHints[_typingIndex]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.54),
                      fontSize: 18,
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

  Widget _blurredFeed() {
    return IgnorePointer(
      child: Column(
        children: [
          _ghostRow(0, width: 0.92),
          const SizedBox(height: 16),
          _ghostRow(1, width: 0.82),
          const SizedBox(height: 16),
          _ghostRow(2, width: 0.94),
          const SizedBox(height: 16),
          _ghostRow(3, width: 0.78),
        ],
      ),
    );
  }

  Widget _ghostRow(int i, {required double width}) {
    return Opacity(
      opacity: 0.55,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: MediaQuery.of(context).size.width * width,
            height: 112,
            padding: const EdgeInsets.all(1.1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: [
                  gold.withOpacity(i.isEven ? 0.34 : 0.16),
                  purple.withOpacity(i.isEven ? 0.18 : 0.32),
                  cyan.withOpacity(0.08),
                ],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(29),
                color: Colors.white.withOpacity(0.055),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: i.isEven
                            ? [gold2, purple2]
                            : [cyan, purple],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _skeletonLine(width: 1),
                        const SizedBox(height: 10),
                        _skeletonLine(width: 0.65),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: gold.withOpacity(0.22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _skeletonLine({required double width}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.42 * width,
        height: 14,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.white.withOpacity(0.16),
        ),
      ),
    );
  }

  Widget _lockedCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
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
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
              boxShadow: [
                BoxShadow(
                  color: gold.withOpacity(0.16),
                  blurRadius: 42,
                  offset: const Offset(0, 22),
                ),
                BoxShadow(
                  color: purple.withOpacity(0.20),
                  blurRadius: 44,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _fireBadge(),
                const SizedBox(height: 20),
                const Text(
                  "🔥 People are looking",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.02,
                    letterSpacing: -0.9,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Go live to enter the feed, get seen and start turning attention into matches.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.58),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
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

  Widget _fireBadge() {
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
              ],
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.black,
              size: 46,
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
                  purple2.withOpacity(0.20),
                  purple.withOpacity(0.075),
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
            height: 460,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  gold.withOpacity(0.16),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 210,
          right: -120,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  cyan.withOpacity(0.07),
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