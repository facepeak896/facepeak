import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'appeal_explanation_screen.dart';

class AppealResultScreen extends StatefulWidget {
  final Map<String, dynamic> appeal;
  final File imageFile;

  const AppealResultScreen({
    super.key,
    required this.appeal,
    required this.imageFile,
  });

  @override
  State<AppealResultScreen> createState() => _AppealResultScreenState();
}

class _AppealResultScreenState extends State<AppealResultScreen>
    with TickerProviderStateMixin {
  // THEME
  static const Color bg = Color(0xFF0B0B0F);
  static const Color blue = Color(0xFF7FB6FF);
  static const Color red = Color(0xFFD36A6A);
  static const Color gold = Color(0xFFF5C518);

  late final AnimationController _ring;
  late final AnimationController _embers;
  late final AnimationController _flamePulse;
  late final AnimationController _float;

  late final List<_Ember> _emberList;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _ring = AnimationController(vsync: this, duration: const Duration(seconds: 34))
      ..repeat();

    _embers = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat();

    _flamePulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200))
      ..repeat(reverse: true);

    _emberList = _buildEmbers(42);
  }

  @override
  void dispose() {
    _ring.dispose();
    _embers.dispose();
    _flamePulse.dispose();
    _float.dispose();
    super.dispose();
  }

  // =========================
  // PARSERS (NOW 1..6)
  // =========================
  int _readDisplayScore() {
    final v = widget.appeal['display_score'];
    if (v is num) return v.clamp(1, 6).toInt();
    if (v is String) return (int.tryParse(v) ?? 3).clamp(1, 6);
    return 3;
  }

  String _readLabel() {
    final v = widget.appeal['label'];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return 'Average';
  }

  double _readConfidence() {
    final v = widget.appeal['confidence'];
    if (v is num) return v.toDouble().clamp(0.0, 1.0);
    if (v is String) return (double.tryParse(v) ?? 1.0).clamp(0.0, 1.0);
    return 1.0;
  }

  // =========================
  // LOOK & FEEL (score-based)
  // =========================
  Color _accentFromScore(int s) {
    // 1-2 warm (red), 3-4 neutral (white), 5-6 cool (blue/gold)
    if (s <= 2) return red;
    if (s == 6) return gold;
    if (s >= 5) return blue;
    return Colors.white;
  }

  double _intensityFromScore(int s) {
    // 1..6 -> 0..1
    if (s >= 6) return 1.0;
    if (s == 5) return 0.88;
    if (s == 4) return 0.55;
    if (s == 3) return 0.35;
    if (s == 2) return 0.22;
    return 0.14;
  }

  String _viralOneLiner(int score) {
    // ONE sentence only (screenshot-friendly)
    if (score >= 6) return 'Elite first impression.';
    if (score == 5) return 'Strong presence. Clean impact.';
    if (score == 4) return 'Above average visual presence.';
    if (score == 3) return 'Average first visual impression.';
    if (score == 2) return 'Below average impression.';
    return 'Weak first impression.';
  }

  List<_Ember> _buildEmbers(int count) {
    final rnd = math.Random(42);
    return List.generate(count, (_) {
      return _Ember(
        seed: rnd.nextDouble() * 9999,
        x: rnd.nextDouble(),
        y: rnd.nextDouble(),
        size: 0.8 + rnd.nextDouble() * 2.6,
        speed: 0.25 + rnd.nextDouble() * 0.9,
        wobble: 0.6 + rnd.nextDouble() * 1.4,
        fade: 0.35 + rnd.nextDouble() * 0.65,
      );
    });
  }

  Widget _scaleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
        color: Colors.black.withOpacity(0.18),
      ),
      child: Text(
        'Appeal scale 1–6',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.60),
        ),
      ),
    );
  }

  Widget _scoreLine({required int score, required Color accent}) {
    const double boxWidth = 260;
    return SizedBox(
      width: boxWidth,
      height: 98,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Text(
              score.toString(),
              style: TextStyle(
                fontSize: 86,
                fontWeight: FontWeight.w900,
                color: accent,
                height: 0.95,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withOpacity(0.55)),
                color: Colors.white.withOpacity(0.04),
              ),
              child: Text(
                'FacePeak',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.72),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierPill({required String label, required Color accent}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withOpacity(0.55)),
        color: accent.withOpacity(0.10),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: accent,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _tierBar({required int score, required Color accent}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          const SizedBox(height: 10),
          SizedBox(
            height: 30,
            child: Row(
              children: List.generate(6, (i) {
                final idx = i + 1;
                final active = idx <= score;
                final c = active ? accent.withOpacity(0.90) : Colors.white.withOpacity(0.10);

                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      color: c,
                      border: Border.all(
                        color: active ? accent.withOpacity(0.45) : Colors.white.withOpacity(0.08),
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: accent.withOpacity(0.10),
                                blurRadius: 16,
                                offset: const Offset(0, 10),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        idx.toString(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: active ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.25),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confidenceCard({required double confidence, required Color accent}) {
    final pct = (confidence * 100).round().clamp(0, 100);
    final label = pct >= 90
        ? 'High confidence'
        : pct >= 75
            ? 'Good confidence'
            : pct >= 60
                ? 'Medium confidence'
                : 'Low confidence';

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        color: Colors.white.withOpacity(0.04),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: accent.withOpacity(0.12),
              border: Border.all(color: accent.withOpacity(0.28)),
            ),
            child: Icon(
              Icons.shield_rounded,
              color: accent.withOpacity(0.85),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withOpacity(0.92),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Photo quality & face detection reliability: $pct%',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.25,
                    color: Colors.white.withOpacity(0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _continueButton(BuildContext context, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent == Colors.white ? blue : accent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => AppealExplanationScreen(onContinue: () {}),
              ),
            );
          },
          child: const Text(
            'Continue',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }

  // SAME SIGNAL CARD (kept)
  Widget _signalCard({
    required int score,
    required Color accent,
    required double intensity,
  }) {
    String title;
    String desc;

    if (score >= 6) {
      title = 'High Tier';
      desc = 'This level usually stands out instantly in real life.';
    } else if (score == 5) {
      title = 'Strong Presence';
      desc = 'Clean impact. People notice you faster than average.';
    } else if (score == 4) {
      title = 'Above Average';
      desc = 'Good base impression. Styling can push it higher.';
    } else if (score == 3) {
      title = 'Neutral';
      desc = 'Most people won’t react strongly. Glow-up changes this.';
    } else {
      title = 'Low Signal';
      desc = 'Bad lighting/angle can kill the result. Use front-facing photo.';
    }

    final glow = accent.withOpacity(0.10 * intensity);

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(color: glow, blurRadius: 24, offset: const Offset(0, 14)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: accent.withOpacity(0.12),
              border: Border.all(color: accent.withOpacity(0.28)),
            ),
            child: Icon(Icons.flash_on_rounded, color: accent.withOpacity(0.92), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withOpacity(0.92),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.58),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = _readDisplayScore();
    final label = _readLabel();
    final confidence = _readConfidence();

    final intensity = _intensityFromScore(score);
    final accent = _accentFromScore(score);
    final oneLiner = _viralOneLiner(score);

    const double faceSize = 206;
    const double ringSize = 270;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF12121A), Color(0xFF0E0E14), Color(0xFF0B0B0F)],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),

              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _flamePulse,
                    builder: (context, _) => CustomPaint(
                      painter: _FlameGlowPainter(
                        pulse: _flamePulse.value,
                        intensity: intensity,
                        accent: accent,
                      ),
                    ),
                  ),
                ),
              ),

              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _embers,
                    builder: (context, _) => CustomPaint(
                      painter: _EmbersPainter(
                        t: _embers.value,
                        embers: _emberList,
                        intensity: intensity,
                        accent: accent,
                      ),
                    ),
                  ),
                ),
              ),

              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.022,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 0.6, sigmaY: 0.6),
                      child: Container(color: Colors.white),
                    ),
                  ),
                ),
              ),

              Positioned.fill(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                        child: Align(alignment: Alignment.topRight, child: _scaleBadge()),
                      ),
                      const SizedBox(height: 10),

                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipOval(
                            child: Image.file(
                              widget.imageFile,
                              width: faceSize,
                              height: faceSize,
                              fit: BoxFit.cover,
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _ring,
                            builder: (context, _) => CustomPaint(
                              size: const Size(ringSize, ringSize),
                              painter: _AppealRingPainter(
                                rotation: _ring.value * 2 * math.pi,
                                main: accent == Colors.white ? blue : accent,
                                intensity: intensity,
                              ),
                            ),
                          ),
                          IgnorePointer(
                            child: Container(
                              width: ringSize,
                              height: ringSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),
                      Text(
                        'Appeal',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: Colors.white.withOpacity(0.70),
                        ),
                      ),
                      const SizedBox(height: 10),

                      _scoreLine(score: score, accent: accent),

                      const SizedBox(height: 8),
                      _tierPill(label: label, accent: accent),

                      const SizedBox(height: 16),

                      // ✅ ONLY 1 sentence
                      Text(
                        oneLiner,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withOpacity(0.92),
                        ),
                      ),

                      _tierBar(score: score, accent: accent),
                      _confidenceCard(confidence: confidence, accent: accent),

                      AnimatedBuilder(
                        animation: _float,
                        builder: (context, _) {
                          final dy = math.sin(_float.value * 2 * math.pi) * 4.0;
                          return Transform.translate(
                            offset: Offset(0, dy),
                            child: _signalCard(
                              score: score,
                              accent: accent,
                              intensity: intensity,
                            ),
                          );
                        },
                      ),

                      _continueButton(context, accent),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ========================
