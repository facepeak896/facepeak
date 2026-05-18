import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:frontend/services/ads_service.dart';
import 'psl_free_upload_screen.dart';

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
  static const Color bg = Color(0xFF05050D);
  static const Color text = Color(0xFFF2EEFF);
  static const Color muted = Color(0xFF9B94AA);
  static const Color micro = Color(0xFF81798F);

  static const Color accent = Color(0xFF8B5CFF);
  static const Color accent2 = Color(0xFFC084FC);
  static const Color accent3 = Color(0xFFE9D5FF);
  static const Color accentDeep = Color(0xFF5B21B6);
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

  bool _loading = false;
  bool _rewardConsumedThisFlow = false;

  @override
  void initState() {
    super.initState();

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
      duration: const Duration(milliseconds: 90),
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

  Future<void> _onUnlockTap() async {
    if (_loading || _rewardConsumedThisFlow) return;

    setState(() => _loading = true);

    HapticFeedback.mediumImpact();

    await _ctaPress.forward();
    _ctaPress.reverse();

    final success = await AdsService.instance.showRewardedAd();

    if (!mounted) return;

    if (!success) {
      setState(() => _loading = false);
      HapticFeedback.selectionClick();
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

  void _onCancelTap() {
    if (_loading) return;

    HapticFeedback.selectionClick();

    if (widget.onCancel != null) {
      widget.onCancel!();
      return;
    }

    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final rawMedia = MediaQuery.of(context);
    final media = rawMedia.copyWith(
      textScaler: const TextScaler.linear(1.0),
    );

    return MediaQuery(
      data: media,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              final compact = h < 760;
              final veryCompact = h < 690;

              return Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _pulse,
                        _floaty,
                        _miniOrbit,
                      ]),
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _ElitePslBackgroundPainter(
                            accent: accent,
                            accent2: accent2,
                            accent3: accent3,
                            intensity: 0.42 + _pulse.value * 0.28,
                            drift: (_floaty.value - 0.5) * 18,
                            orbit: _miniOrbit.value,
                          ),
                        );
                      },
                    ),
                  ),

                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.00),
                            Colors.black.withOpacity(0.05),
                            Colors.black.withOpacity(0.20),
                            Colors.black.withOpacity(0.62),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _miniOrbit,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: _FilmGrainPainter(
                              seed: (_miniOrbit.value * 99999).floor(),
                              opacity: 0.036,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      24,
                      veryCompact ? 18 : 26,
                      24,
                      22 + rawMedia.padding.bottom,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight -
                            rawMedia.padding.top -
                            rawMedia.padding.bottom -
                            40,
                      ),
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
                                  _topRow(),
                                  SizedBox(height: veryCompact ? 18 : 24),
                                  _titleBlock(compact: compact),
                                  SizedBox(height: veryCompact ? 12 : 14),
                                  _description(compact: compact),
                                  SizedBox(height: veryCompact ? 18 : 24),
                                  _unlockCard(compact: compact),
                                  SizedBox(height: veryCompact ? 12 : 16),
                                  _notePill(),
                                  SizedBox(height: veryCompact ? 54 : 96),
                                  _cta(),
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
                                  const SizedBox(height: 14),
                                  Center(
                                    child: Text(
                                      "Tip: front-facing + neutral head pose → best structural read.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: micro.withOpacity(0.88),
                                        fontSize: 11.5,
                                        height: 1.25,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  Positioned(
                    top: -105,
                    left: -90,
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, _) {
                          final o = 0.07 + _pulse.value * 0.08;

                          return Container(
                            width: rawMedia.size.width * 1.02,
                            height: rawMedia.size.width * 1.02,
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
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _topRow() {
    return Row(
      children: [
        _GlowDot(pulse: _pulse, color: accent2),
        const SizedBox(width: 10),
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: [accent3, accent],
          ).createShader(rect),
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
            color: accent3,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const Spacer(),
        _TinyPill(
          text: "STRUCTURE MODE",
          color: accent3,
          bg: accent.withOpacity(0.14),
        ),
      ],
    );
  }

  Widget _titleBlock({required bool compact}) {
    return Transform.scale(
      scale: _titlePop.value,
      alignment: Alignment.centerLeft,
      child: Text(
        "Unlock\nStructural Score",
        style: TextStyle(
          color: text,
          fontSize: compact ? 32 : 36,
          fontWeight: FontWeight.w900,
          height: 1.02,
          letterSpacing: -0.4,
          shadows: [
            Shadow(
              color: accent.withOpacity(0.18),
              blurRadius: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _description({required bool compact}) {
    return Text(
      "This measures bone geometry and facial proportions.\n"
      "Not mood. Not styling. Not expression.",
      style: TextStyle(
        color: muted,
        fontSize: compact ? 14.0 : 14.7,
        height: 1.45,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _unlockCard({required bool compact}) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _shine, _floaty]),
      builder: (context, _) {
        final glow = 0.16 + _pulse.value * 0.30;
        final float = (_floaty.value - 0.5) * 3.5;

        return Transform.translate(
          offset: Offset(0, float),
          child: Transform.scale(
            scale: _cardPop.value,
            child: _GlassCard(
              radius: rCard,
              border: accent2.withOpacity(0.25),
              glow: accent.withOpacity(glow),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      18,
                      compact ? 16 : 18,
                      18,
                      compact ? 14 : 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _MiniHeader(
                          title: "What you unlock",
                          subtitle: "One short step. Permanent clarity.",
                        ),
                        SizedBox(height: compact ? 12 : 14),
                        const _FeatureRow(
                          icon: Icons.rule_rounded,
                          title: "Official PSL score (1–8)",
                          subtitle: "Ranked structural baseline",
                        ),
                        SizedBox(height: compact ? 10 : 12),
                        const _FeatureRow(
                          icon: Icons.shield_moon_rounded,
                          title: "Stable result",
                          subtitle: "Less sensitive to lighting & expression",
                        ),
                        SizedBox(height: compact ? 10 : 12),
                        const _FeatureRow(
                          icon: Icons.timeline_rounded,
                          title: "Long-term potential anchor",
                          subtitle: "A reference point for your glow-up",
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _ShimmerSweepPainter(
                          t: _shine.value,
                          color: accent2.withOpacity(0.11),
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
    );
  }

  Widget _notePill() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = _pulse.value;
        final o = 0.64 + t * 0.25;

        return _NotePill(
          icon: Icons.smart_display_rounded,
          text:
              "To unlock PSL, watch one short rewarded video.\nNo subscription required.",
          opacity: o,
        );
      },
    );
  }

  Widget _cta() {
    return AnimatedBuilder(
      animation: Listenable.merge([_ctaPress, _pulse]),
      builder: (context, _) {
        final press = _ctaPress.value;
        final scale = 1.0 - press * 0.018;
        final glow = 0.22 + _pulse.value * 0.24;

        return Transform.scale(
          scale: scale,
          child: _CtaButton(
            glow: glow,
            loading: _loading,
            onTap: _onUnlockTap,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: _loading
                  ? const SizedBox(
                      key: ValueKey("loading"),
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.black,
                      ),
                    )
                  : Row(
                      key: const ValueKey("ready"),
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
          ),
        );
      },
    );
  }
}

class _MiniHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _MiniHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _PslEliteGateScreenState.accent2.withOpacity(0.90),
            boxShadow: [
              BoxShadow(
                color: _PslEliteGateScreenState.accent2.withOpacity(0.42),
                blurRadius: 16,
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
                  color: _PslEliteGateScreenState.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 14.5,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: _PslEliteGateScreenState.muted.withOpacity(0.95),
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withOpacity(0.045),
            border: Border.all(
              color: _PslEliteGateScreenState.accent2.withOpacity(0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: _PslEliteGateScreenState.accent.withOpacity(0.08),
                blurRadius: 14,
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 19,
            color: _PslEliteGateScreenState.accent3.withOpacity(0.96),
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
                  color: _PslEliteGateScreenState.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: _PslEliteGateScreenState.micro.withOpacity(0.92),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _PslEliteGateScreenState.accent.withOpacity(0.075),
        border: Border.all(
          color: _PslEliteGateScreenState.accent2.withOpacity(0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: _PslEliteGateScreenState.accent.withOpacity(0.07),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: _PslEliteGateScreenState.accent3.withOpacity(opacity),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: _PslEliteGateScreenState.micro.withOpacity(0.95),
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
  final bool loading;
  final VoidCallback onTap;
  final Widget child;

  const _CtaButton({
    required this.glow,
    required this.loading,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: loading ? 0.92 : 1.0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: loading ? null : onTap,
        child: Container(
          height: 58,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_PslEliteGateScreenState.rBtn),
            gradient: const LinearGradient(
              colors: [
                _PslEliteGateScreenState.accent3,
                _PslEliteGateScreenState.accent2,
                _PslEliteGateScreenState.accent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: _PslEliteGateScreenState.accent2.withOpacity(glow),
                blurRadius: 30,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: _PslEliteGateScreenState.accent.withOpacity(0.18),
                blurRadius: 46,
              ),
            ],
          ),
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
        border: Border.all(color: color.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            color: _PslEliteGateScreenState.accent.withOpacity(0.10),
            blurRadius: 16,
          ),
        ],
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
        final o = 0.54 + t * 0.34;

        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(o),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.42 + t * 0.26),
                blurRadius: 15,
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
          border: Border.all(color: border.withOpacity(0.38)),
          color: _PslEliteGateScreenState.glass,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.055),
              _PslEliteGateScreenState.accent.withOpacity(0.040),
              Colors.white.withOpacity(0.025),
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}

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
    final rect = Offset.zero & size;
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
    return oldDelegate.t != t ||
        oldDelegate.color != color ||
        oldDelegate.radius != radius;
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

    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF05050D),
          Color(0xFF070511),
          Color(0xFF0B0718),
          Color(0xFF05050D),
        ],
      ).createShader(rect);

    canvas.drawRect(rect, base);

    final center1 = Offset(size.width * 0.72, size.height * 0.16 + drift);

    final aura1 = Paint()
      ..shader = RadialGradient(
        colors: [
          accent2.withOpacity(0.24 * intensity),
          accent.withOpacity(0.14 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.30, 0.72],
      ).createShader(
        Rect.fromCircle(center: center1, radius: size.width * 0.95),
      );

    canvas.drawCircle(center1, size.width * 0.95, aura1);

    final center2 = Offset(size.width * 0.18, size.height * 0.86 + drift * 0.35);

    final aura2 = Paint()
      ..shader = RadialGradient(
        colors: [
          accent3.withOpacity(0.10 * intensity),
          accent.withOpacity(0.06 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.34, 0.78],
      ).createShader(
        Rect.fromCircle(center: center2, radius: size.width * 1.0),
      );

    canvas.drawCircle(center2, size.width * 1.0, aura2);

    final rays = Paint()
      ..color = accent2.withOpacity(0.016 * intensity)
      ..strokeWidth = 1.0;

    final origin = Offset(size.width * 0.10, size.height * 0.28 + drift * 0.25);

    for (int i = 0; i < 18; i++) {
      final a = -0.70 + (i / 17) * 1.04;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(origin, origin + dir * (size.width * 1.3), rays);
    }

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = accent.withOpacity(0.075 * intensity);

    final arcCenter = Offset(size.width * 0.66, size.height * 0.26 + drift * 0.2);
    final r = size.width * 0.42;
    final start = orbit * math.pi * 2;

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
      ..color = accent2.withOpacity(0.065 * intensity);

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

    final count = (size.width * size.height / 9000)
        .clamp(120.0, 220.0)
        .toInt();

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

class _LCGRand {
  int _state;

  _LCGRand(this._state);

  double nextDouble() {
    _state = (1664525 * _state + 1013904223) & 0x7fffffff;
    return _state / 0x7fffffff;
  }
}