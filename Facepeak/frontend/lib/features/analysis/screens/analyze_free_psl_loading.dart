import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/features/analysis/screens/analysis_block.dart'
    as analysis;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'psl_free_result_screen.dart';

enum AnalysisErrorType {
  imageMissing,
  imageEmpty,
  imageTooLarge,
  invalidResponseType,
  emptyResponse,
  invalidStatus,
  invalidPslPayload,
  missingOrInvalidScore,
  analysisFailed,
  faceNotDetected,
  invalidContext,
  routeNotCurrent,
  navigationFailed,
  unexpected,
}

class AnalysisException implements Exception {
  final AnalysisErrorType type;
  final String? detail;

  const AnalysisException(this.type, {this.detail});

  @override
  String toString() => 'AnalysisException(type: $type, detail: $detail)';
}

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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _analysisRunning = false;
  bool _navigated = false;
  int _analysisRequestId = 0;

  late final AnimationController _spin;
  late final AnimationController _fade;
  late final Animation<double> _opacity;

  Timer? _stepTimer;
  int _step = 0;

  AppLifecycleState? _lastLifecycleState;

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

  bool get _isAppActive {
    final state = _lastLifecycleState;
    return state == null ||
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _lastLifecycleState = WidgetsBinding.instance.lifecycleState;

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

    _stepTimer = Timer.periodic(const Duration(milliseconds: 850), (t) {
      if (!mounted) return;

      if (_step < _steps.length - 1) {
        setState(() {
          _step++;
        });
      } else {
        t.cancel();
        _stepTimer = null;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startAnalysis();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lastLifecycleState = state;

    if (state == AppLifecycleState.detached) {
      _analysisRequestId++;
      _stopStepTimer();
    }
  }

  @override
  void dispose() {
    _analysisRequestId++;
    _stopStepTimer();
    WidgetsBinding.instance.removeObserver(this);
    _spin.dispose();
    _fade.dispose();
    super.dispose();
  }

  void _stopStepTimer() {
    _stepTimer?.cancel();
    _stepTimer = null;
  }

  Future<void> _popSafely() async {
    if (!mounted) return;

    try {
      final navigator = Navigator.of(context);
      final route = ModalRoute.of(context);
      final isCurrent = route?.isCurrent ?? false;

      if (navigator.canPop() && isCurrent) {
        navigator.pop();
      }
    } catch (e) {
      debugPrint('popSafely error: $e');
    }
  }

  bool _isValidString(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  int? _parseScore(dynamic raw) {
    if (raw is int) {
      return raw.clamp(1, 8).toInt();
    }

    if (raw is double) {
      if (raw.isNaN || raw.isInfinite) return null;
      return raw.round().clamp(1, 8).toInt();
    }

    if (raw is String) {
      final value = raw.trim();
      if (value.isEmpty) return null;

      final parsedInt = int.tryParse(value);
      if (parsedInt != null) {
        return parsedInt.clamp(1, 8).toInt();
      }

      final parsedDouble = double.tryParse(value);
      if (parsedDouble != null &&
          !parsedDouble.isNaN &&
          !parsedDouble.isInfinite) {
        return parsedDouble.round().clamp(1, 8).toInt();
      }
    }

    return null;
  }

  List<String> _sanitizeStringList(dynamic raw) {
    if (raw is! List) return const <String>[];

    final Set<String> seen = <String>{};
    final List<String> out = <String>[];

    for (final item in raw.take(20)) {
      String value = '';

      try {
        value = item?.toString().trim() ?? '';
      } catch (_) {
        value = '';
      }

      if (value.isEmpty) continue;

      final normalized = value.toLowerCase();
      if (!seen.add(normalized)) continue;

      out.add(value);
      if (out.length >= 10) break;
    }

    return out;
  }

  Map<String, dynamic> _buildTrustedPsl({
    required int score,
    required List<String> strengths,
    required List<String> limits,
  }) {
    return <String, dynamic>{
      'psl_score': score,
      'strengths': strengths,
      'limits': limits,
      'is_cached': false,
    };
  }

  String _mapErrorToCallbackMessage(AnalysisErrorType type) {
    switch (type) {
      case AnalysisErrorType.imageMissing:
      case AnalysisErrorType.imageEmpty:
      case AnalysisErrorType.imageTooLarge:
      case AnalysisErrorType.faceNotDetected:
      case AnalysisErrorType.invalidPslPayload:
      case AnalysisErrorType.missingOrInvalidScore:
      case AnalysisErrorType.invalidResponseType:
      case AnalysisErrorType.emptyResponse:
      case AnalysisErrorType.invalidStatus:
      case AnalysisErrorType.analysisFailed:
        return 'invalid_image';

      case AnalysisErrorType.invalidContext:
      case AnalysisErrorType.routeNotCurrent:
      case AnalysisErrorType.navigationFailed:
      case AnalysisErrorType.unexpected:
        return 'network';
    }
  }

  Future<void> _safeCallOnFinished(Map<String, dynamic> psl) async {
    try {
      widget.onFinished(psl);
    } catch (e, stack) {
      debugPrint('onFinished callback failed: $e');
      debugPrint(stack.toString());
    }
  }

  Future<void> _safeCallOnError(String message) async {
    try {
      widget.onError(message);
    } catch (e, stack) {
      debugPrint('onError callback failed: $e');
      debugPrint(stack.toString());
    }
  }

  // =========================================================
  // BACKEND CALL
  // =========================================================
  Future<void> _startAnalysis() async {
  if (!mounted || _analysisRunning || _navigated) return;

  /// 🔒 HARD LOCK – sprječava duple API requeste
  _analysisRunning = true;

  if (mounted) {
    setState(() {});
  }

  final int requestId = ++_analysisRequestId;
  final Stopwatch stopwatch = Stopwatch()..start();

  SharedPreferences? prefs;

  bool isRequestStale() {
    return !mounted ||
        _navigated ||
        requestId != _analysisRequestId;
  }

  bool isRouteCurrent() {
    if (!mounted) return false;
    final route = ModalRoute.of(context);
    return route?.isCurrent ?? false;
  }

  Future<void> exitWithMessage(String message) async {
    _stopStepTimer();

    if (!mounted) return;

    await _popSafely();

    await Future.delayed(const Duration(milliseconds: 80));

    widget.onError(message);
  }

  try {

    if (isRequestStale()) return;

    if (!isRouteCurrent()) {
      await exitWithMessage("network");
      return;
    }

    /// FILE VALIDATION
    int fileLength;

    try {
      fileLength = await widget.imageFile.length().timeout(
        const Duration(seconds: 2),
      );
    } catch (_) {
      await exitWithMessage("invalid_image");
      return;
    }

    if (fileLength <= 0) {
      await exitWithMessage("invalid_image");
      return;
    }

    if (fileLength > 10 * 1024 * 1024) {
      await exitWithMessage("invalid_image");
      return;
    }

    if (isRequestStale()) return;

    /// PREFS
    try {
      prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 2),
      );
    } catch (_) {}

    /// TOKEN
    String? guestToken = prefs?.getString('guest_token');

    if (guestToken == null || guestToken.trim().length < 8) {
      guestToken = const Uuid().v4();

      try {
        await prefs?.setString('guest_token', guestToken);
      } catch (_) {}
    }

    if (isRequestStale()) return;

    /// API CALL
    final dynamic resultDynamic =
        await analysis.AnalysisBlock.runFreePslAnalysis(
      imageFile: widget.imageFile,
      guestToken: guestToken,
    ).timeout(const Duration(seconds: 25));

    /// request više nije aktualan
    if (isRequestStale()) return;

    /// rezultat nije map
    if (resultDynamic is! Map<String, dynamic>) {
      await exitWithMessage("invalid_image");
      return;
    }

    final result = resultDynamic;

    if (result["status"] != "success") {
      await exitWithMessage("invalid_image");
      return;
    }

    final rawPsl = result["psl"];

    if (rawPsl == null || rawPsl is! Map) {
      await exitWithMessage("invalid_image");
      return;
    }

    final Map<String, dynamic> psl = Map<String, dynamic>.from(rawPsl);

    final int? parsedScore = _parseScore(psl["psl_score"]);

    if (parsedScore == null) {
      await exitWithMessage("invalid_image");
      return;
    }

    final strengths = _sanitizeStringList(result["strengths"]);
    final limits = _sanitizeStringList(result["limits"]);

    final safeStrengths =
        strengths.isEmpty && limits.isEmpty ? ["facial structure"] : strengths;

    /// 🔧 BACKEND DATA PROPAGATION
    final trustedPsl = {
      "psl_score": parsedScore,
      "strengths": safeStrengths,
      "limits": limits,
      "metric_cards": result["metric_cards"] ?? psl["metric_cards"] ?? {},
      "is_cached": false,
    };

    /// CACHE
    try {
      final encoded = jsonEncode(trustedPsl);
      await prefs?.setString("welcome_psl", encoded);
    } catch (_) {}

    stopwatch.stop();

    final elapsed = stopwatch.elapsed;

    /// MINIMUM LOADING UX
    if (elapsed < const Duration(seconds: 2)) {
      await Future.delayed(const Duration(seconds: 2) - elapsed);
    }

    if (isRequestStale()) return;

    if (!isRouteCurrent()) {
      await exitWithMessage("network");
      return;
    }

    if (_navigated) return;

    _navigated = true;
    _stopStepTimer();

    /// CALLBACK
    try {
      widget.onFinished(trustedPsl);
    } catch (_) {}

    /// NAVIGATION SAFETY
    if (!mounted) return;

    try {
      final navigator = Navigator.of(context);

      await navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => PSLLResultScreen(
            psl: trustedPsl,
            imageFile: widget.imageFile,
            onContinue: () {},
          ),
        ),
      );
    } catch (_) {
      await exitWithMessage("network");
    }
  }

  on SocketException {
    await exitWithMessage("network");
  }

  on TimeoutException {
    await exitWithMessage("network");
  }

  catch (_) {
    await exitWithMessage("invalid_image");
  }

  finally {
    stopwatch.stop();
    _stopStepTimer();

    if (requestId == _analysisRequestId) {
      if (mounted) {
        setState(() {
          _analysisRunning = false;
        });
      } else {
        _analysisRunning = false;
      }
    }
  }
}

  // =========================================================
  // UI (NE DIRATI)
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
                              valueColor: AlwaysStoppedAnimation<Color>(gold),
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