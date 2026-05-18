import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StartupSplashOverlay extends StatefulWidget {
  const StartupSplashOverlay({super.key});

  @override
  State<StartupSplashOverlay> createState() => _StartupSplashOverlayState();
}

class _StartupSplashOverlayState extends State<StartupSplashOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _main;
  late final AnimationController _pulse;
  late final AnimationController _orbit;
  late final AnimationController _scan;
  late final AnimationController _noise;

  bool _visible = true;

  static const Color bg = Color(0xFF02050A);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purple2 = Color(0xFFA855F7);
  static const Color violet = Color(0xFFDBB4FF);
  static const Color gold = Color(0xFFFFC34D);
  static const Color gold2 = Color(0xFFFFE7A8);

  @override
  void initState() {
    super.initState();

    HapticFeedback.selectionClick();

    _main = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _scan = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    )..repeat(reverse: true);

    _noise = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4100),
    )..repeat();

    _main.forward();

    Timer(const Duration(milliseconds: 3100), () {
      if (!mounted) return;
      setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _main.dispose();
    _pulse.dispose();
    _orbit.dispose();
    _scan.dispose();
    _noise.dispose();
    super.dispose();
  }

  double _fade() {
    final v = _main.value;
    if (v < 0.14) return (v / 0.14).clamp(0.0, 1.0);
    if (v > 0.84) return ((1.0 - v) / 0.16).clamp(0.0, 1.0);
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final size = MediaQuery.of(context).size;

    return IgnorePointer(
      ignoring: true,
      child: AnimatedBuilder(
        animation: Listenable.merge([_main, _pulse, _orbit, _scan, _noise]),
        builder: (context, _) {
          final fade = _fade();
          final intro = Curves.easeOutExpo.transform(
            (_main.value / 0.42).clamp(0.0, 1.0),
          );
          final exit = Curves.easeInCubic.transform(
            ((_main.value - 0.78) / 0.22).clamp(0.0, 1.0),
          );

          final scale = 0.84 + intro * 0.16 + exit * 0.035;
          final y = 18 * (1 - intro) - exit * 10;
          final pulse = _pulse.value;

          return Opacity(
            opacity: fade,
            child: Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  Positioned.fill(child: Container(color: bg)),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _EliteSplashBgPainter(
                        t: _noise.value,
                        pulse: pulse,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 8 * exit,
                        sigmaY: 8 * exit,
                      ),
                      child: Container(
                        color: Colors.black.withOpacity(0.08 * exit),
                      ),
                    ),
                  ),

                  Center(
                    child: Transform.translate(
                      offset: Offset(0, y),
                      child: Transform.scale(
                        scale: scale,
                        child: SizedBox(
                          width: math.min(size.width * 0.82, 360),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 228,
                                height: 228,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 178 + pulse * 24,
                                      height: 178 + pulse * 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: purple.withOpacity(
                                              0.34 + pulse * 0.14,
                                            ),
                                            blurRadius: 70 + pulse * 22,
                                            spreadRadius: 8,
                                          ),
                                          BoxShadow(
                                            color: gold.withOpacity(
                                              0.15 + pulse * 0.08,
                                            ),
                                            blurRadius: 92,
                                            spreadRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),

                                    RotationTransition(
                                      turns: _orbit,
                                      child: CustomPaint(
                                        size: const Size(228, 228),
                                        painter: _EliteOrbitPainter(),
                                      ),
                                    ),

                                    RotationTransition(
                                      turns: Tween<double>(
                                        begin: 0,
                                        end: -1,
                                      ).animate(_orbit),
                                      child: CustomPaint(
                                        size: const Size(188, 188),
                                        painter: _InnerOrbitPainter(),
                                      ),
                                    ),

                                    Container(
                                      width: 126,
                                      height: 126,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            violet.withOpacity(0.24),
                                            purple.withOpacity(0.16),
                                            Colors.black.withOpacity(0.10),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.10),
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: purple2.withOpacity(0.36),
                                            blurRadius: 38,
                                          ),
                                          BoxShadow(
                                            color: gold.withOpacity(0.16),
                                            blurRadius: 52,
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Positioned.fill(
                                            child: ClipOval(
                                              child: CustomPaint(
                                                painter: _CoreScanPainter(
                                                  scan: _scan.value,
                                                ),
                                              ),
                                            ),
                                          ),
                                          ShaderMask(
                                            shaderCallback: (rect) {
                                              return const LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  gold2,
                                                  Colors.white,
                                                  violet,
                                                  purple2,
                                                ],
                                              ).createShader(rect);
                                            },
                                            child: const Text(
                                              "FP",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 44,
                                                height: 1,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -3.2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 18),

                              ShaderMask(
                                shaderCallback: (rect) {
                                  return const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      gold2,
                                      Colors.white,
                                      violet,
                                      purple2,
                                    ],
                                  ).createShader(rect);
                                },
                                child: const Text(
                                  "FacePeak",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 38,
                                    height: 1.0,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.55,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 9),

                              Opacity(
                                opacity: Curves.easeOutCubic.transform(
                                  ((_main.value - 0.20) / 0.28)
                                      .clamp(0.0, 1.0),
                                ),
                                child: Text(
                                  "SOCIAL LOOKS INTELLIGENCE",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.56),
                                    fontSize: 11.5,
                                    height: 1,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.6,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 22),

                              _ProgressLine(
                                value: Curves.easeInOutCubic.transform(
                                  (_main.value / 0.76).clamp(0.0, 1.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final double value;

  const _ProgressLine({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      height: 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.08),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              colors: [
                _StartupSplashOverlayState.purple,
                _StartupSplashOverlayState.gold,
                _StartupSplashOverlayState.gold2,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: _StartupSplashOverlayState.gold.withOpacity(0.45),
                blurRadius: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EliteOrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final p1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..color = _StartupSplashOverlayState.gold2.withOpacity(0.92);

    final p2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = _StartupSplashOverlayState.purple2.withOpacity(0.62);

    canvas.drawArc(rect.deflate(9), -math.pi / 2.1, math.pi * 0.34, false, p1);
    canvas.drawArc(rect.deflate(18), math.pi * 0.18, math.pi * 0.42, false, p2);
    canvas.drawArc(rect.deflate(27), math.pi * 1.05, math.pi * 0.32, false, p1);
    canvas.drawArc(rect.deflate(38), math.pi * 0.72, math.pi * 0.24, false, p2);
  }

  @override
  bool shouldRepaint(covariant _EliteOrbitPainter oldDelegate) => true;
}

class _InnerOrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round
      ..color = _StartupSplashOverlayState.gold.withOpacity(0.42);

    canvas.drawArc(rect.deflate(16), math.pi * 0.2, math.pi * 0.36, false, paint);
    canvas.drawArc(rect.deflate(24), math.pi * 1.24, math.pi * 0.28, false, paint);
  }

  @override
  bool shouldRepaint(covariant _InnerOrbitPainter oldDelegate) => true;
}

class _CoreScanPainter extends CustomPainter {
  final double scan;

  const _CoreScanPainter({required this.scan});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _StartupSplashOverlayState.purple2.withOpacity(0.16),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, bgPaint);

    final y = size.height * scan;

    final glow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          _StartupSplashOverlayState.purple2.withOpacity(0.05),
          _StartupSplashOverlayState.gold2.withOpacity(0.30),
          _StartupSplashOverlayState.purple2.withOpacity(0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, y - 24, size.width, 48));

    canvas.drawRect(Rect.fromLTWH(0, y - 24, size.width, 48), glow);

    final line = Paint()
      ..color = _StartupSplashOverlayState.gold2.withOpacity(0.66)
      ..strokeWidth = 1.7;

    canvas.drawLine(Offset(14, y), Offset(size.width - 14, y), line);
  }

  @override
  bool shouldRepaint(covariant _CoreScanPainter oldDelegate) {
    return oldDelegate.scan != scan;
  }
}

class _EliteSplashBgPainter extends CustomPainter {
  final double t;
  final double pulse;

  const _EliteSplashBgPainter({
    required this.t,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.43);

    final mainGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          _StartupSplashOverlayState.purple.withOpacity(0.22 + pulse * 0.06),
          _StartupSplashOverlayState.gold.withOpacity(0.055),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: size.width * 0.72),
      );

    canvas.drawCircle(center, size.width * 0.72, mainGlow);

    final topGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          _StartupSplashOverlayState.gold.withOpacity(0.09),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.18, size.height * 0.16),
          radius: size.width * 0.42,
        ),
      );

    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.16),
      size.width * 0.42,
      topGlow,
    );

    final particlePaint = Paint()
      ..color = _StartupSplashOverlayState.gold2.withOpacity(0.20);

    final purplePaint = Paint()
      ..color = _StartupSplashOverlayState.purple2.withOpacity(0.18);

    final points = <Offset>[
      Offset(size.width * 0.16, size.height * (0.22 + 0.018 * math.sin(t * math.pi * 2))),
      Offset(size.width * 0.83, size.height * (0.26 + 0.015 * math.cos(t * math.pi * 2))),
      Offset(size.width * 0.24, size.height * (0.69 + 0.016 * math.cos(t * math.pi * 2.4))),
      Offset(size.width * 0.76, size.height * (0.64 + 0.018 * math.sin(t * math.pi * 2.2))),
      Offset(size.width * 0.52, size.height * (0.14 + 0.014 * math.sin(t * math.pi * 2.1))),
      Offset(size.width * 0.38, size.height * (0.82 + 0.012 * math.cos(t * math.pi * 1.8))),
    ];

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final paint = i.isEven ? particlePaint : purplePaint;

      canvas.drawCircle(p, 1.5, paint);
      canvas.drawCircle(
        p,
        5.5,
        Paint()..color = paint.color.withOpacity(0.23),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EliteSplashBgPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.pulse != pulse;
  }
}