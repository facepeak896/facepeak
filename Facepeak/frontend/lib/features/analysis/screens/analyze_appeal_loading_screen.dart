import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/features/analysis/screens/analysis_block.dart'
    as analysis;
import 'appeal_result_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyzeAppealLoadingScreen extends StatefulWidget {
  final File imageFile;
  final void Function(Map<String, dynamic> appeal) onFinished;
  final void Function(String message) onError;

  const AnalyzeAppealLoadingScreen({
    super.key,
    required this.imageFile,
    required this.onFinished,
    required this.onError,
  });

  @override
  State<AnalyzeAppealLoadingScreen> createState() =>
      _AnalyzeAppealLoadingScreenState();
}

class _AnalyzeAppealLoadingScreenState extends State<AnalyzeAppealLoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _spin;
  late final AnimationController _fade;
  late final Animation<double> _opacity;

  Timer? _stepTimer;
  int _step = 0;

  bool _isRunning = false; // ✅ FIX #1

  static const Color bgTop = Color(0xFF12121A);
  static const Color bgMid = Color(0xFF0E0E14);
  static const Color bgBottom = Color(0xFF0B0B0F);
  static const Color gold = Color(0xFFF5C518);

  static const List<String> _steps = [
    'Reading facial balance',
    'Evaluating symmetry & harmony',
    'Estimating first impression',
    'Preparing appeal score',
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
        setState(() => _step++);
      } else {
        t.cancel();
      }
    },
  );

  // ✅ JEDINO ISPRAVNO MJESTO
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    _startAppealAnalysis();
  });
}
  // =========================================================
  // BACKEND CALL (APPEAL)
  // =========================================================
  Future<void> _startAppealAnalysis() async {
  if (_isRunning) return;
  _isRunning = true;

  print('');
  print('🚀 APPEAL ANALYSIS START');
  print('📸 imagePath = ${widget.imageFile.path}');

  try {
    final prefs = await SharedPreferences.getInstance();

    final guestToken =
        prefs.getString("guest_token") ??
        "guest_${DateTime.now().millisecondsSinceEpoch}";

    await prefs.setString("guest_token", guestToken);

    print('🔥 guestToken = $guestToken');
    print('📡 CALL BACKEND → runAppealAnalysis');

    final result = await analysis.AnalysisBlock.runAppealAnalysis(
      imageFile: widget.imageFile,
      guestToken: guestToken,
    ).timeout(const Duration(seconds: 20));

    print('💥 BACKEND RESPONSE → $result');

    if (!mounted) return;

    if (result["status"] != "success") {
      print('❌ ANALYSIS FAILED → status=${result["status"]}');
      _isRunning = false;

      Navigator.pop(context, false); // ⬅️ vrati Home-u FAIL
      return;
    }

    final appeal = result["appeal"];

    if (appeal is! Map<String, dynamic>) {
      print('🚨 INVALID APPEAL TYPE → ${appeal.runtimeType}');
      _isRunning = false;

      Navigator.pop(context, false);
      return;
    }

    print('✅ APPEAL SUCCESS');
    print('➡️ PUSH RESULT SCREEN');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AppealResultScreen(
          appeal: appeal,
          imageFile: widget.imageFile,
        ),
      ),
    );

    _isRunning = false;
  }

  // ⏱️ TIMEOUT
  on TimeoutException {
    print('⏱️ TIMEOUT');
    _isRunning = false;

    if (mounted) {
      Navigator.pop(context, false);
    }
  }

  // 💥 EXCEPTION
  catch (e, st) {
    print('💣 EXCEPTION');
    print('ERROR → $e');
    print('STACKTRACE ↓');
    print(st);

    _isRunning = false;

    if (mounted) {
      Navigator.pop(context, false);
    }
  }
}
  @override
  void dispose() {
    _stepTimer?.cancel();
    _spin.dispose();
    _fade.dispose();
    super.dispose();
  }

  // =========================================================
  // UI (UNCHANGED)
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
                      imageFilter:
                          ImageFilter.blur(sigmaX: 0.6, sigmaY: 0.6),
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
                        'Analyzing visual appeal',
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