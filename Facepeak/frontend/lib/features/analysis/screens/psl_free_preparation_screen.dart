import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ✅ ADD THIS IMPORT (change path to your actual file)
import 'package:frontend/features/analysis/screens/psl_free_rewarded_gate_screen.dart';
// If your gate screen is somewhere else, just adjust the import path.

class PslPreparationScreen extends StatefulWidget {
  const PslPreparationScreen({super.key});

  @override
  State<PslPreparationScreen> createState() => _PslPreparationScreenState();
}

class _PslPreparationScreenState extends State<PslPreparationScreen>
    with TickerProviderStateMixin {
  // =========================================================
  // THEME (Blue Structural Identity)
  // =========================================================
  static const Color bg = Color(0xFF05070D);
  static const Color text = Color(0xFFEAF0FF);
  static const Color muted = Color(0xFF8B90A0);
  static const Color micro = Color(0xFF7D8296);

  // 🔥 more “blue” than before
  static const Color accent = Color(0xFF8EA2FF);
  static const Color accent2 = Color(0xFF6FD3FF); // cyan edge highlight
  static const Color accentSoft = Color(0x228EA2FF);

  static const double rCard = 22;

  late final AnimationController _intro;
  late final AnimationController _pulse;
  late final AnimationController _button;
  late final AnimationController _shine;
  late final AnimationController _floaty;

  late final Animation<double> _fade;
  late final Animation<double> _slide;
  late final Animation<double> _titlePop;
  late final Animation<double> _cardPop;

  bool _pressed = false;
  bool _navLock = false; // prevents double taps

  @override
  void initState() {
    super.initState();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..repeat(reverse: true);

    _button = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );

    // “glass sweep” shimmer over the card
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // tiny “breathing” float to make it feel alive
    _floaty = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _fade = CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic);
    _slide = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic),
    );

    _titlePop = Tween<double>(begin: 0.985, end: 1.0).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );

    _cardPop = Tween<double>(begin: 0.99, end: 1.0).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
      ),
    );

    // micro: soft entry haptic (feels premium)
    HapticFeedback.selectionClick();
    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    _button.dispose();
    _shine.dispose();
    _floaty.dispose();
    super.dispose();
  }

  // =========================================================
  // ✅ CONTINUE -> PUSH PSL FREE REWARDED GATE SCREEN
  // =========================================================
  Future<void> _continue() async {
  if (_navLock) return;
  _navLock = true;

  HapticFeedback.mediumImpact();

  if (!mounted) return;

  await Navigator.push(
    context,
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const PslEliteGateScreen(); // 🔥 tvoj novi elite gate
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.02, 0.02),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );

  if (!mounted) return;

  _navLock = false;
}

  void onBtnDown() {
    setState(() => _pressed = true);
    _button.forward();
    HapticFeedback.selectionClick();
  }

  void onBtnUp() {
    setState(() => _pressed = false);
    _button.reverse();
  }

  @override
