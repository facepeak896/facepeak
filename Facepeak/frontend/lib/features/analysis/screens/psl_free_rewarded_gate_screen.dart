import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/services/ads_service.dart';
import 'psl_free_upload_screen.dart';
/// PSL Free Rewarded Gate — UI ONLY (no ad logic, no guest token)
/// - Subtle CTA (not aggressive)
/// - Deep blue structural identity
/// - Elite polish: aura, grain, shimmer, parallax-ish drift, microcopy
///
/// Hook your logic by passing [onUnlock] / [onCancel].
class PslEliteGateScreen extends StatefulWidget {
  final VoidCallback? onUnlock;
  final VoidCallback? onCancel;

  const PslEliteGateScreen({
    super.key,
    this.onUnlock,
    this.onCancel,
  });

  @override
  State<PslEliteGateScreen> createState() => _PslEliteGateScreenState();
}

class _PslEliteGateScreenState extends State<PslEliteGateScreen>
    with TickerProviderStateMixin {
  // =========================
  // THEME
  // =========================
  static const Color bg = Color(0xFF05070D);
  static const Color text = Color(0xFFEAF0FF);
  static const Color muted = Color(0xFF8B90A0);
  static const Color micro = Color(0xFF7D8296);

  static const Color accent = Color(0xFF8EA2FF); // structural blue
  static const Color accent2 = Color(0xFF6FD3FF); // cyan edge
  static const Color accent3 = Color(0xFFB6C2FF); // soft highlight
  static const Color glass = Color(0x12FFFFFF);

  static const double rCard = 22;
  static const double rBtn = 18;

  late final AnimationController _intro;
  late final AnimationController _pulse;
  late final AnimationController _shine;
  late final AnimationController _floaty;
  late final AnimationController _ctaPress;
  late final AnimationController _miniOrbit;

  late final Animation<double> _fade;
  late final Animation<double> _slide;
  late final Animation<double> _titlePop;
  late final Animation<double> _cardPop;

  bool _ctaDown = false;
  bool _loading = false;
  bool _rewardConsumedThisFlow = false;

  @override
void initState() {
  super.initState();

  // 🔥 Preload rewarded ad (bitno za instant prikaz)
  

  _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 860),
  );

  _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  _floaty = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..repeat(reverse: true);

  _miniOrbit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  )..repeat();

  _ctaPress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    lowerBound: 0.0,
    upperBound: 1.0,
  );

  _fade = CurvedAnimation(
    parent: _intro,
    curve: Curves.easeOutCubic,
  );

  _slide = Tween<double>(
    begin: 18,
    end: 0,
  ).animate(
    CurvedAnimation(
      parent: _intro,
      curve: Curves.easeOutCubic,
    ),
  );

  _titlePop = Tween<double>(
    begin: 0.985,
    end: 1.0,
  ).animate(
    CurvedAnimation(
      parent: _intro,
      curve: const Interval(
        0.0,
        0.6,
        curve: Curves.easeOutBack,
      ),
    ),
  );

  _cardPop = Tween<double>(
    begin: 0.99,
    end: 1.0,
  ).animate(
    CurvedAnimation(
      parent: _intro,
      curve: const Interval(
        0.15,
        1.0,
        curve: Curves.easeOutBack,
      ),
    ),
  );

  HapticFeedback.selectionClick();
  _intro.forward();
}

  @override
void dispose() {
  _intro.dispose();
  _pulse.dispose();
  _shine.dispose();
  _floaty.dispose();
  _ctaPress.dispose();
  _miniOrbit.dispose();
  super.dispose();
}

// =======================
// CTA PRESS ANIMATION
// =======================

void _onCtaDown(PointerDownEvent _) {
  if (_loading) return;
  setState(() => _ctaDown = true);
  _ctaPress.forward();
  HapticFeedback.selectionClick();
}

void _onCtaUp([PointerUpEvent? _]) {
  if (_loading) return;
  setState(() => _ctaDown = false);
  _ctaPress.reverse();
}

// =======================
// 🔥 REWARDED FLOW
// =======================

Future<void> _onUnlockTap() async {
  if (_loading || _rewardConsumedThisFlow) return;

  setState(() => _loading = true);
  HapticFeedback.mediumImpact();

  final success = await AdsService.instance.showRewardedAd();

  if (!mounted) return;

  if (!success) {
    setState(() => _loading = false);
    return;
  }

  _rewardConsumedThisFlow = true;

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const PslFreeUploadScreen(),
    ),
  );
}

