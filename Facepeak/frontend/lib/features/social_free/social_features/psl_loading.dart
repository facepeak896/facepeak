// 🔥 ANALYZE PSL LOADING — ENTERPRISE MAX (SAFE + POLISHED)

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/features/analysis/screens/analysis_block.dart' as analysis;

import 'preview_screen.dart';

class AnalyzePslLoadingScreen extends StatefulWidget {
  final File imageFile;
  final void Function(Map<String, dynamic> psl) onFinished;
  final void Function(String message) onError;
  final String guestToken;

  // 🔥 REAL SNAPSHOT FROM SOCIAL HOME / LOGIN FLOW
  final Map<String, dynamic> userSnapshot;

  const AnalyzePslLoadingScreen({
    super.key,
    required this.imageFile,
    required this.onFinished,
    required this.onError,
    required this.guestToken,
    required this.userSnapshot,
  });

  @override
  State<AnalyzePslLoadingScreen> createState() => _AnalyzeLoadingScreenState();
}

class _AnalyzeLoadingScreenState extends State<AnalyzePslLoadingScreen>
    with TickerProviderStateMixin {
  // ================= CONTROLLERS =================

  late final AnimationController _spin;
  late final AnimationController _pulse;
  late final AnimationController _fade;
  late final AnimationController _progressCtrl;

  late final Animation<double> _opacity;

  Timer? _stepTimer;
  Timer? _timeoutTimer;

  int _step = 0;
  bool _navigated = false;
  bool _completed = false;

  double _progress = 0.05;

  static const Color bg = Color(0xFF0B0E14);
  static const Color gold = Color(0xFFF5C518);

  static const List<String> _steps = [
    'Detecting facial structure',
    'Analyzing symmetry & balance',
    'Calculating PSL score',
    'Generating final result',
  ];

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..forward();

    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _opacity = CurvedAnimation(parent: _fade, curve: Curves.easeOut);
    _fade.forward();

    _startSteps();
    _startTimeout();
    _startAnalysis();
  }

  // ================= STEP FLOW =================

  void _startSteps() {
    _stepTimer = Timer.periodic(
      const Duration(milliseconds: 850),
      (t) {
        if (!mounted || _completed) return;

        if (_step < _steps.length - 1) {
          setState(() {
            _step++;
            _progress = (_progress + 0.2).clamp(0.0, 0.9);
          });
        } else {
          t.cancel();
        }
      },
    );
  }

  // ================= TIMEOUT =================

  void _startTimeout() {
    _timeoutTimer = Timer(const Duration(seconds: 20), () {
      if (!_completed) {
        _handleFail();
      }
    });
  }

  // ================= ANALYSIS =================

  Future<void> _startAnalysis() async {
    try {
      final result = await analysis.AnalysisBlock.runPslAnalysis(
        imageFile: widget.imageFile,
        guestToken: widget.guestToken,
      ).timeout(const Duration(seconds: 18));

      if (!mounted || _navigated) return;

      if (result == null || result["status"] != "success") {
        _handleFail();
        return;
      }

      final psl = result["psl"];

      if (psl == null) {
        _handleFail();
        return;
      }

      _completed = true;

      final safePsl = {
        "psl_score": (psl["psl_score"] is num)
            ? (psl["psl_score"] as num).toDouble()
            : 0.0,
        "tier": psl["tier"] ?? "",
        // 🔥 percentile can be "Top 30%" string from backend
        "percentile": psl["percentile"] ?? "",
        "confidence": (psl["confidence"] is num)
            ? (psl["confidence"] as num).toDouble()
            : 0.0,
      };

      // 🔥 REAL USER SNAPSHOT + NEW IMAGE OVERRIDE
      final safeUser = {
        ...widget.userSnapshot,
        "image": widget.imageFile.path,
      };

      _navigateNext(safeUser, safePsl);
    } catch (_) {
      _handleFail();
    }
  }

  // ================= NAVIGATION =================

  void _navigateNext(Map user, Map psl) {
    if (_navigated || !mounted) return;

    _navigated = true;

    _stepTimer?.cancel();
    _timeoutTimer?.cancel();

    setState(() {
      _progress = 1.0;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PreviewScreen(
            user: user.cast<String, dynamic>(),
            psl: psl.cast<String, dynamic>(),
          ),
        ),
      );
    });
  }

  // ================= FAIL =================

  void _handleFail() {
    if (_navigated) return;

    _navigated = true;

    _stepTimer?.cancel();
    _timeoutTimer?.cancel();

    if (!mounted) return;

    Navigator.of(context).pop();

    widget.onError("analysis_failed");
  }

  // ================= DISPOSE =================

  @override
  void dispose() {
    _stepTimer?.cancel();
    _timeoutTimer?.cancel();
    _spin.dispose();
    _fade.dispose();
    _pulse.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;

    final double imageSize = screenWidth * 0.72;
    final double glowSize = screenWidth * 0.82;

    return Scaffold(
      backgroundColor: bg,
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          media.padding.top + 40,
          24,
          media.padding.bottom + 40,
        ),
        child: FadeTransition(
          opacity: _opacity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔥 IMAGE + GLOW
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  final glow = _pulse.value;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: glowSize,
                        height: glowSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(42),
                          boxShadow: [
                            BoxShadow(
                              color: gold.withOpacity(0.22 + glow * 0.20),
                              blurRadius: 80 + glow * 28,
                            ),
                            BoxShadow(
                              color: gold.withOpacity(0.12),
                              blurRadius: 150,
                            ),
                          ],
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Container(
                          width: imageSize,
                          height: imageSize,
                          color: Colors.black,
                          child: Image.file(
                            widget.imageFile,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    RotationTransition(
                      turns: _spin,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: gold.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                    const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(gold),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _steps[_step],
                  key: ValueKey(_step),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Running deep facial analysis",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white60,
                ),
              ),

              const SizedBox(height: 28),

              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AnimatedBuilder(
                  animation: _progressCtrl,
                  builder: (context, _) {
                    final value =
                        (_progress + _progressCtrl.value * 0.25)
                            .clamp(0.0, 1.0);

                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 7,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation(gold),
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
}