Widget build(BuildContext context) {
  final size = MediaQuery.of(context).size;

  return Scaffold(
    backgroundColor: bg,
    body: SafeArea(
      child: Stack(
        children: [
          // ================= BACKGROUND =================
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulse, _floaty]),
              builder: (context, _) {
                final t = _pulse.value;
                final f = _floaty.value;

                return CustomPaint(
                  painter: _PslBackgroundPainter(
                    accent: accent,
                    accent2: accent2,
                    intensity: 0.36 + t * 0.26,
                    drift: (f - 0.5) * 14,
                  ),
                );
              },
            ),
          ),

          // ================= CONTENT =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AnimatedBuilder(
              animation: _intro,
              builder: (context, _) {
                return Opacity(
                  opacity: _fade.value,
                  child: Transform.translate(
                    offset: Offset(0, _slide.value),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 28),

                        // HEADER
                        Row(
                          children: [
                            _GlowDot(pulse: _pulse, color: accent2),
                            const SizedBox(width: 10),
                            const Icon(Icons.architecture_rounded,
                                color: accent, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              "PSL",
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const Spacer(),
                            _TinyPill(
                              text: "STRUCTURE",
                              color: accent,
                              bg: accentSoft,
                            ),
                          ],
                        ),

                        const SizedBox(height: 26),

                        // TITLE
                        Transform.scale(
                          scale: _titlePop.value,
                          child: const Text(
                            "This is your\nfacial structure.",
                            style: TextStyle(
                              color: text,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        const Text(
                          "Not your styling.\nNot your expression.\nNot the photo quality.",
                          style: TextStyle(
                            color: muted,
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),

                        const SizedBox(height: 36),

                        // CARD
                        AnimatedBuilder(
                          animation:
                              Listenable.merge([_pulse, _shine, _floaty]),
                          builder: (context, _) {
                            final glow = 0.14 + _pulse.value * 0.22;
                            final float =
                                (_floaty.value - 0.5) * 3.0;

                            return Transform.translate(
                              offset: Offset(0, float),
                              child: Transform.scale(
                                scale: _cardPop.value,
                                child: _GlowCard(
                                  radius: rCard,
                                  borderColor:
                                      accent.withOpacity(0.55),
                                  glowColor:
                                      accent2.withOpacity(glow),
                                  child: const Padding(
                                    padding: EdgeInsets.all(22),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _Bullet(
                                          title: "PSL reacts slowly",
                                          subtitle:
                                              "Bone structure · proportions · geometry",
                                        ),
                                        SizedBox(height: 18),
                                        _Bullet(
                                          title:
                                              "Unaffected by mood",
                                          subtitle:
                                              "Lighting or expression won’t change it",
                                        ),
                                        SizedBox(height: 18),
                                        _Bullet(
                                          title:
                                              "Stable baseline",
                                          subtitle:
                                              "Your long-term structural potential",
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const Spacer(),

                        // DISCLAIMER
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(18),
                            color: accent.withOpacity(0.12),
                            border: Border.all(
                                color:
                                    accent2.withOpacity(0.22)),
                          ),
                          child: const Text(
                            "PSL measures structure, not worth.",
                            style: TextStyle(
                              color: accent2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),

                        // BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: AnimatedBuilder(
                            animation:
                                Listenable.merge([_button, _pulse]),
                            builder: (context, _) {
                              final press = _button.value;
                              final scale =
                                  1.0 - press * 0.02;
                              final glow =
                                  0.22 + _pulse.value * 0.22;

                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(
                                            18),
                                    gradient:
                                        LinearGradient(
                                      colors: [
                                        accent2,
                                        accent,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accent2
                                            .withOpacity(glow),
                                        blurRadius: 28,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    style:
                                        ElevatedButton
                                            .styleFrom(
                                      backgroundColor:
                                          Colors
                                              .transparent,
                                      shadowColor:
                                          Colors
                                              .transparent,
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                                    18),
                                      ),
                                    ),
                                    onPressed: _continue,
                                    child: const Text(
                                      "Continue",
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 22),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // TOP ORB
          Positioned(
            top: -90,
            left: -70,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  final o =
                      0.07 + _pulse.value * 0.07;

                  return Container(
                    width: size.width * 0.95,
                    height: size.width * 0.95,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accent2.withOpacity(o),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.72],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}}

// =========================================================
// BULLET
// =========================================================
class _Bullet extends StatelessWidget {
  final String title;
  final String subtitle;

  const _Bullet({
    required this.title,
    required this.subtitle,
  });

  static const Color text = _PslPreparationScreenState.text;
  static const Color micro = _PslPreparationScreenState.micro;
  static const Color accent2 = _PslPreparationScreenState.accent2;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 7),
          child: Icon(Icons.circle, size: 6, color: accent2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: text,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: micro.withOpacity(0.95),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =========================================================
// GLOW CARD
// =========================================================
class _GlowCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final Color borderColor;
  final Color glowColor;

  const _GlowCard({
    required this.child,
    required this.radius,
    required this.borderColor,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 34,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor.withOpacity(0.35)),
          color: Colors.white.withOpacity(0.018),
        ),
        child: child,
      ),
    );
  }
}

// =========================================================
// TINY PILL
// =========================================================
class _TinyPill extends StatelessWidget {
  final String text;
  final Color color;
  final Color bg;

  const _TinyPill({
    required this.text,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

// =========================================================
// GLOW DOT
// =========================================================
class _GlowDot extends StatelessWidget {
  final Animation<double> pulse;
  final Color color;

  const _GlowDot({
    required this.pulse,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final t = pulse.value;
        final o = 0.48 + t * 0.34;
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(o),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.35 + t * 0.25),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

// =========================================================
// SHIMMER SWEEP PAINTER (glass sweep on card)
// =========================================================
class _ShimmerSweepPainter extends CustomPainter {
  final double t;
  final Color color;

  _ShimmerSweepPainter({
    required this.t,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Move diagonal band across card
    final x = (t * (size.width + size.height)) - size.height;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          color,
          Colors.transparent,
        ],
        stops: const [0.42, 0.5, 0.58],
      ).createShader(Rect.fromLTWH(x, -size.height, size.width, size.height * 2));

    // clip to rounded card
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(_PslPreparationScreenState.rCard));
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShimmerSweepPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.color != color;
  }
}

// =========================================================
// BACKGROUND PAINTER (blue aura + rays + drift)
// =========================================================
class _PslBackgroundPainter extends CustomPainter {
  final Color accent;
  final Color accent2;
  final double intensity;
  final double drift;

  _PslBackgroundPainter({
    required this.accent,
    required this.accent2,
    required this.intensity,
    required this.drift,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF05070D),
          Color(0xFF05070D),
          Color(0xFF070A14),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, base);

    // Blue aura
    final center = Offset(size.width * 0.72, size.height * 0.18 + drift);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          accent2.withOpacity(0.18 * intensity),
          accent.withOpacity(0.10 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.28, 0.72],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.9));
    canvas.drawCircle(center, size.width * 0.9, glow);

    // Subtle rays (structure vibe)
    final rays = Paint()
      ..color = accent2.withOpacity(0.016 * intensity)
      ..strokeWidth = 1.0;

    final origin = Offset(size.width * 0.12, size.height * 0.28 + drift * 0.25);
    for (int i = 0; i < 16; i++) {
      final a = (-0.62 + (i / 15) * 0.95);
      final dir = Offset(math.cos(a), math.sin(a));
      final p2 = origin + dir * (size.width * 1.25);
      canvas.drawLine(origin, p2, rays);
    }
  }

  @override
  bool shouldRepaint(covariant _PslBackgroundPainter oldDelegate) {
    return oldDelegate.intensity != intensity ||
        oldDelegate.drift != drift ||
        oldDelegate.accent != accent ||
        oldDelegate.accent2 != accent2;
  }
}