// psl_result_screen.dart
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'psl_free_explanation_screen.dart';
class PSLResultScreen extends StatefulWidget {
  final Map<String, dynamic> psl; // safePayload OR whole response
  final ImageProvider image;      // FileImage(widget.imageFile)
  final VoidCallback onContinue;

  const PSLResultScreen({
    super.key,
    required this.psl,
    required this.image,
    required this.onContinue,
  });

  @override
  State<PSLResultScreen> createState() => _PSLResultScreenState();
}

class _PSLResultScreenState extends State<PSLResultScreen>
    with TickerProviderStateMixin {
  // ===== Core theme =====
  static const Color bg = Color(0xFF05070B);
  static const Color panel = Color(0xFF0F141C);
  static const Color panel2 = Color(0xFF0C1017);

  // Gold
  static const Color gold = Color(0xFFE7C26A);
  static const Color gold2 = Color(0xFFFFD37A);
  static const Color goldHot = Color(0xFFFFE3A2);

  static const Color textHi = Color(0xFFE9EEF6);
  static const Color textMid = Color(0xFFB9C2D0);
  static const Color textLo = Color(0xFF7D8796);

  // Only bars get gold fill; borders are neutral grey
  static const Color strokeGrey = Color(0x22FFFFFF);
  static const Color strokeGrey2 = Color(0x18FFFFFF);

  final GlobalKey _shareKey = GlobalKey();

  late final AnimationController _shareWiggle;
  late final Animation<double> _wiggle;

  late final AnimationController _ringSpin;
  late final AnimationController _glowPulse;
  late final AnimationController _intro;

  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  bool _sharing = false;

  @override
  void initState() {
    super.initState();

    _shareWiggle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _wiggle = Tween<double>(begin: -1.2, end: 1.2).animate(
      CurvedAnimation(parent: _shareWiggle, curve: Curves.easeInOut),
    );

    _ringSpin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 26),
    )..repeat();

    _glowPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _fadeIn = CurvedAnimation(parent: _intro, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic));

    _intro.forward();
  }

  @override
  void dispose() {
    _shareWiggle.dispose();
    _ringSpin.dispose();
    _glowPulse.dispose();
    _intro.dispose();
    super.dispose();
  }

  // ===== Payload parsing (keeps backend contract) =====
  Map<String, dynamic> get _pslObj {
    final p = widget.psl;
    if (p["psl"] is Map) return Map<String, dynamic>.from(p["psl"] as Map);
    if (p["psl_score"] != null) return Map<String, dynamic>.from(p);
    return {};
  }

  int get _score {
    final v = _pslObj["psl_score"];
    if (v is int) return v.clamp(1, 8);
    if (v is num) return v.round().clamp(1, 8);
    if (v is String) return (int.tryParse(v) ?? 3).clamp(1, 8);
    return 3;
  }

  String get _tier => (_pslObj["tier"] ?? "Average").toString();
  String get _percentile => (_pslObj["percentile"] ?? "—").toString();

  double get _confidence01 {
    final v = _pslObj["confidence"];
    if (v is num) {
      final d = v.toDouble();
      if (d > 1.0) return (d / 100.0).clamp(0.0, 1.0);
      return d.clamp(0.0, 1.0);
    }
    if (v is String) {
      final d = double.tryParse(v) ?? 0.50;
      if (d > 1.0) return (d / 100.0).clamp(0.0, 1.0);
      return d.clamp(0.0, 1.0);
    }
    return 0.50;
  }

  int get _confidencePct => (_confidence01 * 100).round().clamp(0, 100);

  // ===== Derived UI-only fields =====
  String get _pslLevelLabel {
    final score = _score;

    if (score >= 8) return "Closest to: Alain Delon";
    if (score >= 7) return "Closest to: Henry Cavill";
    if (score >= 6) return "Closest to: Francisco Lachowski";
    if (score >= 5) return "Closest to: Timothée Chalamet";
    if (score >= 4) return "Closest to: Tom Holland";
    if (score >= 3) return "Closest to: Daniel Radcliffe";
    if (score >= 2) return "Closest to: Ed Sheeran";
    return "Closest to: Danny DeVito";
}

  String get _modelRankLabel {
    final s = _score;
    if (s >= 8) return "Elite bracket";
    if (s >= 7) return "Top bracket";
    if (s >= 5) return "High bracket";
    if (s >= 3) return "Mid bracket";
    return "Developing";
  }

  String get _modelPotentialLabel {
    final s = _score;
    if (s >= 8) return "Max";
    if (s >= 7) return "Very high";
    if (s >= 6) return "High";
    if (s >= 5) return "Medium";
    if (s >= 3) return "Developing";
    return "Low";
  }

  // ===== Fills =====
  double get _scoreFill => (_score / 8.0).clamp(0.0, 1.0);
  double get _confFill => _confidence01.clamp(0.0, 1.0);

  double get _stabilityFill {
  final s = _score;

  if (s >= 8) return 0.95;
  if (s >= 7) return 0.90;
  if (s >= 6) return 0.82;
  if (s >= 5) return 0.70;
  if (s >= 4) return 0.58;
  if (s >= 3) return 0.45;
  if (s >= 2) return 0.32;
  return 0.22;
}

  double get _percentileFill {
    final s = _percentile.toLowerCase();
    if (s.contains("0.01")) return 1.0;
    if (s.contains("1%")) return 0.95;
    if (s.contains("5%")) return 0.85;
    if (s.contains("10%")) return 0.78;
    if (s.contains("30%")) return 0.60;
    if (s.contains("60%")) return 0.45;
    if (s.contains("bottom")) return 0.20;
    return _scoreFill;
  }

  double get _rankFill {
    final s = _score;
    if (s >= 8) return 1.0;
    if (s >= 7) return 0.92;
    if (s >= 6) return 0.85;
    if (s >= 5) return 0.78;
    if (s >= 4) return 0.62;
    if (s >= 3) return 0.50;
    if (s >= 2) return 0.35;
    return 0.22;
  }

  double get _potentialFill {
    switch (_modelPotentialLabel) {
      case "Max":
        return 1.0;
      case "Very high":
        return 0.92;
      case "High":
        return 0.82;
      case "Medium":
        return 0.65;
      case "Developing":
        return 0.45;
      default:
        return 0.25;
    }
  }

  Color get _goldFill {
    final t = ((_score - 1) / 7.0).clamp(0.0, 1.0);
    return Color.lerp(gold, goldHot, t) ?? gold;
  }

  // ===== Share capture =====
  Future<void> _shareResult() async {
    if (_sharing) return;
    setState(() => _sharing = true);

    try {
      HapticFeedback.mediumImpact();

      final boundary =
          _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      await Share.shareXFiles(
        [
          XFile.fromData(
            pngBytes,
            mimeType: "image/png",
            name: "facepeak_psl.png",
          )
        ],
        text: "FacePeak PSL result",
      );
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  // ===== Typography =====
  TextStyle _tierStyle() => TextStyle(
        fontSize: 24,
        height: 1.0,
        fontWeight: FontWeight.w900,
        color: textHi,
        letterSpacing: 1.6,
        shadows: [
          Shadow(color: Colors.black.withOpacity(0.75), blurRadius: 20),
          Shadow(color: _goldFill.withOpacity(0.45), blurRadius: 35),
        ],
      );

  TextStyle _labelStyle() => TextStyle(
        fontSize: 10.8,
        letterSpacing: 1.0,
        fontWeight: FontWeight.w900,
        color: Colors.white.withOpacity(0.48),
      );

  TextStyle _valueStyle() => TextStyle(
        fontSize: 16.2,
        height: 1.1,
        fontWeight: FontWeight.w900,
        color: textHi,
        shadows: [
          Shadow(color: Colors.black.withOpacity(0.35), blurRadius: 10),
        ],
      );

  // ===== UCHAD-style search pill (WHITE) + REAL Google Play logo =====
  

  Color _goldStatic(double opacity) => gold.withOpacity(opacity);

  // ===== HERO avatar ring (responsive) =====
  Widget _avatarRing() {
  final screenW = MediaQuery.of(context).size.width;

  // veći krug ali da ne dira rubove
  final size = (screenW * 0.80).clamp(280.0, 380.0);

  return AnimatedBuilder(
    animation: _glowPulse,
    builder: (context, _) {
      final pulse = _glowPulse.value;

      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [

              // soft aura
              Container(
                width: size * 1.18,
                height: size * 1.18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _goldFill.withOpacity(0.14 + pulse * 0.05),
                      blurRadius: 140,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),

              // image
              ClipOval(
                child: Image(
                  image: widget.image,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
  // ===== Progress bar (ONLY fill is gold) =====
  Widget _progressBar(double fill) {
    final f = fill.clamp(0.0, 1.0);
    return Container(
      height: 7,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0D12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: strokeGrey2, width: 1),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: f,
          child: AnimatedBuilder(
            animation: _glowPulse,
            builder: (context, _) {
              final p = _glowPulse.value;
              return Container(
                decoration: BoxDecoration(
                  color: _goldFill.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: _goldFill.withOpacity(0.28 + p * 0.12),
                      blurRadius: 18 + p * 8,
                      spreadRadius: 0.2,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _cell({
    required String label,
    required String value,
    required double fill,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0F16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: strokeGrey, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: _labelStyle()),
            const SizedBox(height: 8),
            Text(value, style: _valueStyle()),
            const SizedBox(height: 10),
            _progressBar(fill),
          ],
        ),
      ),
    );
  }
  Widget _pslHeader() {
  return SizedBox(
    width: double.infinity,
    height: 72, // 🔧 povećano da nema overflowa
    child: Stack(
      alignment: Alignment.center,
      children: [

        // CENTER COLUMN
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _tier.toUpperCase(),
              style: GoogleFonts.orbitron(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: textHi,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              "PSL scale",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
                color: textMid,
              ),
            ),
          ],
        ),

        // FACEPEAK BADGE
        Positioned(
          left: MediaQuery.of(context).size.width / 2 - 150,
          top: 45, // 🔧 spušten malo
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0F16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _goldFill.withOpacity(0.35),
                width: 1,
              ),
            ),
            child: Text(
              "FacePeak",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _goldFill,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
  Widget _table6() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: panel2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _goldStatic(0.70), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.60),
            blurRadius: 20,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: _goldFill.withOpacity(0.08),
            blurRadius: 28,
            spreadRadius: 0.2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _cell(label: "Score", value: "${_score} / 8", fill: _scoreFill),
              const SizedBox(width: 12),
              _cell(label: "Confidence", value: "${_confidencePct}%", fill: _confFill),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _cell(label: "Percentile", value: _percentile, fill: _percentileFill),
              const SizedBox(width: 12),
              _cell(label: "Stability", value: _pslLevelLabel, fill: _stabilityFill),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _cell(label: "Model Rank", value: _modelRankLabel, fill: _rankFill),
              const SizedBox(width: 12),
              _cell(label: "Model Potential", value: _modelPotentialLabel, fill: _potentialFill),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniExplainRow({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: strokeGrey, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _glowPulse,
            builder: (context, _) {
              final p = _glowPulse.value;
              return Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _goldFill.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _goldFill.withOpacity(0.25 + p * 0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: _goldFill.withOpacity(0.12 + p * 0.06),
                      blurRadius: 16 + p * 6,
                    ),
                  ],
                ),
                child: Icon(icon, color: _goldFill.withOpacity(0.95), size: 18),
              );
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.6,
                    fontWeight: FontWeight.w900,
                    color: textHi,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11.6,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== Share button (fixed syntax + brutal glow) =====
  Widget _shareButton() {
  return AnimatedBuilder(
    animation: Listenable.merge([_wiggle, _glowPulse]),
    builder: (context, _) {
      final p = _glowPulse.value;

      return Transform.translate(
        offset: Offset(_wiggle.value * 1.4, 0),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _goldFill.withOpacity(0.65 + p * 0.25),
                blurRadius: 55 + p * 25,
                spreadRadius: 3,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: _goldFill,
              backgroundColor: Colors.transparent, // 🔥 nema pozadine
              side: BorderSide(
                color: _goldFill.withOpacity(0.85),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
            onPressed: _sharing ? null : _shareResult,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: _goldFill.withOpacity(0.95),
                ),
                const SizedBox(width: 12),
                Text(
                  _sharing ? "Preparing…" : "SHARE RESULT",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
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

  Widget _continueButton() {
  return SizedBox(
    width: double.infinity,
    height: 56,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: gold2,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      onPressed: () {
        HapticFeedback.selectionClick();

        Navigator.of(context).push(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 380),
            reverseTransitionDuration: const Duration(milliseconds: 260),
            pageBuilder: (context, animation, _) {
              return FadeTransition(
                opacity: animation,
                child: PslExplanationScreen(
                  onContinue: widget.onContinue,
                ),
              );
            },
          ),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "CONTINUE",
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: Colors.black.withOpacity(0.85),
          ),
        ],
      ),
    ),
  );
}

  @override
Widget build(BuildContext context) {
  final status = (widget.psl["status"] ?? "success").toString();
  final isOk = status == "success" && _pslObj.isNotEmpty;

  return Scaffold(
    backgroundColor: bg,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideIn,
                    child: Column(
                      children: [

                        // ===== SHARE AREA START =====
                        RepaintBoundary(
                          key: _shareKey,
                          child: Container(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              children: [

                                const SizedBox(height: 16),

                                _avatarRing(),

                                const SizedBox(height: 16),

                                // 🔥 FacePeak header (JawMax style)
                                _pslHeader(),

                                const SizedBox(height: 16),

                                _table6(),
                              ],
                            ),
                          ),
                        ),
                        // ===== SHARE AREA END =====

                        const SizedBox(height: 14),

                        _miniExplainRow(
                          icon: Icons.psychology_alt_rounded,
                          title: "Score",
                          desc: "Your structural rank in the 8-tier model.",
                        ),

                        const SizedBox(height: 10),

                        _miniExplainRow(
                          icon: Icons.check_circle_outline_rounded,
                          title: "Confidence",
                          desc: "How sure the ML model is about this result.",
                        ),

                        const SizedBox(height: 10),

                        _miniExplainRow(
                          icon: Icons.emoji_events_outlined,
                          title: "Percentile",
                          desc: "Where you stand vs other analyzed faces.",
                        ),

                        const SizedBox(height: 10),

                        _miniExplainRow(
                          icon: Icons.insights_rounded,
                          title: "Stability",
                          desc: "How consistent the result is across inputs.",
                        ),

                        const SizedBox(height: 10),

                        _miniExplainRow(
                          icon: Icons.workspace_premium_rounded,
                          title: "Model Rank",
                          desc: "Bracket derived from score (not a new tier).",
                        ),

                        const SizedBox(height: 10),

                        _miniExplainRow(
                          icon: Icons.track_changes_rounded,
                          title: "Model Potential",
                          desc: "Structure-based potential (not styling).",
                        ),

                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            _shareButton(),

            const SizedBox(height: 12),

            _continueButton(),

            const SizedBox(height: 10),

            Text(
              "🔒 Photos are processed securely and deleted after analysis.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.50),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}}