/// PAINTERS + PARTICLES (same as your original)
/// ========================
class _AppealRingPainter extends CustomPainter {
  final double rotation;
  final Color main;
  final double intensity;

  _AppealRingPainter({
    required this.rotation,
    required this.main,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final double stroke = 12 + (intensity * 2.0);

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        transform: GradientRotation(rotation),
        colors: <Color>[
          main.withOpacity(0.95),
          _AppealPalette.purple.withOpacity(0.95),
          _AppealPalette.orange.withOpacity(0.95),
          _AppealPalette.blue.withOpacity(0.95),
          main.withOpacity(0.95),
        ],
      ).createShader(rect);

    canvas.drawOval(rect.deflate(6), paint);

    final Paint inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white.withOpacity(0.06);

    canvas.drawOval(rect.deflate(22), inner);

    if (intensity > 0.55) {
      final Paint glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = main.withOpacity(0.10 + intensity * 0.10);

      canvas.drawOval(rect.deflate(2), glow);
    }
  }

  @override
  bool shouldRepaint(covariant _AppealRingPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.main != main ||
        oldDelegate.intensity != intensity;
  }
}

class _AppealPalette {
  static const Color blue = Color(0xFF7FB6FF);
  static const Color purple = Color(0xFF9D7CFF);
  static const Color orange = Color(0xFFFF8A5B);
}

