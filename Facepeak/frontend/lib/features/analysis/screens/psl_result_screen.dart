import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// PSL RESULT SCREEN
/// Goals:
/// - Score number ALWAYS centered on screen
/// - FacePeak badge ALWAYS left of the score
/// - Strengths / Limits layout 1:1 (two columns)
/// - Always show exactly 6 metrics
/// - Fill logic based on PSL score (1-6):
///     - first N metrics are "blue filled"
///     - remaining are "red filled"
///     - if score == 6 -> everything blue (even on limits side)
/// - Tapping a metric opens bottom sheet with short description
class PSLResultScreen extends StatefulWidget {
  final Map<String, dynamic> psl;
  final File imageFile;
  final VoidCallback onContinue; // ✅ NOVO
const PSLResultScreen({
  super.key,
  required this.psl,
  required this.imageFile,
  required this.onContinue,
});

  @override
  State<PSLResultScreen> createState() => _PSLResultScreenState();
}

class _PSLResultScreenState extends State<PSLResultScreen>
    with TickerProviderStateMixin {
  // ===== THEME =====
  static const Color bg = Color(0xFF0B0E14);

  static const Color blue = Color(0xFF7FB6FF);
  static const Color red = Color(0xFFD36A6A);

  // Ring gradient extra stops (same vibe as your screenshots)
  static const Color gPurple = Color(0xFF9D7CFF);
  static const Color gOrange = Color(0xFFFF8A5B);

  late final AnimationController _ring;
    
  @override
  void initState() {
    super.initState();
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 36),
    )..repeat();
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  // ===== METRIC SCALE (the 6 things) =====
  // Order matters because fill logic uses first N = "best" (blue)
  static const List<String> _metricOrder = <String>[
    'appeal',
    'symmetry',
    'bone',
    'face_shape',
    'skin',
    'hair',
  ];

  // Pretty labels shown on UI
  static const Map<String, String> _metricTitles = <String, String>{
    'bone': 'Bone structure',
    'face_shape': 'Face shape',
    'symmetry': 'Symmetry',
    'appeal': 'Visual appeal',
    'skin': 'Skin quality',
    'hair': 'Hair framing',
  };

  // Fallback descriptions (1–2 sentences)
  // Backend can override via widget.psl['metric_cards'][key]
  static const Map<String, String> _fallbackDescs = <String, String>{
    'bone':
        'Jaw + cheekbone support and overall structural strength. Mostly genetic and very stable.',
    'face_shape':
        'Overall width-to-height balance and facial harmony from different angles. Stable baseline.',
    'symmetry':
        'Left-right alignment and proportional balance. Small asymmetries are normal.',
    'appeal':
        'How well the features work together visually. This is overall “look” cohesion.',
    'skin':
        'Texture and clarity of the skin. One of the most changeable traits over time.',
    'hair':
        'How hair frames the face (shape, volume, hairline styling). Styling matters a lot.',
  };

  // ===== SCORE STYLE =====
  Color _scoreTint(int score) {
    if (score <= 3) return red;
    if (score >= 5) return blue;
    return Colors.white;
  }

  int _readScore() {
    final raw = widget.psl['display_score'] ?? widget.psl['psl_score'] ?? 4;
    if (raw is num) return raw.clamp(1, 6).toInt();
    if (raw is String) {
      final n = int.tryParse(raw) ?? 4;
      return n.clamp(1, 6);
    }
    return 4;
  }

  // ===== BACKEND METRIC CARDS SUPPORT =====
  // Accept both:
  // - String
  // - { "title": "...", "desc": "..." }
  String _metricDesc(String key) {
    try {
      final cards = widget.psl['metric_cards'];
      if (cards is Map) {
        final v = cards[key];
        if (v is String && v.trim().isNotEmpty) return v.trim();
        if (v is Map && v['desc'] != null) {
          final d = v['desc'].toString().trim();
          if (d.isNotEmpty) return d;
        }
      }
    } catch (_) {
      // ignore
    }
    return _fallbackDescs[key] ?? 'No description.';
  }

  String _metricTitle(String key) {
    return _metricTitles[key] ?? key;
  }

  void _openMetricSheet(String key, Color accent) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // top grabber vibe
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 46,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              Text(
                _metricTitle(key),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withOpacity(0.95),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 48,
                height: 3,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _metricDesc(key),
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Colors.white.withOpacity(0.72),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===== METRIC BUILD =====
  // Blue filled vs Red filled cards (like your reference)
  Widget _metricCard({
    required String key,
    required bool isBlueFilled,
    required bool isRightColumn,
  }) {
    final label = _metricTitle(key);

    // Even when it’s on the Limits side, if score==6 or metric is within blueCount,
    // it becomes blue filled.
    final Color accent = isBlueFilled ? blue : red;

    return GestureDetector(
      onTap: () => _openMetricSheet(key, accent),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withOpacity(0.55), width: 1.2),
          color: accent.withOpacity(0.10),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.10),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.95),
          ),
        ),
      ),
    );
  }

  // ===== FACEPEAK + CENTER SCORE (THE FIX) =====
  // We use Stack so:
  // - number is Center() => true center of screen
  // - FacePeak badge is Positioned(left: ...) => always left
  Widget _scoreLine({
    required int score,
    required Color scoreColor,
  }) {
    // This width roughly matches the look in your screenshot.
    // Center stays center within this box; the whole box is centered on screen.
    const double boxWidth = 260;

    return SizedBox(
      width: boxWidth,
      height: 98,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered number (true center of the box)
          Center(
            child: Text(
              score.toString(),
              style: TextStyle(
                fontSize: 86,
                fontWeight: FontWeight.w900,
                color: scoreColor,
                height: 0.95,
              ),
            ),
          ),

          // FacePeak pinned to left inside same box
          Positioned(
            left: 0,
            top: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scoreColor.withOpacity(0.55)),
                color: Colors.white.withOpacity(0.04),
              ),
              child: Text(
                'FacePeak',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.70),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== MAIN BUILD =====
  @override
Widget build(BuildContext context) {
  final int score = _readScore();
  final Color tint = _scoreTint(score);

  final int blueCount = score.clamp(1, 6);
  final List<String> six = List<String>.from(_metricOrder);
  final List<String> leftThree = six.take(3).toList();
  final List<String> rightThree = six.skip(3).take(3).toList();

  final bool isCached = widget.psl['is_cached'] == true; // ⬅️ NOVO

  bool isBlueMetric(String key) {
    if (score >= 6) return true;
    final idx = six.indexOf(key);
    if (idx < 0) return false;
    return idx < blueCount;
  }

  return Scaffold(
    backgroundColor: bg,
    body: SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
              child: Align(
                alignment: Alignment.topRight,
                child: Text(
                  'PSL scale 1–6',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // IMAGE + RING
            Stack(
              alignment: Alignment.center,
              children: [
                ClipOval(
                  child: Image.file(
                    widget.imageFile,
                    width: 186,
                    height: 186,
                    fit: BoxFit.cover,
                  ),
                ),
                AnimatedBuilder(
                  animation: _ring,
                  builder: (context, _) {
                    return CustomPaint(
                      size: const Size(236, 236),
                      painter: _RingPainter(
                        rotation: _ring.value * 2 * math.pi,
                        main: tint,
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 18),

            Text(
              'PSL',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: Colors.white.withOpacity(0.70),
              ),
            ),

            const SizedBox(height: 10),

            _scoreLine(score: score, scoreColor: tint),

            // 🔴 INFO PORUKA (NOVO, SIGURNO MJESTO)
            if (isCached)
              Container(
                margin: const EdgeInsets.fromLTRB(18, 14, 18, 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.6)),
                ),
                child: const Text(
                  'This is the same result as before. Re-analyzing will not change the score.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
              ),

            const SizedBox(height: 26),

            // STRENGTHS / LIMITS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STRENGTHS',
                          style: TextStyle(
                            color: blue.withOpacity(0.95),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Top structural strengths',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.50),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (final k in leftThree)
                          _metricCard(
                            key: k,
                            isBlueFilled: isBlueMetric(k),
                            isRightColumn: false,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LIMITS',
                          style: TextStyle(
                            color: red.withOpacity(0.95),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Main structural limits',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.50),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (final k in rightThree)
                          _metricCard(
                            key: k,
                            isBlueFilled: isBlueMetric(k),
                            isRightColumn: true,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // CONTINUE BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: widget.onContinue,
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // FOOTER
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Structural analysis only. Not overall attractiveness.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.45),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}}

// ===== RING PAINTER =====
// Smooth ring with sweep gradient rotation
class _RingPainter extends CustomPainter {
  final double rotation;
  final Color main;

  _RingPainter({
    required this.rotation,
    required this.main,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        transform: GradientRotation(rotation),
        colors: <Color>[
          main,
          _PSLColors.purple,
          _PSLColors.orange,
          _PSLColors.blue,
          main,
        ],
      ).createShader(rect);

    // Outer ring
    canvas.drawOval(rect.deflate(6), paint);

    // Inner subtle ring (like reference depth)
    final Paint inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white.withOpacity(0.06);

    canvas.drawOval(rect.deflate(20), inner);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.rotation != rotation || oldDelegate.main != main;
  }
}

// Small palette helper so you can tweak in one place
class _PSLColors {
  static const Color blue = Color(0xFF7FB6FF);
  static const Color purple = Color(0xFF9D7CFF);
  static const Color orange = Color(0xFFFF8A5B);
}