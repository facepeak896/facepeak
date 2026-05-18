import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/features/analysis/screens/analysis_block.dart'
    as analysis;


import 'social_api.dart';
import 'social_live_screen.dart';

import 'package:frontend/features/analysis/screens/app_state.dart';

class AnalyzePslLoadingScreen extends StatefulWidget {
  final File imageFile;
  final void Function(Map<String, dynamic> psl) onFinished;
  final void Function(String message) onError;
  final String guestToken;
  final Map<String, dynamic> userSnapshot;
  final String? accessToken;

  const AnalyzePslLoadingScreen({
    super.key,
    required this.imageFile,
    required this.onFinished,
    required this.onError,
    required this.guestToken,
    required this.userSnapshot,
    this.accessToken,
  });

  @override
  State<AnalyzePslLoadingScreen> createState() =>
      _AnalyzeLoadingScreenState();
}

class _AnalyzeLoadingScreenState extends State<AnalyzePslLoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _fade;
  late final AnimationController _progressCtrl;
  late final AnimationController _scan;
  late final AnimationController _orbit;
  late final AnimationController _ring;
  late final AnimationController _particles;
  late final Animation<double> _opacity;

  Timer? _stepTimer;
  Timer? _timeoutTimer;

  int _step = 0;
  bool _navigated = false;
  bool _completed = false;

  double _progress = 0.08;

  static const Color bg = Color(0xFF02050A);
  static const Color bg2 = Color(0xFF07111A);
  static const Color panel = Color(0xCC0B1220);

  static const Color gold = Color(0xFFFFC34D);
  static const Color gold2 = Color(0xFFFFD978);
  static const Color gold3 = Color(0xFFFFE7A8);
  static const Color goldDeep = Color(0xFFC68613);

  static const List<String> _steps = [
    'Reading structure',
    'Checking harmony',
    'Scoring face',
    'Launching',
  ];

  static const List<String> _substeps = [
    'Million-face match',
    'Balance + alignment',
    'Score + percentile',
    'Finalizing',
  ];

  static const List<String> _miniStates = [
    'Structure',
    'Harmony',
    'Percentile',
    'Confidence',
  ];

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..forward();

    _scan = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1650),
    )..repeat(reverse: true);

    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();

    _ring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _particles = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();

    _opacity = CurvedAnimation(
      parent: _fade,
      curve: Curves.easeOut,
    );

    _fade.forward();
    _startSteps();
    
    _startAnalysis();
  }

  int _readInt(dynamic v) => v is int ? v : int.tryParse("$v") ?? 0;

  double _readDouble(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse("$v") ?? 0.0;

  String _readString(dynamic v) => v?.toString() ?? "";
  // 👉 TU DODAJ
  int? _readPercentileNumber(dynamic v) {
  if (v == null) return null;

  if (v is int) return v;
  if (v is num) return v.toInt();

  final s = v.toString();
  final match = RegExp(r'\d+').firstMatch(s);
  if (match == null) return null;

  final n = int.tryParse(match.group(0)!);
  if (n == null) return null;

  return n.clamp(1, 100);
  }

  String _percentileTextFrom(dynamic percentile) {
    if (percentile == null) return "";
    if (percentile is String) return percentile;
    if (percentile is num) return "Top ${percentile.toInt()}%";
    return percentile.toString();
  }

  String _rangeTextFromConfidence(double c) {
    double min;
    double max;

    if (c >= 0.9) {
      min = 0.1;
      max = 0.2;
    } else if (c >= 0.8) {
      min = 0.1;
      max = 0.25;
    } else if (c >= 0.7) {
      min = 0.1;
      max = 0.3;
    } else if (c >= 0.5) {
      min = 0.2;
      max = 0.4;
    } else {
      min = 0.3;
      max = 0.5;
    }

    return "+${min.toStringAsFixed(1)} → +${max.toStringAsFixed(1)} PSL";
  }
  void _navigateNext(Map user, Map psl) {
  if (_navigated || !mounted) return;

  _navigated = true;
  _stepTimer?.cancel();
  _timeoutTimer?.cancel();

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => SocialLiveScreen(
        user: user.cast<String, dynamic>(),
        psl: psl.cast<String, dynamic>(),
      ),
    ),
    (route) => false,
  );
}

  void _startSteps() {
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1000), (t) {
      if (!mounted || _completed) return;

      if (_step < _steps.length - 1) {
        setState(() {
          _step++;
          _progress = (_progress + 0.18).clamp(0.0, 0.88);
        });
      } else {
        t.cancel();
      }
    });
  }

  

  Future<void> _startAnalysis() async {
  try {
    final result = await analysis.AnalysisBlock.runFreePslAnalysis(
  imageFile: widget.imageFile,
  guestToken: widget.guestToken,
  accessToken: widget.accessToken,
);

    if (!mounted || _navigated) return;

    if (result == null || result["status"] != "success") {
      _handleFail("Analysis failed. Please try again.");
      return;
    }

    final psl = result["psl"];
    if (psl == null) {
      _handleFail("Analysis result missing. Please try again.");
      return;
    }

    _completed = true;

    final confidence = _readDouble(psl["confidence"]);
    final percentileText = _percentileTextFrom(psl["percentile"]);
    final weeklyPotential = _rangeTextFromConfidence(confidence);
    final percentileNumber = _readPercentileNumber(psl["percentile"]);

    final token = await AppState.getToken();
    if (token == null || token.isEmpty) {
      _handleFail("Login expired. Please sign in again.");
      return;
    }

    await SocialApi.saveAnalysisProfile(
      token: token,
      imageFile: widget.imageFile,
      weeklyPotentialRange: weeklyPotential,
      reachTargetPercentile: percentileNumber,
    );

    final res = await SocialApi.goLive(token: token);

    await AppState.setSocialLive(true);

    final backendUser =
        (res["user"] as Map<String, dynamic>?) ?? <String, dynamic>{};

    final backendPsl =
        (backendUser["psl"] as Map<String, dynamic>?) ?? <String, dynamic>{};

    if (backendUser.isEmpty) {
      _handleFail("Profile failed to load. Try again.");
      return;
    }

    final oldUser = widget.userSnapshot;
    final oldPsl =
        (oldUser["psl"] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    String firstNonEmpty(List<dynamic> values) {
      for (final v in values) {
        final s = v?.toString().trim() ?? "";
        if (s.isNotEmpty) return s;
      }
      return "";
    }

    int firstInt(List<dynamic> values) {
      for (final v in values) {
        final n = _readInt(v);
        if (n > 0) return n;
      }
      return 0;
    }

    double firstDouble(List<dynamic> values) {
      for (final v in values) {
        final n = _readDouble(v);
        if (n > 0) return n;
      }
      return 0.0;
    }

    String safeName(List<dynamic> values) {
      final raw = firstNonEmpty(values);
      final cleaned = raw.replaceAll(RegExp(r'[^a-zA-Z]'), '');

      if (cleaned.isEmpty) return "User";

      final cut = cleaned.length > 10 ? cleaned.substring(0, 10) : cleaned;

      return cut[0].toUpperCase() + cut.substring(1).toLowerCase();
    }

    final backendImage = firstNonEmpty([
      backendUser["profile_image_url"],
      backendUser["image"],
    ]);

    final fallbackImage = firstNonEmpty([
      oldUser["local_image_path"],
      oldUser["profile_image_url"],
      oldUser["image"],
      widget.imageFile.path,
    ]);

    final finalImage = backendImage.isNotEmpty ? backendImage : fallbackImage;

    final finalUsername = safeName([
      oldUser["username"],
      oldUser["display_name"],
      backendUser["username"],
      backendUser["display_name"],
    ]);

    final finalDisplayName = finalUsername;

    final mergedUser = <String, dynamic>{
      ...oldUser,
      ...backendUser,

      "username": finalUsername,
      "display_name": finalDisplayName,

      "image": finalImage,
      "profile_image_url": finalImage,

      "local_image_path": widget.imageFile.path,

      "bio": firstNonEmpty([
        backendUser["bio"],
        oldUser["bio"],
      ]),

      "weekly_potential_range": firstNonEmpty([
        weeklyPotential,
        backendUser["weekly_potential_range"],
        oldUser["weekly_potential_range"],
      ]),

      "reach_target_percentile": percentileNumber ??
          firstInt([
            backendUser["reach_target_percentile"],
            oldUser["reach_target_percentile"],
          ]),

      "is_live": true,

      "followers": firstInt([
        backendUser["followers"],
        oldUser["followers"],
      ]),

      "following": firstInt([
        backendUser["following"],
        oldUser["following"],
      ]),

      "matches": firstInt([
        backendUser["matches"],
        oldUser["matches"],
      ]),

      "profile_views": firstInt([
        backendUser["profile_views"],
        oldUser["profile_views"],
      ]),

      "comments": firstInt([
        backendUser["comments"],
        oldUser["comments"],
      ]),

      "posts": firstInt([
        backendUser["posts"],
        oldUser["posts"],
      ]),
    };

    final mergedPsl = <String, dynamic>{
      ...oldPsl,
      ...backendPsl,
      ...psl,

      "psl_score": firstInt([
        psl["psl_score"],
        backendPsl["psl_score"],
        oldPsl["psl_score"],
      ]),

      "tier": firstNonEmpty([
        psl["tier"],
        backendPsl["tier"],
        oldPsl["tier"],
      ]),

      "percentile": firstNonEmpty([
        percentileText,
        psl["percentile"],
        backendPsl["percentile"],
        oldPsl["percentile"],
      ]),

      "confidence": firstDouble([
        psl["confidence"],
        backendPsl["confidence"],
        oldPsl["confidence"],
      ]),

      "weekly_potential_range": firstNonEmpty([
        weeklyPotential,
        backendUser["weekly_potential_range"],
        oldUser["weekly_potential_range"],
        oldPsl["weekly_potential_range"],
      ]),
    };

    await AppState.setSocialSnapshot(
      user: mergedUser,
      psl: mergedPsl,
    );

    widget.onFinished(mergedPsl.cast<String, dynamic>());
    _navigateNext(mergedUser, mergedPsl);
  } catch (e) {
  final error = e.toString().toLowerCase();

  // FACE NOT DETECTED
  if (error.contains("422") ||
      error.contains("unprocessable") ||
      error.contains("no_face_detected") ||
      error.contains("no face detected") ||
      error.contains("no face") ||
      error.contains("face could not be detected")) {
    _handleFail(
      "No face detected. Center your full face and hair inside the camera and try again.",
    );
    return;
  }

  // INTERNET
  if (error.contains("socket") ||
      error.contains("network") ||
      error.contains("connection") ||
      error.contains("internet") ||
      error.contains("failed host lookup")) {
    _handleFail(
      "No internet connection. Check your Wi-Fi or mobile data and try again.",
    );
    return;
  }

  // TIMEOUT
  if (error.contains("timeout")) {
    _handleFail(
      "Connection timed out. Please try again in a moment.",
    );
    return;
  }

  // RATE LIMIT
  if (error.contains("429") ||
      error.contains("too_many") ||
      error.contains("rate")) {
    _handleFail(
      "Too many attempts. Please wait a bit before trying again.",
    );
    return;
  }

  // AUTH
  if (error.contains("401") ||
      error.contains("unauthorized")) {
    _handleFail(
      "Session expired. Please sign in again.",
    );
    return;
  }

  // SERVER
  if (error.contains("500") ||
      error.contains("internal server") ||
      error.contains("server")) {
    _handleFail(
      "Servers are temporarily busy. Please try again shortly.",
    );
    return;
  }

  // UNKNOWN
  _handleFail(
    "Something went wrong while processing your photo. Please try again.",
  );
}}

  void _handleFail([
  String message = "Something went wrong. Please try again.",
]) {
  if (_navigated) return;

  _navigated = true;

  _stepTimer?.cancel();
  _timeoutTimer?.cancel();

  if (!mounted) return;

  Navigator.of(context).pop();

  widget.onError(message);
}

  @override
  void dispose() {
    _stepTimer?.cancel();
    _timeoutTimer?.cancel();
    _pulse.dispose();
    _fade.dispose();
    _progressCtrl.dispose();
    _scan.dispose();
    _orbit.dispose();
    _ring.dispose();
    _particles.dispose();
    super.dispose();
  }

  double _uiProgressValue() {
    return (_progress + (_progressCtrl.value * 0.18)).clamp(0.0, 0.985);
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
                        math.min(screenWidth * 0.72, screenHeight * 0.35);
                    final frameSize =
                        math.min(screenWidth * 0.84, screenHeight * 0.45);

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            compact ? 10 : 16,
                            20,
                            compact ? 16 : 22,
                          ),
                          child: FadeTransition(
                            opacity: _opacity,
                            child: Column(
                              children: [
                                _topRow(),
                                SizedBox(height: compact ? 20 : 24),
                                _hero(
                                  imageSize: imageSize,
                                  frameSize: frameSize,
                                ),
                                SizedBox(height: compact ? 22 : 28),
                                _titleBlock(compact: compact),
                                SizedBox(height: compact ? 14 : 18),
                                _miniStatesRow(compact: compact),
                                SizedBox(height: compact ? 24 : 28),
                                _progressBlock(),
                                SizedBox(height: compact ? 22 : 26),
                                _bottomPill(),
                              ],
                            ),
                          ),
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
      animation: Listenable.merge([_pulse, _orbit, _particles]),
      builder: (context, _) {
        final p = _pulse.value;
        final orb = _orbit.value * math.pi * 2;

        return Stack(
          children: [
            Positioned(
              top: -120,
              left: -90,
              right: -90,
              child: IgnorePointer(
                child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        gold.withOpacity(0.05 + p * 0.03),
                        gold.withOpacity(0.01),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 130 + math.sin(orb) * 10,
              left: -120,
              right: -120,
              child: IgnorePointer(
                child: Container(
                  height: 420,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        gold2.withOpacity(0.04 + p * 0.025),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _LuxuryParticlePainter(
                    t: _particles.value,
                    color: gold2.withOpacity(0.16),
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
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: gold2,
            boxShadow: [
              BoxShadow(
                color: gold.withOpacity(0.55),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withOpacity(0.03),
            border: Border.all(
              color: gold.withOpacity(0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: gold.withOpacity(0.06),
                blurRadius: 14,
              ),
            ],
          ),
          child: Text(
            _progressText(),
            style: const TextStyle(
              color: gold2,
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _hero({
    required double imageSize,
    required double frameSize,
  }) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _scan, _orbit, _ring]),
      builder: (context, _) {
        final pulse = _pulse.value;
        final scanY = (_scan.value * imageSize).clamp(24.0, imageSize - 24.0);

        return SizedBox(
          width: frameSize,
          height: frameSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: frameSize * 0.94,
                height: frameSize * 0.94,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gold.withOpacity(0.16 + pulse * 0.14),
                      blurRadius: 34 + pulse * 14,
                      spreadRadius: 1.5,
                    ),
                    BoxShadow(
                      color: gold2.withOpacity(0.10),
                      blurRadius: 120,
                    ),
                  ],
                ),
              ),
              RotationTransition(
                turns: _ring,
                child: CustomPaint(
                  size: Size(frameSize * 0.90, frameSize * 0.90),
                  painter: _LuxuryOrbitPainter(
                    color: gold.withOpacity(0.42),
                    bright: gold2.withOpacity(0.98),
                  ),
                ),
              ),
              RotationTransition(
                turns: Tween<double>(begin: 1, end: 0).animate(_orbit),
                child: CustomPaint(
                  size: Size(frameSize * 0.78, frameSize * 0.78),
                  painter: _InnerOrbitPainter(
                    color: gold3.withOpacity(0.55),
                  ),
                ),
              ),
              Container(
                width: imageSize + 14,
                height: imageSize + 14,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      gold3.withOpacity(0.16),
                      gold.withOpacity(0.08),
                      Colors.white.withOpacity(0.02),
                    ],
                  ),
                  border: Border.all(
                    color: gold.withOpacity(0.30),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gold.withOpacity(0.16),
                      blurRadius: 26,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.45),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
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
                                Colors.white.withOpacity(0.04),
                                Colors.transparent,
                                Colors.black.withOpacity(0.11),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _CinematicHudPainter(
                              lineColor: Colors.white.withOpacity(0.038),
                              accent: gold.withOpacity(0.14),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: scanY - 52,
                        child: Container(
                          height: 104,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                gold.withOpacity(0.025),
                                gold.withOpacity(0.06),
                                gold2.withOpacity(0.13),
                                gold.withOpacity(0.06),
                                gold.withOpacity(0.025),
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
                                gold,
                                gold2,
                                gold3,
                                gold2,
                                gold,
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: gold.withOpacity(0.45),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 18,
                        left: 18,
                        child: _node(),
                      ),
                      Positioned(
                        top: 18,
                        right: 18,
                        child: _node(),
                      ),
                      Positioned(
                        bottom: 18,
                        left: 18,
                        child: _node(),
                      ),
                      Positioned(
                        bottom: 18,
                        right: 18,
                        child: _node(),
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

  Widget _node() {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: gold2,
        boxShadow: [
          BoxShadow(
            color: gold.withOpacity(0.40),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }

  Widget _titleBlock({required bool compact}) {
    return SizedBox(
      height: compact ? 84 : 92,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Text(
              _steps[_step],
              key: ValueKey("title_$_step"),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 30 : 34,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1.2,
                height: 0.95,
                shadows: [
                  Shadow(
                    color: gold.withOpacity(0.14),
                    blurRadius: 22,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Text(
              _substeps[_step],
              key: ValueKey("subtitle_$_step"),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 13.5 : 14.2,
                fontWeight: FontWeight.w800,
                color: Colors.white.withOpacity(0.62),
                height: 1.0,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStatesRow({required bool compact}) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: List.generate(_miniStates.length, (i) {
        final active = i <= _step;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: active
                ? gold.withOpacity(0.11)
                : Colors.white.withOpacity(0.025),
            border: Border.all(
              color: active
                  ? gold.withOpacity(0.22)
                  : Colors.white.withOpacity(0.05),
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: gold.withOpacity(0.08),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5.5,
                height: 5.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? gold2 : Colors.white24,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _miniStates[i],
                style: TextStyle(
                  color: active ? Colors.white : Colors.white54,
                  fontSize: compact ? 11.2 : 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _progressBlock() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_progressCtrl, _pulse, _orbit]),
          builder: (context, _) {
            final value = _uiProgressValue();
            final pulse = _pulse.value;
            final shimmer = (_orbit.value * 1.5) - 0.25;

            return Container(
              height: 13,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
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
                            colors: [goldDeep, gold, gold2, gold3],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: gold.withOpacity(0.26 + pulse * 0.10),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (value > 0.06)
                      FractionallySizedBox(
                        widthFactor: value,
                        child: Align(
                          alignment: Alignment(shimmer, 0),
                          child: Container(
                            width: 62,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.00),
                                  Colors.white.withOpacity(0.36),
                                  Colors.white.withOpacity(0.00),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              "Calibrating",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white.withOpacity(0.72),
              ),
            ),
            const Spacer(),
            Text(
              _progressText(),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: gold2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bottomPill() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: panel,
            border: Border.all(
              color: gold.withOpacity(0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: gold.withOpacity(0.07),
                blurRadius: 18,
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bolt_rounded,
                size: 16,
                color: gold2,
              ),
              SizedBox(width: 8),
              Text(
                "Finalizing profile",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LuxuryOrbitPainter extends CustomPainter {
  final Color color;
  final Color bright;

  const _LuxuryOrbitPainter({
    required this.color,
    required this.bright,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final p1 = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final p2 = Paint()
      ..color = bright
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect.deflate(8),
      -math.pi / 2.25,
      math.pi * 0.30,
      false,
      p2,
    );

    canvas.drawArc(
      rect.deflate(16),
      math.pi * 0.16,
      math.pi * 0.24,
      false,
      p1,
    );

    canvas.drawArc(
      rect.deflate(16),
      math.pi * 1.04,
      math.pi * 0.28,
      false,
      p1..color = color.withOpacity(0.75),
    );

    canvas.drawArc(
      rect.deflate(24),
      math.pi * 0.72,
      math.pi * 0.14,
      false,
      p2..color = bright.withOpacity(0.82),
    );
  }

  @override
  bool shouldRepaint(covariant _LuxuryOrbitPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.bright != bright;
  }
}

class _InnerOrbitPainter extends CustomPainter {
  final Color color;

  const _InnerOrbitPainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect.deflate(12),
      math.pi * 0.08,
      math.pi * 0.18,
      false,
      paint,
    );
    canvas.drawArc(
      rect.deflate(12),
      math.pi * 0.90,
      math.pi * 0.16,
      false,
      paint..color = color.withOpacity(0.7),
    );
  }

  @override
  bool shouldRepaint(covariant _InnerOrbitPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _CinematicHudPainter extends CustomPainter {
  final Color lineColor;
  final Color accent;

  const _CinematicHudPainter({
    required this.lineColor,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final thin = Paint()
      ..color = lineColor
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final accentPaint = Paint()
      ..color = accent
      ..strokeWidth = 1.05
      ..style = PaintingStyle.stroke;

    final thirdsX = [size.width / 3, (size.width / 3) * 2];
    final thirdsY = [size.height / 3, (size.height / 3) * 2];

    for (final x in thirdsX) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), thin);
    }

    for (final y in thirdsY) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), thin);
    }

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      accentPaint,
    );

    const l = 18.0;

    canvas.drawLine(Offset(0, 0), const Offset(l, 0), accentPaint);
    canvas.drawLine(Offset(0, 0), const Offset(0, l), accentPaint);

    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - l, 0),
      accentPaint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, l),
      accentPaint,
    );

    canvas.drawLine(
      Offset(0, size.height),
      Offset(l, size.height),
      accentPaint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - l),
      accentPaint,
    );

    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - l, size.height),
      accentPaint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - l),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CinematicHudPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.accent != accent;
  }
}

class _LuxuryParticlePainter extends CustomPainter {
  final double t;
  final Color color;

  const _LuxuryParticlePainter({
    required this.t,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final points = <Offset>[
      Offset(
        size.width * 0.12,
        size.height * (0.20 + (0.02 * math.sin(t * math.pi * 2))),
      ),
      Offset(
        size.width * 0.86,
        size.height * (0.26 + (0.02 * math.cos(t * math.pi * 2))),
      ),
      Offset(
        size.width * 0.22,
        size.height * (0.72 + (0.015 * math.cos(t * math.pi * 2.5))),
      ),
      Offset(
        size.width * 0.78,
        size.height * (0.66 + (0.018 * math.sin(t * math.pi * 2.3))),
      ),
      Offset(
        size.width * 0.52,
        size.height * (0.12 + (0.016 * math.sin(t * math.pi * 2.1))),
      ),
    ];

    for (final p in points) {
      canvas.drawCircle(p, 1.6, paint);
      canvas.drawCircle(
        p,
        4.8,
        Paint()..color = color.withOpacity(0.10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LuxuryParticlePainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.color != color;
  }
}