class _FlameGlowPainter extends CustomPainter {
  final double pulse;
  final double intensity;
  final Color accent;

  _FlameGlowPainter({
    required this.pulse,
    required this.intensity,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final a = (0.06 + intensity * 0.18) * (0.70 + 0.30 * pulse);

    final Rect bottom = Rect.fromLTWH(0, h * 0.55, w, h * 0.45);
    final Paint p1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          accent.withOpacity(a),
          _AppealPalette.orange.withOpacity(a * 0.75),
          Colors.transparent,
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(bottom);

    canvas.drawRect(bottom, p1);

    final Rect left = Rect.fromLTWH(0, h * 0.10, w * 0.40, h * 0.80);
    final Paint p2 = Paint()
      ..shader = RadialGradient(
        center: Alignment.centerLeft,
        radius: 1.2,
        colors: [
          _AppealPalette.purple.withOpacity(a * 0.65),
          Colors.transparent,
        ],
      ).createShader(left);

    canvas.drawRect(left, p2);

    final Rect right = Rect.fromLTWH(w * 0.60, h * 0.10, w * 0.40, h * 0.80);
    final Paint p3 = Paint()
      ..shader = RadialGradient(
        center: Alignment.centerRight,
        radius: 1.2,
        colors: [
          _AppealPalette.blue.withOpacity(a * 0.65),
          Colors.transparent,
        ],
      ).createShader(right);

    canvas.drawRect(right, p3);

    final Rect top = Rect.fromLTWH(0, 0, w, h * 0.28);
    final Paint vignette = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withOpacity(0.45),
          Colors.transparent,
        ],
      ).createShader(top);

    canvas.drawRect(top, vignette);
  }

  @override
  bool shouldRepaint(covariant _FlameGlowPainter oldDelegate) {
    return oldDelegate.pulse != pulse ||
        oldDelegate.intensity != intensity ||
        oldDelegate.accent != accent;
  }
}

class _EmbersPainter extends CustomPainter {
  final double t;
  final List<_Ember> embers;
  final double intensity;
  final Color accent;

  _EmbersPainter({
    required this.t,
    required this.embers,
    required this.intensity,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0.18) return;

    final w = size.width;
    final h = size.height;

    final visibleCount = (embers.length * (0.45 + intensity * 0.55)).round();

    for (int i = 0; i < visibleCount; i++) {
      final e = embers[i];
      final double up = (t * e.speed) % 1.0;

      final double y = (e.y - up);
      final double yy = y < 0 ? (y + 1.0) : y;

      final double wob = math.sin((t * 2 * math.pi) + e.seed) * 0.015 * e.wobble;
      final double xx = (e.x + wob) % 1.0;

      final double r = e.size * (0.75 + intensity * 0.55);
      final double alpha = (0.05 + intensity * 0.22) * e.fade;

      final Color c = Color.lerp(
            accent.withOpacity(alpha),
            _AppealPalette.orange.withOpacity(alpha),
            0.55,
          ) ??
          accent.withOpacity(alpha);

      canvas.drawCircle(Offset(xx * w, yy * h), r, Paint()..color = c);
    }
  }

  @override
  bool shouldRepaint(covariant _EmbersPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.intensity != intensity ||
        oldDelegate.accent != accent;
  }
}

class _Ember {
  final double seed;
  final double x;
  final double y;
  final double size;
  final double speed;
  final double wobble;
  final double fade;

  _Ember({
    required this.seed,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.wobble,
    required this.fade,
  });
}