import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';



class LandingScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const LandingScreen({
    super.key,
    required this.onContinue,
  });

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _contentFade;

  static const Color bgTop = Color(0xFF1A1A24);
  static const Color bgMid = Color(0xFF12121A);
  static const Color bgBottom = Color(0xFF0B0B0F);
  static const Color gold = Color(0xFFF5C518);

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );

    _logoScale = Tween(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutExpo),
      ),
    );

    _contentFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    );

    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

void _go() {
  HapticFeedback.lightImpact();
  widget.onContinue();
}
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
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // subtle grain
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.03,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 0.6, sigmaY: 0.6),
                      child: Container(color: Colors.white),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  media.padding.top + 32,
                  24,
                  media.padding.bottom + 28,
                ),
                child: FadeTransition(
                  opacity: _contentFade,
                  child: Column(
                    children: [
                      const Spacer(flex: 3),

                      FadeTransition(
                        opacity: _logoFade,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: gold.withOpacity(0.35),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: gold.withOpacity(0.16),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 1,
                                  height: 46,
                                  color: gold.withOpacity(0.35),
                                ),
                                const Opacity(
                                  opacity: 0.92,
                                  child: Text(
                                    'F',
                                    style: TextStyle(
                                      fontSize: 41,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 26),

                      const Text(
                        'FacePeak',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'See what your face actually signals\nbeyond mirrors, filters, and bias',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.35,
                          color: Color(0xE6FFFFFF),
                        ),
                      ),

                      const Spacer(flex: 4),

                      // ✅ REPLACED SOCIAL PROOF (POLICY SAFE)
                      const Text(
                        'Objective facial analysis powered by structured data',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0x99FFFFFF),
                        ),
                      ),

                      const SizedBox(height: 14),

                      _PremiumCTA(
                        text: 'Start analysis',
                        onPressed: _go,
                      ),

                      const SizedBox(height: 16),

                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_rounded,
                              size: 14, color: Color(0x99FFFFFF)),
                          SizedBox(width: 6),
                          Text(
                            'Secure image processing • Photos deleted after analysis',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0x99FFFFFF),
                            ),
                          ),
                        ],
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

/* ----------------------- PREMIUM CTA ----------------------- */

class _PremiumCTA extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;

  const _PremiumCTA({
    required this.onPressed,
    required this.text,
  });

  @override
  State<_PremiumCTA> createState() => _PremiumCTAState();
}

class _PremiumCTAState extends State<_PremiumCTA>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _shimmer;
  bool _idle = false;

  @override
  void initState() {
    super.initState();
    _initShimmer();
  }

  void _initShimmer() {
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6500),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) {
        _shimmer.stop();
        setState(() => _idle = true);
      }
    });
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.97 : 1.0;

    return Hero(
      tag: 'cta-hero',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: AnimatedBuilder(
            animation: _shimmer,
            builder: (context, _) => _buildButton(shimmer: !_idle),
          ),
        ),
      ),
    );
  }

  Widget _buildButton({required bool shimmer}) {
    final t = _shimmer.value;
    final x = (t * 2 - 1);

    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF5C518),
            Color(0xFFE6B800),
            Color(0xFFF5C518),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5C518).withOpacity(0.16),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            if (shimmer)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.22,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(x, 0),
                        end: const Alignment(1.4, 0),
                        colors: const [
                          Color(0x00FFFFFF),
                          Color(0x33FFFFFF),
                          Color(0x00FFFFFF),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Center(
              child: Text(
                widget.text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0B0B0F),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}