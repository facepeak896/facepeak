import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SocialExplainerScreen extends StatefulWidget {
  const SocialExplainerScreen({super.key});

  @override
  State<SocialExplainerScreen> createState() => _SocialExplainerScreenState();
}

class _SocialExplainerScreenState extends State<SocialExplainerScreen>
    with TickerProviderStateMixin {
  static const Color bg = Color(0xFF070B12);

  static const Color gold1 = Color(0xFFBA8C22);
  static const Color gold2 = Color(0xFFF0CF5A);
  static const Color gold3 = Color(0xFFFFE7A6);
  static const Color gold4 = Color(0xFFFFF3D0);

  static const Color purple = Color(0xFF7C3AED);

  late final AnimationController _screen;
  late final AnimationController _heroGlow;
  late final AnimationController _searchPulse;

  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact();

    _screen = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();

    _heroGlow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _searchPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _screen.dispose();
    _heroGlow.dispose();
    _searchPulse.dispose();
    super.dispose();
  }

  void _closeHelpful() {
    HapticFeedback.mediumImpact();
    Navigator.pop(context, true);
  }

  void _closeNotHelpful() {
    HapticFeedback.selectionClick();
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    final reveal = CurvedAnimation(
      parent: _screen,
      curve: Curves.easeOutCubic,
    );

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([_screen, _heroGlow, _searchPulse]),
          builder: (context, _) {
            final heroGlow = _heroGlow.value;

            return Opacity(
              opacity: reveal.value,
              child: Transform.translate(
                offset: Offset(0, 14 * (1 - reveal.value)),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0, -0.16),
                              radius: 0.95,
                              colors: [
                                gold2.withOpacity(0.08 + heroGlow * 0.03),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _topButton(
                                icon: Icons.arrow_back_ios_new_rounded,
                                onTap: _closeNotHelpful,
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: Colors.white.withOpacity(0.022),
                                  border: Border.all(
                                    color: gold2.withOpacity(0.14),
                                  ),
                                ),
                                child: Text(
                                  "HOW SOCIAL WORKS",
                                  style: TextStyle(
                                    color: gold3,
                                    fontSize: 11.2,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _heroOrb(heroGlow),
                          const SizedBox(height: 14),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [gold2, gold3, gold4],
                            ).createShader(bounds),
                            child: const Text(
                              "Everything starts with search",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.0,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Get attention. Get matches. Get noticed.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                              height: 1.12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Column(
                              children: [
                                _SearchFeatureCard(
                                  pulse: _searchPulse,
                                ),
                                const SizedBox(height: 14),
                                const Expanded(
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: _MiniFeatureCard(
                                                icon: Icons.favorite,
                                                iconColor: purple,
                                                title: "Matches",
                                                subtitle: "People who like you",
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: _MiniFeatureCard(
                                                icon: Icons.remove_red_eye_outlined,
                                                title: "Profile views",
                                                subtitle: "Who checked you out",
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: _MiniFeatureCard(
                                                icon: Icons.edit,
                                                title: "Your profile",
                                                subtitle: "Improve your profile",
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: _MiniFeatureCard(
                                                icon: Icons.menu_rounded,
                                                title: "Settings",
                                                subtitle: "Preferences & control",
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white.withOpacity(0.024),
                              border: Border.all(
                                color: gold2.withOpacity(0.10),
                              ),
                            ),
                            child: const Text(
                              "Most matches come from search ✨",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.2,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AnimatedBuilder(
                            animation: _heroGlow,
                            builder: (context, _) {
                              final glow = _heroGlow.value;

                              return GestureDetector(
                                onTap: _closeHelpful,
                                child: Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    gradient: const LinearGradient(
                                      colors: [gold2, gold3, gold4],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: gold2.withOpacity(
                                          0.22 + glow * 0.08,
                                        ),
                                        blurRadius: 18 + glow * 7,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "CONTINUE",
                                      style: TextStyle(
                                        fontSize: 14.1,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                        letterSpacing: 0.35,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 9),
                          GestureDetector(
                            onTap: _closeNotHelpful,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                "This was not helpful",
                                style: TextStyle(
                                  fontSize: 12.2,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white54,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white38,
                                ),
                              ),
                            ),
                          ),
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
    );
  }

  Widget _heroOrb(double glow) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [gold3, gold2, gold1],
        ),
        boxShadow: [
          BoxShadow(
            color: gold2.withOpacity(0.16 + glow * 0.06),
            blurRadius: 22 + glow * 7,
          ),
        ],
      ),
      child: const Icon(
        Icons.travel_explore_rounded,
        color: Colors.black,
        size: 37,
      ),
    );
  }

  Widget _topButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _SearchFeatureCard extends StatelessWidget {
  final AnimationController pulse;

  const _SearchFeatureCard({
    required this.pulse,
  });

  static const Color gold2 = Color(0xFFF0CF5A);
  static const Color gold3 = Color(0xFFFFE7A6);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final t = pulse.value;

        return GestureDetector(
          onTap: () => HapticFeedback.selectionClick(),
          child: Transform.scale(
            scale: 1 + (t * 0.005),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: gold2.withOpacity(0.18 + t * 0.06),
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.040),
                    gold2.withOpacity(0.034),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: gold2.withOpacity(0.065 + t * 0.03),
                    blurRadius: 15 + t * 5,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [gold2, gold3],
                      ),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      size: 29,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Your main tool",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17.0,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.0,
                            letterSpacing: -0.25,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          "Discover people and get seen",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.78),
                            height: 1.0,
                          ),
                        ),
                      ],
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
}

class _MiniFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;

  const _MiniFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor = Colors.white,
  });

  static const Color gold2 = Color(0xFFF0CF5A);
  static const Color gold3 = Color(0xFFFFE7A6);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => HapticFeedback.selectionClick(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: gold2.withOpacity(0.08),
          ),
          color: Colors.white.withOpacity(0.024),
          boxShadow: [
            BoxShadow(
              color: gold2.withOpacity(0.012),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                gradient: LinearGradient(
                  colors: [
                    gold2.withOpacity(0.9),
                    gold3.withOpacity(0.9),
                  ],
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor == Colors.white ? Colors.black : iconColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.0,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.3,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.72),
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}