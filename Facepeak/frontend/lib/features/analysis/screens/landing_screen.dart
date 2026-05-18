import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/features/social_free/social_features/social_auth_guard.dart';

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
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _pulse;
  late final AnimationController _float;
  late final AnimationController _orbit;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _contentFade;

  bool _authLoading = false;

  static const Color bgTop = Color(0xFF05040D);
  static const Color bgMid = Color(0xFF0B0718);
  static const Color bgBottom = Color(0xFF04040A);

  static const Color purple = Color(0xFF8B5CFF);
  static const Color purple2 = Color(0xFFC084FC);
  static const Color purple3 = Color(0xFFE9D5FF);
  static const Color gold = Color(0xFFFFD978);
  static const Color whiteSoft = Color(0xFFF8F5FF);

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);

    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();

    _logoFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );

    _logoScale = Tween(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutExpo),
      ),
    );

    _contentFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.18, 1.0, curve: Curves.easeOut),
    );

    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    _float.dispose();
    _orbit.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    if (_authLoading) return;

    HapticFeedback.lightImpact();

    setState(() => _authLoading = true);

    final token = await SocialAuthGuard.ensureBackendToken();

    if (!mounted) return;

    setState(() => _authLoading = false);

    if (token == null || token.isEmpty) {
      HapticFeedback.mediumImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Google sign-in is required to continue.',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          backgroundColor: Colors.black.withOpacity(0.92),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );

      return;
    }

    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final rawMedia = MediaQuery.of(context);

    final media = rawMedia.copyWith(
      textScaler: const TextScaler.linear(1.0),
    );

    return MediaQuery(
      data: media,
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          backgroundColor: bgBottom,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bgTop, bgMid, bgBottom],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(child: _backgroundFx()),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final h = constraints.maxHeight;
                      final compact = h < 760;
                      final veryCompact = h < 690;

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          24,
                          veryCompact ? 18 : 28,
                          24,
                          24 + rawMedia.padding.bottom,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight -
                                rawMedia.padding.top -
                                rawMedia.padding.bottom -
                                40,
                          ),
                          child: FadeTransition(
                            opacity: _contentFade,
                            child: Column(
                              children: [
                                SizedBox(height: compact ? 22 : 34),
                                FadeTransition(
                                  opacity: _logoFade,
                                  child: ScaleTransition(
                                    scale: _logoScale,
                                    child: _heroLogo(compact: compact),
                                  ),
                                ),
                                SizedBox(height: compact ? 24 : 30),
                                _title(compact: compact),
                                SizedBox(height: compact ? 12 : 14),
                                _subtitle(compact: compact),
                                SizedBox(height: compact ? 28 : 36),
                                _securityCard(compact: compact),
                                SizedBox(height: compact ? 24 : 30),
                                _signalCard(compact: compact),
                                SizedBox(height: compact ? 34 : 48),
                                _PremiumCTA(
                                  text: 'Continue with Google',
                                  loading: _authLoading,
                                  onPressed: _go,
                                  pulse: _pulse,
                                ),
                                const SizedBox(height: 16),
                                _hardGateText(),
                                SizedBox(height: veryCompact ? 8 : 18),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _backgroundFx() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _float, _orbit]),
      builder: (context, _) {
        final p = _pulse.value;
        final f = (_float.value - 0.5) * 32;

        return Stack(
          children: [
            Positioned(
              top: -180,
              left: -140,
              right: -140,
              child: Container(
                height: 420,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      purple2.withOpacity(0.16 + p * 0.08),
                      purple.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 260 + f,
              left: -160,
              right: -160,
              child: Container(
                height: 520,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      purple.withOpacity(0.14 + p * 0.04),
                      gold.withOpacity(0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -180,
              left: -160,
              right: -160,
              child: Container(
                height: 400,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      purple2.withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _LandingParticlePainter(
                    t: _orbit.value,
                    color: purple3.withOpacity(0.14),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _heroLogo({required bool compact}) {
    final size = compact ? 108.0 : 122.0;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _orbit]),
      builder: (context, _) {
        final p = _pulse.value;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: purple.withOpacity(0.24 + p * 0.16),
                      blurRadius: 40,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: purple2.withOpacity(0.16),
                      blurRadius: 80,
                    ),
                  ],
                ),
              ),
              RotationTransition(
                turns: _orbit,
                child: CustomPaint(
                  size: Size(size, size),
                  painter: _LogoRingPainter(
                    color: purple2.withOpacity(0.32),
                    bright: purple3.withOpacity(0.92),
                  ),
                ),
              ),
              Container(
                width: size * 0.72,
                height: size * 0.72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.08),
                      purple.withOpacity(0.12),
                      Colors.black.withOpacity(0.24),
                    ],
                  ),
                  border: Border.all(
                    color: purple2.withOpacity(0.20),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 1,
                      height: size * 0.32,
                      color: purple3.withOpacity(0.32),
                    ),
                    Text(
                      'F',
                      style: TextStyle(
                        fontSize: compact ? 44 : 50,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: purple.withOpacity(0.22),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _title({required bool compact}) {
    return ShaderMask(
      shaderCallback: (rect) {
        return const LinearGradient(
          colors: [
            Colors.white,
            purple3,
          ],
        ).createShader(rect);
      },
      child: Text(
        'FacePeak',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: compact ? 42 : 48,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.1,
          color: Colors.white,
          shadows: [
            Shadow(
              color: purple.withOpacity(0.22),
              blurRadius: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _subtitle({required bool compact}) {
    return Text(
      'Unlock your private facial analysis\nwith secure Google verification.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: compact ? 15.5 : 16.5,
        height: 1.42,
        fontWeight: FontWeight.w700,
        color: Colors.white.withOpacity(0.72),
      ),
    );
  }

  Widget _securityCard({required bool compact}) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final p = _pulse.value;

        return ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                18,
                compact ? 16 : 18,
                18,
                compact ? 16 : 18,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: gold.withOpacity(0.20),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    gold.withOpacity(0.10),
                    purple.withOpacity(0.075),
                    Colors.white.withOpacity(0.035),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: gold.withOpacity(0.10 + p * 0.06),
                    blurRadius: 34,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                      border: Border.all(
                        color: gold.withOpacity(0.22),
                      ),
                    ),
                    child: Icon(
                      Icons.verified_user_rounded,
                      color: gold.withOpacity(0.95),
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Google sign-in required',
                          style: TextStyle(
                            color: whiteSoft,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'This protects your free scan, saves your result, and prevents duplicate analysis abuse.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.58),
                            fontSize: 12.6,
                            height: 1.28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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

  Widget _signalCard({required bool compact}) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _float]),
      builder: (context, _) {
        final p = _pulse.value;
        final offset = (_float.value - 0.5) * 5;

        return Transform.translate(
          offset: Offset(0, offset),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              18,
              compact ? 16 : 18,
              18,
              compact ? 16 : 18,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: purple2.withOpacity(0.18),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.05),
                  purple.withOpacity(0.06),
                  Colors.black.withOpacity(0.24),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: purple.withOpacity(0.14 + p * 0.08),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: purple3,
                        boxShadow: [
                          BoxShadow(
                            color: purple2.withOpacity(0.50),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'STRUCTURAL ANALYSIS',
                      style: TextStyle(
                        color: purple3,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 16 : 18),
                Row(
                  children: [
                    _miniPoint(
                      icon: Icons.architecture_rounded,
                      text: 'Bone structure',
                    ),
                    const SizedBox(width: 10),
                    _miniPoint(
                      icon: Icons.grid_4x4_rounded,
                      text: 'Facial harmony',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _miniPoint(
                      icon: Icons.auto_graph_rounded,
                      text: 'Rank profile',
                    ),
                    const SizedBox(width: 10),
                    _miniPoint(
                      icon: Icons.shield_rounded,
                      text: 'Private scan',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _miniPoint({
    required IconData icon,
    required String text,
  }) {
    return Expanded(
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withOpacity(0.035),
          border: Border.all(
            color: purple2.withOpacity(0.12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: purple3.withOpacity(0.95),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withOpacity(0.88),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hardGateText() {
    return Column(
      children: [
        Text(
          'Google verification is required to continue.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.2,
            height: 1.25,
            fontWeight: FontWeight.w900,
            color: Colors.white.withOpacity(0.58),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'By continuing, you agree to our Privacy Policy.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.2,
            height: 1.25,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.38),
          ),
        ),
      ],
    );
  }
}

/* ----------------------- PREMIUM CTA ----------------------- */

class _PremiumCTA extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final bool loading;
  final Animation<double> pulse;

  const _PremiumCTA({
    required this.onPressed,
    required this.text,
    required this.loading,
    required this.pulse,
  });

  @override
  State<_PremiumCTA> createState() => _PremiumCTAState();
}

class _PremiumCTAState extends State<_PremiumCTA>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  late AnimationController _shimmer;

  @override
  void initState() {
    super.initState();

    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
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
        onTapDown: widget.loading
            ? null
            : (_) => setState(() => _pressed = true),
        onTapCancel: widget.loading
            ? null
            : () => setState(() => _pressed = false),
        onTapUp: widget.loading
            ? null
            : (_) {
                setState(() => _pressed = false);
                widget.onPressed();
              },
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: AnimatedBuilder(
            animation: _shimmer,
            builder: (context, _) {
              final t = _shimmer.value;
              final x = (t * 2 - 1);

              return Container(
                height: 62,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      _LandingScreenState.whiteSoft,
                      _LandingScreenState.purple3,
                      _LandingScreenState.purple2,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _LandingScreenState.purple2.withOpacity(0.34),
                      blurRadius: 36,
                      spreadRadius: 1,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: _LandingScreenState.gold.withOpacity(0.10),
                      blurRadius: 46,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: 0.26,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment(x, 0),
                                  end: const Alignment(1.4, 0),
                                  colors: const [
                                    Color(0x00FFFFFF),
                                    Color(0x99FFFFFF),
                                    Color(0x00FFFFFF),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 22,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.26),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: widget.loading
                            ? const SizedBox(
                                width: 23,
                                height: 23,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Color(0xFF22142F),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _GoogleMark(),
                                  const SizedBox(width: 11),
                                  Text(
                                    widget.text,
                                    style: const TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF22142F),
                                      letterSpacing: -0.15,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.94),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: Color(0xFF241A2F),
        ),
      ),
    );
  }
}

/* ----------------------- PAINTERS ----------------------- */

class _LogoRingPainter extends CustomPainter {
  final Color color;
  final Color bright;

  const _LogoRingPainter({
    required this.color,
    required this.bright,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final p1 = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final p2 = Paint()
      ..color = bright
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect.deflate(8),
      -math.pi / 2.25,
      math.pi * 0.30,
      false,
      p2,
    );

    canvas.drawArc(
      rect.deflate(16),
      math.pi * 0.16,
      math.pi * 0.24,
      false,
      p1,
    );

    canvas.drawArc(
      rect.deflate(16),
      math.pi * 1.04,
      math.pi * 0.28,
      false,
      p1..color = color.withOpacity(0.75),
    );
  }

  @override
  bool shouldRepaint(covariant _LogoRingPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.bright != bright;
  }
}

class _LandingParticlePainter extends CustomPainter {
  final double t;
  final Color color;

  const _LandingParticlePainter({
    required this.t,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final points = <Offset>[
      Offset(
        size.width * 0.12,
        size.height * (0.20 + (0.02 * math.sin(t * math.pi * 2))),
      ),
      Offset(
        size.width * 0.86,
        size.height * (0.26 + (0.02 * math.cos(t * math.pi * 2))),
      ),
      Offset(
        size.width * 0.22,
        size.height * (0.72 + (0.015 * math.cos(t * math.pi * 2.5))),
      ),
      Offset(
        size.width * 0.78,
        size.height * (0.66 + (0.018 * math.sin(t * math.pi * 2.3))),
      ),
      Offset(
        size.width * 0.52,
        size.height * (0.12 + (0.016 * math.sin(t * math.pi * 2.1))),
      ),
    ];

    for (final p in points) {
      canvas.drawCircle(p, 1.6, paint);

      canvas.drawCircle(
        p,
        4.8,
        Paint()..color = color.withOpacity(0.10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LandingParticlePainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.color != color;
  }
}