// =======================
// CANCEL
// =======================

void _onCancelTap() {
  if (_loading) return;
  HapticFeedback.selectionClick();
  Navigator.maybePop(context);
}

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
            // =========================
            // BACKGROUND LAYERS
            // =========================
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([_pulse, _floaty, _miniOrbit]),
                builder: (context, _) {
                  final p = _pulse.value;
                  final f = _floaty.value;
                  final o = _miniOrbit.value;

                  return CustomPaint(
                    painter: _ElitePslBackgroundPainter(
                      accent: accent,
                      accent2: accent2,
                      accent3: accent3,
                      intensity: 0.42 + p * 0.28,
                      drift: (f - 0.5) * 18,
                      orbit: o,
                    ),
                  );
                },
              ),
            ),

            // subtle vignette
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.00),
                      Colors.black.withOpacity(0.06),
                      Colors.black.withOpacity(0.22),
                      Colors.black.withOpacity(0.62),
                    ],
                  ),
                ),
              ),
            ),

            // grain (very subtle)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _miniOrbit,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _FilmGrainPainter(
                        seed: (_miniOrbit.value * 99999).floor(),
                        opacity: 0.040,
                      ),
                    );
                  },
                ),
              ),
            ),

            // =========================
            // CONTENT
            // =========================
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
                          const SizedBox(height: 26),

                          // top row
                          Row(
                            children: [
                              _GlowDot(pulse: _pulse, color: accent2),
                              const SizedBox(width: 10),
                              ShaderMask(
                                shaderCallback: (rect) =>
                                    const LinearGradient(colors: [accent2, accent])
                                        .createShader(rect),
                                child: const Icon(
                                  Icons.architecture_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
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
                                text: "STRUCTURE MODE",
                                color: accent2,
                                bg: accent.withOpacity(0.10),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Title block
                          Transform.scale(
                            scale: _titlePop.value,
                            child: const Text(
                              "Unlock\nStructural Score",
                              style: TextStyle(
                                color: text,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                height: 1.02,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            "This measures bone geometry and facial proportions.\n"
                            "Not mood. Not styling. Not expression.",
                            style: TextStyle(
                              color: muted,
                              fontSize: 14.5,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 22),

                          // Value/feature card
                          AnimatedBuilder(
                            animation: Listenable.merge([_pulse, _shine, _floaty]),
                            builder: (context, _) {
                              final glow = 0.14 + _pulse.value * 0.26;
                              final float = (_floaty.value - 0.5) * 3.5;

                              return Transform.translate(
                                offset: Offset(0, float),
                                child: Transform.scale(
                                  scale: _cardPop.value,
                                  child: _GlassCard(
                                    radius: rCard,
                                    border: accent2.withOpacity(0.22),
                                    glow: accent2.withOpacity(glow),
                                    child: Stack(
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.fromLTRB(18, 18, 18, 16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _MiniHeader(
                                                title: "What you unlock",
                                                subtitle: "One short step. Permanent clarity.",
                                              ),
                                              SizedBox(height: 14),
                                              _FeatureRow(
                                                icon: Icons.rule_rounded,
                                                title: "Official PSL score (1–8)",
                                                subtitle: "Ranked structural baseline",
                                              ),
                                              SizedBox(height: 12),
                                              _FeatureRow(
                                                icon: Icons.shield_moon_rounded,
                                                title: "Stable result",
                                                subtitle: "Less sensitive to lighting & expression",
                                              ),
                                              SizedBox(height: 12),
                                              _FeatureRow(
                                                icon: Icons.timeline_rounded,
                                                title: "Long-term potential anchor",
                                                subtitle: "A reference point for your glow-up",
                                              ),
                                            ],
                                          ),
                                        ),

                                        // shimmer sweep
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            child: CustomPaint(
                                              painter: _ShimmerSweepPainter(
                                                t: _shine.value,
                                                color: accent2.withOpacity(0.10),
                                                radius: rCard,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          // subtle “cost” / “ad” copy (non aggressive)
                          AnimatedBuilder(
                            animation: _pulse,
                            builder: (context, _) {
                              final t = _pulse.value;
                              final o = 0.60 + t * 0.25;

                              return _NotePill(
                                icon: Icons.smart_display_rounded,
                                text:
                                    "To unlock PSL, watch one short rewarded video.\nNo subscription required.",
                                opacity: o,
                              );
                            },
                          ),

                          const Spacer(),

                          // =========================
                          // CTA (subtle, elite)
                          // =========================
                          Listener(
                            onPointerDown: _onCtaDown,
                            onPointerUp: (_) => _onCtaUp(),
                            onPointerCancel: (_) => _onCtaUp(),
                            child: AnimatedBuilder(
                              animation: Listenable.merge([_ctaPress, _pulse]),
                              builder: (context, _) {
                                final press = _ctaPress.value;
                                final scale = 1.0 - press * 0.018;
                                final glow = 0.18 + _pulse.value * 0.20;

                                return Transform.scale(
                                  scale: scale,
                                  child: _CtaButton(
                                    glow: glow,
                                    onTap: _loading ? () {} : _onUnlockTap, 
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.lock_open_rounded,
                                          size: 18,
                                          color: Colors.black.withOpacity(0.90),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          "Unlock PSL",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.2,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          size: 22,
                                          color: Colors.black.withOpacity(0.85),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 14),

                          Center(
                            child: TextButton(
                              onPressed: _onCancelTap,
                              child: const Text(
                                "Not now",
                                style: TextStyle(
                                  color: muted,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Center(
                            child: Text(
                              "Tip: front-facing + neutral head pose → best structural read.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: micro.withOpacity(0.88),
                                fontSize: 11.5,
                                height: 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Top orb highlight
            Positioned(
              top: -105,
              left: -90,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) {
                    final o = 0.06 + _pulse.value * 0.07;
                    return Container(
                      width: size.width * 1.02,
                      height: size.width * 1.02,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            accent2.withOpacity(o),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.73],
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
  }
}

// =========================================================
// Small components
// =========================================================

class _MiniHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _MiniHeader({
    required this.title,
    required this.subtitle,
  });

  static const Color text = _PslEliteGateScreenState.text;
  static const Color muted = _PslEliteGateScreenState.muted;
  static const Color accent2 = _PslEliteGateScreenState.accent2;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent2.withOpacity(0.85),
            boxShadow: [
              BoxShadow(
                color: accent2.withOpacity(0.35),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: text,
                  fontWeight: FontWeight.w900,
                  fontSize: 14.5,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: muted.withOpacity(0.95),
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  static const Color text = _PslEliteGateScreenState.text;
  static const Color micro = _PslEliteGateScreenState.micro;
  static const Color accent = _PslEliteGateScreenState.accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withOpacity(0.04),
            border: Border.all(color: accent.withOpacity(0.16)),
          ),
          child: Icon(
            icon,
            size: 19,
            color: accent.withOpacity(0.95),
          ),
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
                  fontSize: 13.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: micro.withOpacity(0.92),
                  fontWeight: FontWeight.w700,
                  fontSize: 12.0,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotePill extends StatelessWidget {
  final IconData icon;
  final String text;
  final double opacity;

  const _NotePill({
    required this.icon,
    required this.text,
    required this.opacity,
  });

  static const Color accent2 = _PslEliteGateScreenState.accent2;
  static const Color micro = _PslEliteGateScreenState.micro;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: accent2.withOpacity(0.06),
        border: Border.all(color: accent2.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: accent2.withOpacity(opacity),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: micro.withOpacity(0.95),
                fontWeight: FontWeight.w700,
                fontSize: 12.3,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final double glow;
  final VoidCallback onTap;
  final Widget child;

  const _CtaButton({
    required this.glow,
    required this.onTap,
    required this.child,
  });

  static const Color accent = _PslEliteGateScreenState.accent;
  static const Color accent2 = _PslEliteGateScreenState.accent2;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_PslEliteGateScreenState.rBtn),
        gradient: LinearGradient(
          colors: [
            accent2.withOpacity(0.98),
            accent.withOpacity(0.98),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent2.withOpacity(glow),
            blurRadius: 30,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_PslEliteGateScreenState.rBtn),
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }
}

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
          color: color.withOpacity(0.98),
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

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

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final Color border;
  final Color glow;

  const _GlassCard({
    required this.child,
    required this.radius,
    required this.border,
    required this.glow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: glow,
            blurRadius: 34,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: border.withOpacity(0.35)),
          color: _PslEliteGateScreenState.glass,
        ),
        child: child,
      ),
    );
  }
}

// =========================================================
// Painters
// =========================================================

class _ShimmerSweepPainter extends CustomPainter {
  final double t;
  final Color color;
  final double radius;

  _ShimmerSweepPainter({
    required this.t,
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // diagonal band progress
    final x = (t * (size.width + size.height)) - size.height;

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
      ).createShader(
        Rect.fromLTWH(x, -size.height, size.width, size.height * 2),
      );

    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShimmerSweepPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _ElitePslBackgroundPainter extends CustomPainter {
  final Color accent;
  final Color accent2;
  final Color accent3;
  final double intensity;
  final double drift;
  final double orbit;

  _ElitePslBackgroundPainter({
    required this.accent,
    required this.accent2,
    required this.accent3,
    required this.intensity,
    required this.drift,
    required this.orbit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base gradient
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF05070D),
          Color(0xFF05070D),
          Color(0xFF070A14),
          Color(0xFF05070D),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, base);

    // Primary aura (top-right)
    final center1 = Offset(size.width * 0.74, size.height * (0.16) + drift);
    final aura1 = Paint()
      ..shader = RadialGradient(
        colors: [
          accent2.withOpacity(0.20 * intensity),
          accent.withOpacity(0.12 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.28, 0.72],
      ).createShader(Rect.fromCircle(center: center1, radius: size.width * 0.95));
    canvas.drawCircle(center1, size.width * 0.95, aura1);

    // Secondary aura (bottom-left)
    final center2 = Offset(size.width * 0.18, size.height * 0.86 + drift * 0.35);
    final aura2 = Paint()
      ..shader = RadialGradient(
        colors: [
          accent3.withOpacity(0.08 * intensity),
          accent.withOpacity(0.05 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.34, 0.78],
      ).createShader(Rect.fromCircle(center: center2, radius: size.width * 1.0));
    canvas.drawCircle(center2, size.width * 1.0, aura2);

    // Structural rays
    final rays = Paint()
      ..color = accent2.withOpacity(0.014 * intensity)
      ..strokeWidth = 1.0;

    final origin = Offset(size.width * 0.10, size.height * 0.28 + drift * 0.25);
    for (int i = 0; i < 18; i++) {
      final a = (-0.70 + (i / 17) * 1.04);
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(origin, origin + dir * (size.width * 1.3), rays);
    }

    // Orbit arcs (very subtle)
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = accent.withOpacity(0.06 * intensity);

    final arcCenter = Offset(size.width * 0.66, size.height * 0.26 + drift * 0.2);
    final r = size.width * 0.42;
    final start = (orbit * math.pi * 2);
    canvas.drawArc(
      Rect.fromCircle(center: arcCenter, radius: r),
      start,
      math.pi * 0.65,
      false,
      arcPaint,
    );

    final arcPaint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = accent2.withOpacity(0.05 * intensity);

    canvas.drawArc(
      Rect.fromCircle(center: arcCenter, radius: r * 0.78),
      start + 1.1,
      math.pi * 0.55,
      false,
      arcPaint2,
    );
  }

  @override
  bool shouldRepaint(covariant _ElitePslBackgroundPainter oldDelegate) {
    return oldDelegate.intensity != intensity ||
        oldDelegate.drift != drift ||
        oldDelegate.orbit != orbit ||
        oldDelegate.accent != accent ||
        oldDelegate.accent2 != accent2 ||
        oldDelegate.accent3 != accent3;
  }
}

/// Very subtle grain — purely aesthetic.
/// This is “fake grain” (random dots), cheap & good enough.
class _FilmGrainPainter extends CustomPainter {
  final int seed;
  final double opacity;

  _FilmGrainPainter({
    required this.seed,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = _LCGRand(seed);
    final paint = Paint()..color = Colors.white.withOpacity(opacity);

    // density scales with area but clamped
    final count = (size.width * size.height / 9000).clamp(120.0, 220.0).toInt();

    for (int i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final r = 0.35 + rnd.nextDouble() * 0.85;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FilmGrainPainter oldDelegate) {
    return oldDelegate.seed != seed || oldDelegate.opacity != opacity;
  }
}

/// Tiny deterministic RNG (fast, no import).
class _LCGRand {
  int _state;
  _LCGRand(this._state);

  double nextDouble() {
    // LCG parameters
    _state = (1664525 * _state + 1013904223) & 0x7fffffff;
    return _state / 0x7fffffff;
  }
}