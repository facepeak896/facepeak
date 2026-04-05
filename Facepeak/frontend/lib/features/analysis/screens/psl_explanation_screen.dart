import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


// ✅ CHANGE THIS PATH to where your HomeScreen lives.
// If you don't have it yet, create a simple placeholder HomeScreen file.


/// PSL EXPLANATION SCREEN (Post-result)
/// Goals:
/// - Same dark vibe as the rest of the app (FacePeak style)
/// - Gold accent (premium / calm / trusted)
/// - User-friendly language (NOT AI-ish)
/// - Explains:
///   1) What PSL actually measures (mostly structure/bones)
///   2) Why heavier / higher body-fat users can still get a decent PSL
///   3) Why Appeal is different + when to use it
///   4) How to get more accurate results (neutral photo tips)
/// - Micro animations: subtle fade/slide + pulsing accent
/// - Continue -> saves "psl_explained" and goes Home
class PslExplanationScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const PslExplanationScreen({
    super.key,
    required this.onContinue,
  });

  @override
  State<PslExplanationScreen> createState() => _PslExplanationScreenState();
}

class _PslExplanationScreenState extends State<PslExplanationScreen>
    with TickerProviderStateMixin {
  // ===== THEME =====
  static const Color bg = Color(0xFF0B0E14);
  static const Color panel = Color(0xFF0F141C);
  static const Color panel2 = Color(0xFF101824);

  // Gold accents (calm, premium)
  static const Color gold = Color(0xFFE7C26A);
  static const Color gold2 = Color(0xFFFFD37A);

  // Subtle neutrals
  static const Color textHi = Color(0xFFE9EEF6);
  static const Color textMid = Color(0xFFB9C2D0);
  static const Color textLo = Color(0xFF7D8796);

  // Micro animation controllers
  late final AnimationController _intro;
  late final AnimationController _pulse;
  late final AnimationController _ring;

  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _ring = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    _fade = CurvedAnimation(parent: _intro, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic));

    // start entrance animation
    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    _ring.dispose();
    super.dispose();
  }

  void _continue() {
  if (_saving) return;
  setState(() => _saving = true);

  HapticFeedback.selectionClick();
  widget.onContinue();
}
  // ===== UI HELPERS =====
  TextStyle _h1() => const TextStyle(
        fontSize: 22,
        height: 1.05,
        fontWeight: FontWeight.w900,
        color: textHi,
        letterSpacing: -0.2,
      );

  TextStyle _h2() => const TextStyle(
        fontSize: 14,
        height: 1.15,
        fontWeight: FontWeight.w900,
        color: textHi,
        letterSpacing: 0.3,
      );

  TextStyle _p() => const TextStyle(
        fontSize: 13.2,
        height: 1.45,
        fontWeight: FontWeight.w600,
        color: textMid,
      );

  TextStyle _small() => const TextStyle(
        fontSize: 11.3,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: textLo,
      );

  BoxDecoration _cardDeco({Color? borderAccent}) {
    final acc = borderAccent ?? Colors.white.withOpacity(0.06);
    return BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: acc.withOpacity(0.55), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.35),
          blurRadius: 18,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }

  Widget _badge({
    required String text,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent.withOpacity(0.92)),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.2,
              fontWeight: FontWeight.w800,
              color: Colors.white.withOpacity(0.86),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 14),
      color: Colors.white.withOpacity(0.06),
    );
  }

  Widget _bullet(String s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: gold.withOpacity(0.95),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(s, style: _p()),
          ),
        ],
      ),
    );
  }

  Widget _tipRow({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: panel2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: gold.withOpacity(0.95), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.8,
                    fontWeight: FontWeight.w900,
                    color: textHi,
                  ),
                ),
                const SizedBox(height: 6),
                Text(desc, style: _small()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat({
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: panel2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10.5,
                letterSpacing: 0.7,
                fontWeight: FontWeight.w900,
                color: Colors.white.withOpacity(0.50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.1,
                fontWeight: FontWeight.w900,
                color: textHi,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // A subtle animated ring header (same vibe as PSL result screen)
  Widget _ringHeader() {
    return SizedBox(
      width: 132,
      height: 132,
      child: AnimatedBuilder(
        animation: _ring,
        builder: (context, _) {
          return CustomPaint(
            painter: _GoldRingPainter(
              rotation: _ring.value * 2 * math.pi,
              main: gold2,
            ),
            child: Center(
              child: Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.03),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Center(
                  child: Text(
                    'PSL',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withOpacity(0.92),
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _ctaButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: gold2,
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: _saving ? null : _continue,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _saving ? 'Saving…' : 'Continue',
                style: const TextStyle(
                  fontSize: 15.2,
                  fontWeight: FontWeight.w900,
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
      ),
    );
  }

  // ===== BUILD =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                  child: Row(
                    children: [
                      // subtle "calm" pulse dot
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, _) {
                          final t = _pulse.value; // 0..1
                          return Container(
                            width: 10 + t * 2.0,
                            height: 10 + t * 2.0,
                            decoration: BoxDecoration(
                              color: gold.withOpacity(0.30 + t * 0.18),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: gold.withOpacity(0.18 + t * 0.08),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Understanding your result',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withOpacity(0.65),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Text(
                          '1 min',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white.withOpacity(0.70),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: _ringHeader()),
                        const SizedBox(height: 18),

                        // Headline
                        Text('What PSL actually measures', style: _h1()),
                        const SizedBox(height: 10),
                        Text(
                          "PSL is mainly about your facial structure — the bone base. "
                          "It’s strict on purpose, so it doesn’t change much from one day to another.",
                          style: _p(),
                        ),

                        const SizedBox(height: 14),

                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _badge(
                              text: 'Mostly structure',
                              icon: Icons.account_tree_rounded,
                              accent: gold,
                            ),
                            _badge(
                              text: 'Stable result',
                              icon: Icons.lock_rounded,
                              accent: gold,
                            ),
                            _badge(
                              text: 'One photo = one moment',
                              icon: Icons.photo_camera_rounded,
                              accent: gold,
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Card 1: Structure
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          decoration: _cardDeco(borderAccent: gold),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PSL focuses on structure', style: _h2()),
                              const SizedBox(height: 12),
                              _bullet(
                                "Jaw / cheekbone support, overall face shape, and symmetry are the main drivers.",
                              ),
                              _bullet(
                                "Things like lighting, hair, facial expression can slightly change the look — but not the structure.",
                              ),
                              _bullet(
                                "That’s why PSL is good for “bone base” ranking, not for full attractiveness.",
                              ),
                              _divider(),
                              Row(
                                children: [
                                  _miniStat(label: 'Best for', value: 'Structure / bone base'),
                                  const SizedBox(width: 12),
                                  _miniStat(label: 'Not for', value: 'Weight / styling'),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Card 2: Why “heavier can score higher”
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          decoration: _cardDeco(borderAccent: Colors.white.withOpacity(0.10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Why a heavier person can still score well', style: _h2()),
                              const SizedBox(height: 12),
                              Text(
                                "This is important: PSL doesn’t directly measure body fat. "
                                "So someone can have strong structure and still carry more facial fullness.",
                                style: _p(),
                              ),
                              const SizedBox(height: 12),
                              _bullet(
                                "Strong bones can still be visible even if the face is fuller.",
                              ),
                              _bullet(
                                "On the other side, someone can be very lean but still have average bone support.",
                              ),
                              _bullet(
                                "So PSL can look “weird” if you expect it to punish weight — that’s not its job.",
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.info_outline_rounded,
                                        color: Colors.white.withOpacity(0.75), size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "If you want a score that reflects leanness / “sharpness”, use Appeal too.",
                                        style: TextStyle(
                                          fontSize: 12.2,
                                          height: 1.35,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white.withOpacity(0.72),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Card 3: Appeal
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          decoration: _cardDeco(borderAccent: gold.withOpacity(0.55)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('When to use Appeal', style: _h2()),
                              const SizedBox(height: 12),
                              Text(
                                "Appeal is closer to “how you look right now”. "
                                "It reacts more to styling, grooming, and overall presentation.",
                                style: _p(),
                              ),
                              const SizedBox(height: 12),
                              _bullet(
                                "Appeal will usually reflect things PSL ignores: facial fullness, grooming, hair, and overall vibe.",
                              ),
                              _bullet(
                                "If PSL feels high/low compared to what you expected — check Appeal. It adds context.",
                              ),
                              _bullet(
                                "Think: PSL = base structure. Appeal = how that structure is showing today.",
                              ),
                              _divider(),
                              Row(
                                children: [
                                  _miniStat(label: 'PSL', value: 'Bone base'),
                                  const SizedBox(width: 12),
                                  _miniStat(label: 'Appeal', value: 'Presentation'),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Card 4: Accuracy tips
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          decoration: _cardDeco(borderAccent: Colors.white.withOpacity(0.10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('How to get a more accurate result', style: _h2()),
                              const SizedBox(height: 12),
                              _tipRow(
                                icon: Icons.wb_sunny_rounded,
                                title: 'Neutral lighting',
                                desc: 'Front light is best. Avoid harsh side light or dark rooms.',
                              ),
                              _tipRow(
                                icon: Icons.sentiment_neutral_rounded,
                                title: 'Neutral expression',
                                desc: 'No big smile, no squint. Keep it relaxed and natural.',
                              ),
                              _tipRow(
                                icon: Icons.center_focus_strong_rounded,
                                title: 'Straight angle',
                                desc: 'Face the camera. Avoid extreme tilt or close-up distortion.',
                              ),
                              _tipRow(
                                icon: Icons.face_retouching_natural,
                                title: 'No heavy filters',
                                desc: 'Filters can confuse the detector and make results unstable.',
                              ),
                              _divider(),
                              Text(
                                "If you want: try 2–3 neutral photos and compare. "
                                "You’ll see the result becomes more consistent.",
                                style: _small(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Bottom note: calm reassurance
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.shield_rounded, color: gold.withOpacity(0.95), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Don’t overthink a single result. It’s one photo, one moment. "
                                  "Use PSL for structure, use Appeal for “overall look”, and compare multiple neutral shots.",
                                  style: TextStyle(
                                    fontSize: 12.4,
                                    height: 1.4,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withOpacity(0.72),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Soft footer info
                        Center(
                          child: Text(
                            "Structural analysis only. Not a statement of your worth.",
                            style: _small(),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),

                // CTA pinned bottom
                _ctaButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtle rotating gold ring for the explanation header.
/// Matches the app vibe without copying PSL result exactly.
class _GoldRingPainter extends CustomPainter {
  final double rotation;
  final Color main;

  _GoldRingPainter({required this.rotation, required this.main});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Outer glow
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = main.withOpacity(0.12);

    canvas.drawOval(rect.deflate(8), glow);

    // Gradient ring
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        transform: GradientRotation(rotation),
        colors: [
          main.withOpacity(0.15),
          main.withOpacity(0.95),
          const Color(0xFF9D7CFF).withOpacity(0.85),
          const Color(0xFFFF8A5B).withOpacity(0.80),
          main.withOpacity(0.95),
          main.withOpacity(0.15),
        ],
        stops: const [0.0, 0.18, 0.42, 0.62, 0.82, 1.0],
      ).createShader(rect);

    canvas.drawOval(rect.deflate(8), ring);

    // Inner subtle ring
    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Colors.white.withOpacity(0.06);

    canvas.drawOval(rect.deflate(22), inner);
  }

  @override
  bool shouldRepaint(covariant _GoldRingPainter oldDelegate) {
    return oldDelegate.rotation != rotation || oldDelegate.main != main;
  }
}