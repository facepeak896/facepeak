import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  static const Color bg = Color(0xFF070B12);

  static const Color gold = Color(0xFFFFC34D);
  static const Color gold2 = Color(0xFFFFD978);
  static const Color gold3 = Color(0xFFFFE7A8);

  static const Color purple = Color(0xFF7C3AED);
  static const Color cyan = Color(0xFF8FD8FF);

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _openPremium() {
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "Premium analytics coming soon.",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: purple,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          _background(),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
              child: Column(
                children: [
                  _topBar(),

                  const SizedBox(height: 24),

                  _hero(),

                  const SizedBox(height: 26),

                  _premiumCard(),

                  const SizedBox(height: 18),

                  _blurredAnalytics(),

                  const SizedBox(height: 18),

                  _insights(),

                  const SizedBox(height: 24),

                  _bottomButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _background() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final g = _pulse.value;

          return Stack(
            children: [
              Positioned(
                top: -180,
                left: -120,
                right: -120,
                child: Container(
                  height: 360,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        gold.withOpacity(0.08 + g * 0.03),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 260,
                left: -140,
                right: -140,
                child: Container(
                  height: 320,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        purple.withOpacity(0.10 + g * 0.03),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        _glassIcon(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _glassIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            final g = _pulse.value;

            return Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [gold2, gold3],
                ),
                boxShadow: [
                  BoxShadow(
                    color: gold.withOpacity(0.22 + g * 0.10),
                    blurRadius: 34 + g * 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.insights_rounded,
                color: Colors.black,
                size: 58,
              ),
            );
          },
        ),

        const SizedBox(height: 26),

        const Text(
          "Elite Analytics",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 42,
            height: 0.95,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.4,
          ),
        ),

        const SizedBox(height: 14),

        Text(
          "Unlock advanced profile intelligence\nand growth insights.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.70),
            fontSize: 17,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _premiumCard() {
    return Container(
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            gold.withOpacity(0.35),
            purple.withOpacity(0.28),
            Colors.white.withOpacity(0.05),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(29),
          color: const Color(0xCC0C1018),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gold.withOpacity(0.14),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: gold3,
                size: 28,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Premium Required",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "See profile reach, ranking trends,\nmatch conversion and hidden stats.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.62),
                      fontSize: 13.5,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blurredAnalytics() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        children: [
          Column(
            children: [
              _fakeMetric(
                title: "Profile Reach",
                value: "18.4K",
                subtitle: "+241% this week",
                color: cyan,
              ),
              const SizedBox(height: 14),
              _fakeMetric(
                title: "Match Conversion",
                value: "74%",
                subtitle: "Top performing metric",
                color: purple,
              ),
              const SizedBox(height: 14),
              _fakeMetric(
                title: "Visibility Score",
                value: "92",
                subtitle: "Higher than 88% users",
                color: gold3,
              ),
            ],
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 18,
                sigmaY: 18,
              ),
              child: Container(
                color: Colors.black.withOpacity(0.18),
              ),
            ),
          ),

          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      gold3.withOpacity(0.94),
                      gold.withOpacity(0.92),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gold.withOpacity(0.28),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      color: Colors.black,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "LOCKED",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fakeMetric({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withOpacity(0.045),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.14),
            ),
            child: Icon(
              Icons.auto_graph_rounded,
              color: color,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _insights() {
    return Column(
      children: [
        _insightTile(
          icon: Icons.visibility_rounded,
          title: "Who viewed your profile",
        ),
        const SizedBox(height: 12),
        _insightTile(
          icon: Icons.favorite_rounded,
          title: "Match success analytics",
        ),
        const SizedBox(height: 12),
        _insightTile(
          icon: Icons.trending_up_rounded,
          title: "Growth trend predictions",
        ),
      ],
    );
  }

  Widget _insightTile({
    required IconData icon,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.045),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: gold.withOpacity(0.12),
            ),
            child: Icon(
              icon,
              color: gold3,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          Icon(
            Icons.lock_rounded,
            color: Colors.white.withOpacity(0.38),
          ),
        ],
      ),
    );
  }

  Widget _bottomButton() {
    return GestureDetector(
      onTap: _openPremium,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final g = _pulse.value;

          return Container(
            width: double.infinity,
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [gold, gold3],
              ),
              boxShadow: [
                BoxShadow(
                  color: gold.withOpacity(0.24 + g * 0.08),
                  blurRadius: 26 + g * 8,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.black,
                ),
                SizedBox(width: 10),
                Text(
                  "UNLOCK PREMIUM",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}