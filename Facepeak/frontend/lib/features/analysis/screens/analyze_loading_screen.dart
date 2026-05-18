// 🔥 ANALYZE LOADING (FREE PSL) — CLEAN CINEMATIC UI

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/features/analysis/screens/analysis_block.dart' as analysis;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/features/Social_free/social_features/social_auth_guard.dart';

class AnalyzeLoadingScreen extends StatefulWidget {
  final File imageFile;
  final void Function(Map<String, dynamic> psl) onFinished;
  final void Function(String message) onError;

  const AnalyzeLoadingScreen({
    super.key,
    required this.imageFile,
    required this.onFinished,
    required this.onError,
  });

  @override
  State<AnalyzeLoadingScreen> createState() => _AnalyzeLoadingScreenState();
}

class _AnalyzeLoadingScreenState extends State<AnalyzeLoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _fade;
  late final AnimationController _progressCtrl;
  late final AnimationController _scan;
  late final AnimationController _orbit;
  late final Animation<double> _opacity;

  bool _done = false;

  static const Color bg = Color(0xFF02040A);
  static const Color bg2 = Color(0xFF070B16);

  static const Color gold = Color(0xFFFFC34D);
  static const Color gold2 = Color(0xFFFFD978);
  static const Color gold3 = Color(0xFFFFE7A8);

  static const Color purple = Color(0xFF8A3FFC);
  static const Color purple2 = Color(0xFFC77DFF);
  static const Color blue = Color(0xFF63D8FF);

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);

    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..forward();

    _scan = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);

    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();

    _opacity = CurvedAnimation(
      parent: _fade,
      curve: Curves.easeOut,
    );

    _fade.forward();
    _startAnalysis();
  }

  double _readDouble(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse("$v") ?? 0.0;

  String _readString(dynamic v) => v?.toString() ?? "";

  void _finish(Map<String, dynamic> psl) {
    if (_done) return;
    _done = true;

    if (!mounted) return;
    widget.onFinished(psl);
  }

  void _fail(String message) {
    if (_done) return;
    _done = true;

    if (!mounted) return;
    widget.onError(message);
  }

  void _handleError(dynamic result) {
  final message =
      result?["message"]?.toString() ??
      result?["detail"]?.toString() ??
      "Something went wrong.";

  _fail(message);
}

Future<void> _startAnalysis() async {
  try {
    final token = await SocialAuthGuard.ensureBackendToken();

    if (!mounted || _done) return;

    if (token == null || token.isEmpty) {
      _fail("Google sign-in is required to continue.");
      return;
    }

    final result = await analysis.AnalysisBlock.runPslAnalysis(
      imageFile: widget.imageFile,
      accessToken: token,
    );

    if (!mounted || _done) return;

    if (result["status"] != "success") {
      _handleError(result);
      return;
    }

    final psl = result["psl"];

    if (psl == null || psl is! Map) {
      _handleError(result);
      return;
    }

    final safePsl = <String, dynamic>{
      "psl_score": (psl["psl_score"] is num)
          ? (psl["psl_score"] as num).toDouble()
          : 0.0,
      "tier": _readString(psl["tier"]),
      "percentile": psl["percentile"] ?? "",
      "confidence": _readDouble(psl["confidence"]),
      "stable_score_float": _readDouble(psl["stable_score_float"]),
      "raw_expected": _readDouble(psl["raw_expected"]),
      "bonus_applied": _readDouble(psl["bonus_applied"]),
      "strengths": (result["strengths"] is List)
          ? result["strengths"]
          : (psl["strengths"] is List ? psl["strengths"] : []),
      "limits": (result["limits"] is List)
          ? result["limits"]
          : (psl["limits"] is List ? psl["limits"] : []),
      "is_cached": result["is_cached"] == true,
    };

    _finish(safePsl);
  } catch (e) {
    if (!mounted || _done) return;

    final error = e.toString().toLowerCase();

    debugPrint("X_LOADING_ERROR = $error");

    if (error.contains("auth_required") ||
        error.contains("401") ||
        error.contains("403") ||
        error.contains("invalid_token") ||
        error.contains("missing_auth")) {
      _fail("Google sign-in is required to continue.");
      return;
    }

    if (error.contains("422") ||
        error.contains("unprocessable") ||
        error.contains("no_face_detected") ||
        error.contains("no face detected") ||
        error.contains("no face") ||
        error.contains("face could not be detected")) {
      _fail(
        "No face detected. Center your full face and hair inside the camera and try again.",
      );
      return;
    }

    if (error.contains("socket") ||
        error.contains("network") ||
        error.contains("connection") ||
        error.contains("internet") ||
        error.contains("failed host lookup")) {
      _fail(
        "No internet connection. Check your Wi-Fi or mobile data and try again.",
      );
      return;
    }

    if (error.contains("timeout")) {
      _fail("Connection timed out. Please try again in a moment.");
      return;
    }

    if (error.contains("429") ||
        error.contains("too_many") ||
        error.contains("rate_limited") ||
        error.contains("rate")) {
      _fail("You’ve already used your free analysis.");
      return;
    }

    if (error.contains("500") ||
        error.contains("server") ||
        error.contains("internal")) {
      _fail("Servers are temporarily busy. Please try again shortly.");
      return;
    }

    _fail("Something went wrong while processing your photo. Please try again.");
  }
}

  @override
  void dispose() {
    _pulse.dispose();
    _fade.dispose();
    _progressCtrl.dispose();
    _scan.dispose();
    _orbit.dispose();
    super.dispose();
  }

  double _uiProgressValue() {
    return (0.12 + (_progressCtrl.value * 0.84)).clamp(0.0, 0.985);
  }

  String _progressText() {
    final percent = (_uiProgressValue() * 100).floor().clamp(1, 99);
    return "$percent%";
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final lockedMedia = media.copyWith(
      textScaler: const TextScaler.linear(1.0),
    );

    return MediaQuery(
      data: lockedMedia,
      child: Scaffold(
        backgroundColor: bg,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [bg, bg2, bg],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: _backgroundFx()),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    final screenHeight = constraints.maxHeight;
                    final compact = screenHeight < 760;

                    final imageSize =
                        math.min(screenWidth * 0.72, screenHeight * 0.36);

                    return FadeTransition(
                      opacity: _opacity,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          22,
                          compact ? 12 : 18,
                          22,
                          compact ? 18 : 24,
                        ),
                        child: Column(
                          children: [
                            _topRow(),
                            const Spacer(),
                            _hero(imageSize: imageSize),
                            SizedBox(height: compact ? 34 : 44),
                            _titleBlock(compact: compact),
                            SizedBox(height: compact ? 30 : 38),
                            _progressBlock(),
                            const Spacer(flex: 2),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backgroundFx() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _orbit]),
      builder: (context, _) {
        final p = _pulse.value;
        final t = _orbit.value * math.pi * 2;

        return Stack(
          children: [
            Positioned(
              top: -120,
              left: -120,
              right: -120,
              child: Container(
                height: 360,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      purple.withOpacity(0.12 + p * 0.04),
                      purple.withOpacity(0.035),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 170 + math.sin(t) * 18,
              left: -140,
              right: -140,
              child: Container(
                height: 440,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      gold.withOpacity(0.09 + p * 0.035),
                      purple.withOpacity(0.035),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -160,
              left: -130,
              right: -130,
              child: Container(
                height: 360,
                decoration: BoxDecoration(
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
      },
    );
  }

  Widget _topRow() {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            return Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [gold2, purple2],
                ),
                boxShadow: [
                  BoxShadow(
                    color: purple.withOpacity(0.35 + _pulse.value * 0.25),
                    blurRadius: 18,
                  ),
                  BoxShadow(
                    color: gold.withOpacity(0.25),
                    blurRadius: 14,
                  ),
                ],
              ),
            );
          },
        ),
        const Spacer(),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withOpacity(0.045),
                border: Border.all(
                  color: purple2.withOpacity(0.20),
                ),
              ),
              child: Text(
                _progressText(),
                style: const TextStyle(
                  color: gold2,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _hero({required double imageSize}) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _scan, _orbit]),
      builder: (context, _) {
        final pulse = _pulse.value;
        final scanY = (_scan.value * imageSize).clamp(26.0, imageSize - 26.0);

        return SizedBox(
          width: imageSize + 78,
          height: imageSize + 78,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: imageSize + 74,
                height: imageSize + 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: purple.withOpacity(0.22 + pulse * 0.12),
                      blurRadius: 80,
                      spreadRadius: 8,
                    ),
                    BoxShadow(
                      color: gold.withOpacity(0.15 + pulse * 0.10),
                      blurRadius: 54,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              RotationTransition(
                turns: _orbit,
                child: CustomPaint(
                  size: Size(imageSize + 56, imageSize + 56),
                  painter: _CleanOrbitPainter(
                    gold: gold2.withOpacity(0.80),
                    purple: purple2.withOpacity(0.75),
                  ),
                ),
              ),
              Container(
                width: imageSize,
                height: imageSize,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(42),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      gold2,
                      purple2,
                      blue,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: purple.withOpacity(0.34),
                      blurRadius: 36,
                    ),
                    BoxShadow(
                      color: gold.withOpacity(0.22),
                      blurRadius: 34,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.48),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.file(
                          widget.imageFile,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.10),
                                Colors.transparent,
                                Colors.black.withOpacity(0.28),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _MinimalGridPainter(
                            color: Colors.white.withOpacity(0.035),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: scanY - 46,
                        child: Container(
                          height: 92,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                purple.withOpacity(0.06),
                                gold.withOpacity(0.10),
                                gold2.withOpacity(0.16),
                                purple2.withOpacity(0.07),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: scanY - 2,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                purple2,
                                gold2,
                                gold3,
                                gold2,
                                purple2,
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: gold.withOpacity(0.55),
                                blurRadius: 20,
                              ),
                              BoxShadow(
                                color: purple.withOpacity(0.45),
                                blurRadius: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _titleBlock({required bool compact}) {
    return Column(
      children: [
        Text(
          "Comparing to millions of faces",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact ? 29 : 34,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1.25,
            height: 1.02,
            shadows: [
              Shadow(
                color: purple.withOpacity(0.24),
                blurRadius: 24,
              ),
              Shadow(
                color: gold.withOpacity(0.14),
                blurRadius: 18,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Building your rank",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact ? 14 : 15,
            fontWeight: FontWeight.w800,
            color: Colors.white.withOpacity(0.54),
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _progressBlock() {
    return AnimatedBuilder(
      animation: Listenable.merge([_progressCtrl, _pulse, _orbit]),
      builder: (context, _) {
        final value = _uiProgressValue();
        final shimmer = (_orbit.value * 2.0) - 0.6;

        return Column(
          children: [
            Container(
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withOpacity(0.055),
                border: Border.all(
                  color: Colors.white.withOpacity(0.055),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              purple,
                              purple2,
                              gold,
                              gold3,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: purple.withOpacity(0.35),
                              blurRadius: 20,
                            ),
                            BoxShadow(
                              color: gold.withOpacity(0.25),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: value,
                      child: Align(
                        alignment: Alignment(shimmer, 0),
                        child: Container(
                          width: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0),
                                Colors.white.withOpacity(0.38),
                                Colors.white.withOpacity(0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 13),
            Text(
              _progressText(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: gold2,
                letterSpacing: -0.2,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CleanOrbitPainter extends CustomPainter {
  final Color gold;
  final Color purple;

  const _CleanOrbitPainter({
    required this.gold,
    required this.purple,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final goldPaint = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final purplePaint = Paint()
      ..color = purple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect.deflate(10),
      -math.pi / 2,
      math.pi * 0.34,
      false,
      goldPaint,
    );

    canvas.drawArc(
      rect.deflate(18),
      math.pi * 0.35,
      math.pi * 0.24,
      false,
      purplePaint,
    );

    canvas.drawArc(
      rect.deflate(24),
      math.pi * 1.08,
      math.pi * 0.22,
      false,
      goldPaint..color = gold.withOpacity(0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _CleanOrbitPainter oldDelegate) {
    return oldDelegate.gold != gold || oldDelegate.purple != purple;
  }
}

class _MinimalGridPainter extends CustomPainter {
  final Color color;

  const _MinimalGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.75;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    final soft = Paint()
      ..color = color.withOpacity(0.55)
      ..strokeWidth = 0.55;

    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      soft,
    );

    canvas.drawLine(
      Offset((size.width / 3) * 2, 0),
      Offset((size.width / 3) * 2, size.height),
      soft,
    );
  }

  @override
  bool shouldRepaint(covariant _MinimalGridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}