// 🔥 ANALYZE LOADING (FREE PSL) — ENTERPRISE UI + ORIGINAL LOGIC FIXED

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/features/analysis/screens/analysis_block.dart' as analysis;

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

  late final AnimationController _spin;
  late final AnimationController _pulse;
  late final AnimationController _fade;
  late final AnimationController _progressCtrl;

  late final Animation<double> _opacity;

  Timer? _stepTimer;
  int _step = 0;
  double _progress = 0.05;

  static const Color bg = Color(0xFF0B0E14);
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
      duration: const Duration(milliseconds: 420),
    );

    _opacity = CurvedAnimation(parent: _fade, curve: Curves.easeOut);
    _fade.forward();

    _stepTimer = Timer.periodic(
      const Duration(milliseconds: 850),
      (t) {
        if (!mounted) return;
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

    _startAnalysis();
  }
  void _handleError(SharedPreferences prefs, dynamic result) {
  final status = result?["status"];

  // 🔒 FORBIDDEN → fallback na cache
  if (status == "forbidden") {
    final cached = prefs.getString("welcome_psl");

    if (cached != null) {
      final psl = jsonDecode(cached) as Map<String, dynamic>;
      psl["is_cached"] = true;
      widget.onFinished(psl);
      return;
    }
  }

  // ❌ HARD FAIL
  widget.onError("face");
}

  // =========================================================
  // 🔥 BACKEND CALL (FIXED PAYLOAD)
  // =========================================================
  Future<void> _startAnalysis() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    // =========================
    // GUEST TOKEN (STABLE)
    // =========================
    final guestToken =
        prefs.getString("guest_token") ??
        "guest_${DateTime.now().millisecondsSinceEpoch}";

    await prefs.setString("guest_token", guestToken);

    // =========================
    // CALL BACKEND (FREE PSL)
    // =========================
    final result = await analysis.AnalysisBlock.runPslAnalysis(
      imageFile: widget.imageFile,
      guestToken: guestToken,
    ).timeout(const Duration(seconds: 18));

    if (!mounted) return;

    // =========================
    // SAFETY CHECK
    // =========================
    if (result == null || result["status"] != "success") {
      _handleError(prefs, result);
      return;
    }

    final psl = result["psl"];

    if (psl == null) {
      _handleError(prefs, result);
      return;
    }

    // =========================
    // SAFE FORMAT (NO CRASH UI)
    // =========================
    final safePsl = {
      "psl_score": (psl["psl_score"] is num)
          ? psl["psl_score"].toDouble()
          : 0.0,

      "strengths": (result["strengths"] is List)
          ? result["strengths"]
          : [],

      "limits": (result["limits"] is List)
          ? result["limits"]
          : [],
    };

    // =========================
    // CACHE (WELCOME FLOW)
    // =========================
    await prefs.setString("welcome_psl", jsonEncode(safePsl));

    // =========================
    // FINISH
    // =========================
    widget.onFinished(safePsl);

  } catch (e) {
    if (!mounted) return;
    widget.onError("analysis_failed");
  }
}

  @override
  void dispose() {
    _stepTimer?.cancel();
    _spin.dispose();
    _pulse.dispose();
    _fade.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  // =========================================================
  // 🔥 ENTERPRISE UI
  // =========================================================
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

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

              // 🔥 IMAGE GLOW
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  final glow = _pulse.value;

                  return Stack(
                    alignment: Alignment.center,
                    children: [

                      Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: gold.withOpacity(0.25 + glow * 0.25),
                              blurRadius: 60 + glow * 30,
                            ),
                            BoxShadow(
                              color: gold.withOpacity(0.15),
                              blurRadius: 120,
                            )
                          ],
                        ),
                      ),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.file(
                          widget.imageFile,
                          height: 220,
                          width: 220,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 44),

              // 🔥 SPINNER
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

              const SizedBox(height: 36),

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

              const SizedBox(height: 12),

              const Text(
                "Processing image securely",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white60,
                ),
              ),

              const SizedBox(height: 32),

              // 🔥 PROGRESS
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