import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_free_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
/// PSL RESULT SCREEN
/// Goals:
/// - Score number ALWAYS centered on screen
/// - FacePeak badge ALWAYS left of the score
/// - Strengths / Limits layout 1:1 (two columns)
/// - Always show exactly 6 metrics
/// - Fill logic based on PSL score (1-8)
/// - Tapping a metric opens bottom sheet with short description
class PSLLResultScreen extends StatefulWidget {
  final Map<String, dynamic> psl;
  final File imageFile;
  final VoidCallback onContinue;
  

  const PSLLResultScreen({
    super.key,
    required this.psl,
    required this.imageFile,
    required this.onContinue,
  });

  @override
  State<PSLLResultScreen> createState() => _PSLResultScreenState();
}

class _PSLResultScreenState extends State<PSLLResultScreen>
    with TickerProviderStateMixin {

  /// Screenshot capture key
  final GlobalKey _captureKey = GlobalKey();

  static const Color bg = Color(0xFF0B0E14);
  static const Color blue = Color(0xFF7FB6FF);
  static const Color red = Color(0xFFD36A6A);

  static const Color gPurple = Color(0xFF9D7CFF);
  static const Color gOrange = Color(0xFFFF8A5B);

  /// Rotating ring animation
  late final AnimationController _ring;

  /// Floating share button animation
  late final AnimationController _shareFloat;
  late final Animation<double> _shareOffset;

  @override
  void initState() {
    super.initState();

    /// Ring rotation
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 36),
    )..repeat();

    /// Share button floating animation
    _shareFloat = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _shareOffset = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(
      CurvedAnimation(
        parent: _shareFloat,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _ring.dispose();
    _shareFloat.dispose();
    super.dispose();
  }
  Future<void> _shareResult() async {
  try {
    final boundary =
        _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ImageByteFormat.png);

    final bytes = byteData!.buffer.asUint8List();

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/psl_share.png');

    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: "This is my PSL score on FacePeak. Can you beat it 👀?",
    );
  } catch (e) {
    print(e);
  }
}

  Color _scoreTint(int score) {
    if (score <= 3) return red;
    if (score >= 5) return blue;
    return Colors.white;
  }
  String _pslTier(int score) {
  switch (score) {
    case 1:
      return "Fragile";
    case 2:
      return "Limited";
    case 3:
      return "Developing";
    case 4:
      return "Balanced";
    case 5:
      return "Strong";
    case 6:
      return "Advanced";
    case 7:
      return "Elite";
    case 8:
      return "Near Impossible";
    default:
      return "";
  }
}

  int _readScore() {
  final raw =
      widget.psl['display_score'] ??
      widget.psl['psl_score'] ??
      widget.psl['psl']?['psl_score'] ??
      4;

  if (raw is num) {
    return raw.clamp(1, 8).toInt();
  }

  if (raw is String) {
    final n = int.tryParse(raw) ?? 4;
    return n.clamp(1, 8);
  }

  return 4;
}

  String _metricDesc(String key) {
  try {

    final Map data = widget.psl['result'] ?? widget.psl;
    final cards = data['metric_cards'];

    if (cards is Map) {
      final v = cards[key];

      if (v is String && v.trim().isNotEmpty) {
        return v.trim();
      }

      if (v is Map && v['desc'] != null) {
        final d = v['desc'].toString().trim();
        if (d.isNotEmpty) return d;
      }
    }

  } catch (_) {}

  return "This facial feature influences overall structure and visual balance.";
}

  String _metricTitle(String key) {
    return key.toString();
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

  Widget _metricCard({
    required String key,
    required bool isBlueFilled,
    required bool isRightColumn,
  }) {

    final label = _metricTitle(key);
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

  Widget _scoreLine({
    required int score,
    required Color scoreColor,
  }) {

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
                color: scoreColor,
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

  @override
Widget build(BuildContext context) {

  final Map data = widget.psl['result'] ?? widget.psl;

  final int rawScore = _readScore();
  final int score = rawScore.clamp(1, 8);
  final Color tint = _scoreTint(score);

  final int blueCount = score;

  final List strengths = List.from(data['strengths'] ?? []);
  final List limits = List.from(data['limits'] ?? []);

  final List<String> metrics = [];

  for (final s in strengths) {
    metrics.add(s.toString());
  }

  for (final l in limits) {
    metrics.add(l.toString());
  }

  while (metrics.length < 6) {
    metrics.add("—");
  }

  if (metrics.length > 6) {
    metrics.removeRange(6, metrics.length);
  }

  final List<String> leftThree = metrics.take(3).toList();
  final List<String> rightThree = metrics.skip(3).take(3).toList();

  bool isBlueMetric(int index) {
    return index < blueCount;
  }

  return Scaffold(
    backgroundColor: const Color(0xFF0B0E14),
    body: SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [

            /// CAPTURE AREA
            RepaintBoundary(
              key: _captureKey,
              child: Container(
                color: const Color(0xFF0B0E14),
                child: Column(
                  children: [

                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Text(
                          'PSL scale 1–8',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.55),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

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

                    SizedBox(
                      width: 260,
                      height: 110,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [

                          Text(
                            score.toString(),
                            style: TextStyle(
                              fontSize: 104,
                              fontWeight: FontWeight.w900,
                              color: tint,
                              height: 0.9,
                            ),
                          ),

                          Positioned(
                            left: 0,
                            top: 36,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: tint.withOpacity(0.55)),
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
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _pslTier(score),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "Can your friends beat this? 👀",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),

                    const SizedBox(height: 26),

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

                                for (int i = 0; i < leftThree.length; i++)
                                  _metricCard(
                                    key: leftThree[i],
                                    isBlueFilled: isBlueMetric(i),
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

                                for (int i = 0; i < rightThree.length; i++)
                                  _metricCard(
                                    key: rightThree[i],
                                    isBlueFilled: isBlueMetric(i + 3),
                                    isRightColumn: true,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),
                  ],
                ),
              ),
            ),

            /// SHARE BUTTON
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: AnimatedBuilder(
                animation: _shareFloat,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _shareOffset.value),
                    child: child,
                  );
                },
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _shareResult();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withOpacity(0.9),
                          Colors.purple.withOpacity(0.9),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        "Share My Score",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// CONTINUE
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
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const HomeFreeScreen(),
                      ),
                    );
                  },
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

          ],
        ),
      ),
    ),
  );
}}
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

    canvas.drawOval(rect.deflate(6), paint);

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

class _PSLColors {
  static const Color blue = Color(0xFF7FB6FF);
  static const Color purple = Color(0xFF9D7CFF);
  static const Color orange = Color(0xFFFF8A5B);
}