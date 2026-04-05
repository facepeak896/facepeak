import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/features/analysis/screens/analysis_block.dart' as analysis;

import 'psl_result_premium_screen.dart';

class AnalyzePslLoadingScreen extends StatefulWidget {
  final File imageFile;
  final void Function(Map<String, dynamic> psl) onFinished;
  final void Function(String message) onError;
  final String guestToken;

  const AnalyzePslLoadingScreen({
    super.key,
    required this.imageFile,
    required this.onFinished,
    required this.onError,
    required this.guestToken,
  });

  @override
  State<AnalyzePslLoadingScreen> createState() => _AnalyzeLoadingScreenState();
}

class _AnalyzeLoadingScreenState extends State<AnalyzePslLoadingScreen>
    with TickerProviderStateMixin {

  late final AnimationController _spin;
  late final AnimationController _fade;
  late final Animation<double> _opacity;

  Timer? _stepTimer;

  int _step = 0;
  bool _navigated = false;

  static const Color bgTop = Color(0xFF12121A);
  static const Color bgMid = Color(0xFF0E0E14);
  static const Color bgBottom = Color(0xFF0B0B0F);
  static const Color gold = Color(0xFFF5C518);

  static const List<String> _steps = [
    'Reading facial landmarks',
    'Analyzing structure & symmetry',
    'Calculating proportions',
    'Preparing results',
  ];

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _opacity = CurvedAnimation(
      parent: _fade,
      curve: Curves.easeOut,
    );

    _fade.forward();

    _stepTimer = Timer.periodic(
      const Duration(milliseconds: 850),
      (t) {
        if (!mounted) return;

        if (_step < _steps.length - 1) {
          setState(() {
            _step++;
          });
        } else {
          t.cancel();
        }
      },
    );

    _startAnalysis();
  }

  // =========================================================
  // SAFE ANALYSIS CALL
  // =========================================================

  Future<void> _startAnalysis() async {
    try {
      print("🔥 STARTING PSL ANALYSIS");

      final result = await analysis.AnalysisBlock.runPslAnalysis(
        imageFile: widget.imageFile,
        guestToken: widget.guestToken,
      );

      if (!mounted || _navigated) return;

      print("🔥 BACKEND RESULT: $result");

      if (result["status"] != "success") {
        widget.onError("analysis_failed");
        return;
      }

      final psl = result["psl"];
      if (psl == null) {
        widget.onError("invalid_psl_payload");
        return;
      }

      final int score = psl["psl_score"] ?? 0;
      final String tier = psl["tier"] ?? "";
      final String percentile = psl["percentile"] ?? "";
      final double confidence =
          (psl["confidence"] is num) ? psl["confidence"].toDouble() : 0.0;

      final safePayload = {
        "psl_score": score,
        "tier": tier,
        "percentile": percentile,
        "confidence": confidence,
      };

      _navigated = true;

      _stepTimer?.cancel();

      print("🔥 NAVIGATING TO RESULT SCREEN");

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PSLResultScreen(
            psl: safePayload,
            image: FileImage(widget.imageFile),
            onContinue: () {
              Navigator.pop(context);
            },
          ),
        ),
      );
    } catch (e, stack) {
      print("❌ PSL ERROR: $e");
      print(stack);

      if (!mounted) return;

      widget.onError("analysis_failed");
    }
  }

  // =========================================================
  // DISPOSE (CRITICAL FOR STABILITY)
  // =========================================================

  @override
  void dispose() {
    _stepTimer?.cancel();
    _spin.dispose();
    _fade.dispose();
    super.dispose();
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [bgTop, bgMid, bgBottom],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.025,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: 0.6,
                        sigmaY: 0.6,
                      ),
                      child: Container(color: Colors.white),
                    ),
                  ),
                ),
              ),
              Padding(
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
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: gold.withOpacity(0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(gold),
                            ),
                            RotationTransition(
                              turns: _spin,
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: gold.withOpacity(0.35),
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        child: Text(
                          _steps[_step],
                          key: ValueKey(_step),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Processing image securely',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0x99FFFFFF),
                        ),
                      ),
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