import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class ViralResultUiData {
  final File imageFile;
  final double score;
  final String tierLabel;
  final String populationLabel;
  final String confidenceLabel;
  final double percentile;
  final double confidence;

  const ViralResultUiData({
    required this.imageFile,
    required this.score,
    required this.tierLabel,
    required this.populationLabel,
    required this.confidenceLabel,
    required this.percentile,
    required this.confidence,
  });
}

class FreeResultCard extends StatefulWidget {
  final ViralResultUiData data;

  const FreeResultCard({
    super.key,
    required this.data,
  });

  @override
  State<FreeResultCard> createState() => _FreeResultCardState();
}

class _FreeResultCardState extends State<FreeResultCard>
    with TickerProviderStateMixin {
  static const Color bg = Color(0xFF05030B);
  static const Color card = Color(0xFF080512);
  static const Color violet = Color(0xFF8B5CFF);
  static const Color deepViolet = Color(0xFF35127F);
  static const Color electric = Color(0xFFC06CFF);
  static const Color cyan = Color(0xFF5EF1FF);
  static const Color pink = Color(0xFFFF5FD7);
  static const Color gold = Color(0xFFFFD27D);
  static const Color mtnWhite = Color(0xFFF0E9FF);

  late final AnimationController _intro;
  late final AnimationController _pulse;
  late final AnimationController _shimmer;
  late final AnimationController _float;

  late final Animation<double> _shellIn;
  late final Animation<double> _avatarIn;
  late final Animation<double> _rankIn;
  late final Animation<double> _copyIn;
  late final Animation<double> _graphIn;

  @override
  void initState() {
    super.initState();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..forward();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);

    _shellIn = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.00, 0.25, curve: Curves.easeOutCubic),
    );

    _avatarIn = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.06, 0.36, curve: _SoftPopCurve()),
    );

    _rankIn = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.28, 0.68, curve: _TierPopCurve()),
    );

    _copyIn = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.52, 0.80, curve: Curves.easeOutCubic),
    );

    _graphIn = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.62, 1.00, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    _shimmer.dispose();
    _float.dispose();
    super.dispose();
  }

  _RankVisual _rankVisual() {
    final code = widget.data.tierLabel.toUpperCase().trim();

    if (code.contains('ELITE')) {
      return const _RankVisual(code: 'ELITE', subline: 'Actually unfair ☠️');
    }

    if (code.contains('CHADLITE')) {
      return const _RankVisual(
        code: 'CHADLITE',
        subline: 'Most cannot compete 🔥',
      );
    }

    if (code.contains('CHAD')) {
      return const _RankVisual(
        code: 'CHAD',
        subline: 'Breaks normal standards 🧬',
      );
    }

    if (code.contains('HTN')) {
      return const _RankVisual(
        code: 'HTN',
        subline: 'Clearly clears average 📈',
      );
    }

    if (code.contains('MTN')) {
      return const _RankVisual(
        code: 'MTN',
        subline: 'Enough to get noticed 🎯',
      );
    }

    if (code.contains('LTN')) {
      return const _RankVisual(
        code: 'LTN',
        subline: 'Mostly blends in 🛠️',
      );
    }

    if (code.contains('SUB-5')) {
      return const _RankVisual(
        code: 'SUB-5',
        subline: 'Visibly below average 🔒',
      );
    }

    return const _RankVisual(
      code: 'SUB-3',
      subline: 'Brutal starting point 🧱',
    );
  }

  @override
Widget build(BuildContext context) {
  final visual = _rankVisual();
  final media = MediaQuery.of(context);
  final screenWidth = media.size.width;

  final cardWidth = math.min(screenWidth * 0.905, 370.0).clamp(318.0, 370.0);
  final scale = cardWidth / 350.0;

  final avatarSize = (148.0 * scale).clamp(134.0, 156.0);
  final totalHeight = 582.0 * scale;

  return AnimatedBuilder(
    animation: Listenable.merge([
      _intro,
      _pulse,
      _shimmer,
      _float,
    ]),
    builder: (context, _) {
      final shellScale = 0.962 + (_shellIn.value * 0.038);

      final floatX = math.sin(_float.value * math.pi * 2) * 1.8;
      final floatY = math.cos(_float.value * math.pi * 2) * 2.8;

      return Opacity(
        opacity: _shellIn.value,
        child: Transform.scale(
          scale: shellScale,
          child: SizedBox(
            width: cardWidth,
            height: totalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ParticlePainter(
                        shimmer: _shimmer.value,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 134 * scale,
                  left: 0,
                  right: 0,
                  child: _PosterCardShell(
                    pulse: _pulse.value,
                    width: cardWidth,
                    scale: scale,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        17 * scale,
                        37 * scale,
                        17 * scale,
                        15 * scale,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FadeTransition(
                            opacity: _rankIn,
                            child: Transform.scale(
                              scale: 0.70 + (_rankIn.value * 0.30),
                              child: _TierCountReveal(
                                visual: visual,
                                progress: _rankIn.value,
                                scale: scale,
                                shimmer: _shimmer.value,
                              ),
                            ),
                          ),
                          SizedBox(height: 8 * scale),

                          // ✅ fixed: no double fade/typewriter
                          _RankCopyBlock(
                            visual: visual,
                            progress: _copyIn.value,
                            scale: scale,
                          ),

                          SizedBox(height: 14 * scale),
                          FadeTransition(
                            opacity: _graphIn,
                            child: _FutureTierGraph(
                              percentile: widget.data.percentile,
                              confidence: widget.data.confidence,
                              progress: _graphIn.value,
                              scale: scale,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 4 * scale,
                  child: FadeTransition(
                    opacity: _avatarIn,
                    child: Transform.scale(
                      scale: 0.82 + (_avatarIn.value * 0.18),
                      child: Transform.translate(
                        offset: Offset(
                          floatX,
                          (10 * (1 - _avatarIn.value)) - floatY,
                        ),
                        child: _FloatingAvatar(
                          imageFile: widget.data.imageFile,
                          pulse: _pulse.value,
                          size: avatarSize,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}}

class _RankVisual {
  final String code;
  final String subline;

  const _RankVisual({
    required this.code,
    required this.subline,
  });
}

class _PosterCardShell extends StatelessWidget {
  final double pulse;
  final double width;
  final double scale;
  final Widget child;

  const _PosterCardShell({
    required this.pulse,
    required this.width,
    required this.scale,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final border = Color.lerp(
      _FreeResultCardState.violet.withOpacity(0.42),
      _FreeResultCardState.electric.withOpacity(0.68),
      pulse,
    )!;

    return Container(
      width: width,
      constraints: BoxConstraints(
        minHeight: 418 * scale,
        maxHeight: 432 * scale,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36 * scale),
        color: _FreeResultCardState.card,
        border: Border.all(color: border, width: 1.15),
        boxShadow: [
          BoxShadow(
            color: _FreeResultCardState.deepViolet.withOpacity(0.50),
            blurRadius: 54 * scale,
            spreadRadius: 5 * scale,
            offset: Offset(0, 20 * scale),
          ),
          BoxShadow(
            color: _FreeResultCardState.violet.withOpacity(0.26),
            blurRadius: 96 * scale,
            spreadRadius: 8 * scale,
          ),
          BoxShadow(
            color: _FreeResultCardState.pink.withOpacity(0.10),
            blurRadius: 132 * scale,
            spreadRadius: 12 * scale,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34 * scale),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _FutureCardPainter(pulse: pulse),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.050),
                        Colors.transparent,
                        Colors.black.withOpacity(0.13),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -42 * scale,
              left: -16 * scale,
              right: -16 * scale,
              child: IgnorePointer(
                child: Container(
                  height: 94 * scale,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.13),
                        Colors.white.withOpacity(0.025),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _FloatingAvatar extends StatelessWidget {
  final File imageFile;
  final double pulse;
  final double size;

  const _FloatingAvatar({
    required this.imageFile,
    required this.pulse,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final border = Color.lerp(
      Colors.white.withOpacity(0.16),
      _FreeResultCardState.electric.withOpacity(0.42),
      pulse,
    )!;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black,
        border: Border.all(color: border, width: 1.35),
        boxShadow: [
          BoxShadow(
            color: _FreeResultCardState.deepViolet.withOpacity(0.36),
            blurRadius: 38,
            spreadRadius: 2,
            offset: const Offset(0, 13),
          ),
          BoxShadow(
            color: _FreeResultCardState.electric.withOpacity(0.14),
            blurRadius: 66,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.033),
        child: ClipOval(
          child: Image.file(
            imageFile,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

class _TierCountReveal extends StatelessWidget {
  final _RankVisual visual;
  final double progress;
  final double scale;
  final double shimmer;

  const _TierCountReveal({
    required this.visual,
    required this.progress,
    required this.scale,
    required this.shimmer,
  });

  Color _rankColor(String code) {
    switch (code) {
      case 'MTN':
        return _FreeResultCardState.mtnWhite;
      case 'HTN':
        return const Color(0xFF9DFFEA);
      case 'CHADLITE':
        return const Color(0xFFFFD27D);
      case 'CHAD':
        return const Color(0xFFFFA14F);
      case 'ELITE':
        return const Color(0xFFFFF0A3);
      case 'LTN':
        return const Color(0xFF9AA8FF);
      case 'SUB-5':
        return const Color(0xFFC06CFF);
      case 'SUB-3':
        return const Color(0xFFFF77B7);
      default:
        return _FreeResultCardState.electric;
    }
  }

  String _rollingCode() {
    final stages = [
      'SUB-3',
      'SUB-5',
      'LTN',
      'MTN',
      'HTN',
      'CHADLITE',
      'CHAD',
      'ELITE',
      visual.code,
    ];

    final idx = (progress * (stages.length - 1))
        .floor()
        .clamp(0, stages.length - 1);

    return stages[idx];
  }

  @override
  Widget build(BuildContext context) {
    final showing = progress < 0.975 ? _rollingCode() : visual.code;
    final rankColor = _rankColor(visual.code);
    final isLong = showing.length > 6;
    final fontSize = isLong ? 41.5 * scale : 62.0 * scale;

    final slide = shimmer * 2 - 1;

    return ShaderMask(
      shaderCallback: (rect) {
        return LinearGradient(
          begin: Alignment(-1.2 + slide, -0.2),
          end: Alignment(1.2 + slide, 0.2),
          colors: [
            Colors.white,
            rankColor,
            Colors.white.withOpacity(0.96),
            _FreeResultCardState.electric.withOpacity(0.96),
          ],
          stops: const [0.0, 0.38, 0.52, 1.0],
        ).createShader(rect);
      },
      child: Text(
        showing,
        textAlign: TextAlign.center,
        maxLines: 1,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          height: 0.88,
          fontWeight: FontWeight.w900,
          letterSpacing: isLong ? -2.0 * scale : -2.6 * scale,
          shadows: [
            Shadow(
              color: rankColor.withOpacity(0.36),
              blurRadius: 24,
            ),
            Shadow(
              color: _FreeResultCardState.deepViolet.withOpacity(0.50),
              blurRadius: 42,
            ),
          ],
        ),
      ),
    );
  }
}

class _RankCopyBlock extends StatelessWidget {
  final _RankVisual visual;
  final double progress;
  final double scale;

  const _RankCopyBlock({
    required this.visual,
    required this.progress,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = progress.clamp(0.0, 1.0);

    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: 318 * scale,
        child: Text(
          visual.subline,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(0.90),
            fontSize: 14.8 * scale,
            height: 1.14,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.10 * scale,
            shadows: [
              Shadow(
                color: _FreeResultCardState.electric.withOpacity(0.18),
                blurRadius: 16,
              ),
              Shadow(
                color: Colors.black.withOpacity(0.70),
                blurRadius: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FutureTierGraph extends StatelessWidget {
  final double percentile;
  final double confidence;
  final double progress;
  final double scale;

  const _FutureTierGraph({
    required this.percentile,
    required this.confidence,
    required this.progress,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 258 * scale,
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        12 * scale,
        12 * scale,
        12 * scale,
        10 * scale,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28 * scale),
        color: Colors.black.withOpacity(0.44),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: _FreeResultCardState.violet.withOpacity(0.16),
            blurRadius: 34 * scale,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _FutureGraphPainter(
                percentile: percentile,
                confidence: confidence,
                progress: progress,
              ),
              child: Align(
                alignment: Alignment.topLeft,
                child: Opacity(
                  opacity: progress.clamp(0.0, 1.0),
                  child: Row(
                    children: [
                      Text('🧬', style: TextStyle(fontSize: 13 * scale)),
                      SizedBox(width: 7 * scale),
                      Text(
                        'TIER MAP',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.70),
                          fontSize: 10.8 * scale,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 8 * scale),
          Opacity(
            opacity: progress.clamp(0.0, 1.0),
            child: _TierLabelRow(scale: scale),
          ),
        ],
      ),
    );
  }
}

class _TierLabelRow extends StatelessWidget {
  final double scale;

  const _TierLabelRow({
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    const labels = [
      'SUB-3',
      'SUB-5',
      'LTN',
      'MTN',
      'HTN',
      'CL',
      'CHAD',
      'ELITE',
    ];

    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: label == 'ELITE'
                        ? Colors.white.withOpacity(0.92)
                        : Colors.white.withOpacity(0.72),
                    fontSize: label.length > 4 ? 8.2 * scale : 9.2 * scale,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.10,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FutureGraphPainter extends CustomPainter {
  final double percentile;
  final double confidence;
  final double progress;

  _FutureGraphPainter({
    required this.percentile,
    required this.confidence,
    required this.progress,
  });

  double _smooth(double a, double b, double t) {
    final x = t.clamp(0.0, 1.0);
    final s = x * x * x * (x * (x * 6 - 15) + 10);
    return a + (b - a) * s;
  }

  double _density(double t) {
    if (t < 0.08) {
      return _smooth(0.08, 0.26, t / 0.08);
    }

    if (t < 0.18) {
      return _smooth(0.26, 0.56, (t - 0.08) / 0.10);
    }

    if (t < 0.30) {
      return _smooth(0.56, 1.14, (t - 0.18) / 0.12);
    }

    if (t < 0.37) {
      return 1.14;
    }

    if (t < 0.50) {
      return _smooth(1.14, 0.58, (t - 0.37) / 0.13);
    }

    if (t < 0.64) {
      return _smooth(0.58, 0.22, (t - 0.50) / 0.14);
    }

    if (t < 0.76) {
      return _smooth(0.22, 0.095, (t - 0.64) / 0.12);
    }

    if (t < 0.88) {
      return _smooth(0.095, 0.038, (t - 0.76) / 0.12);
    }

    return _smooth(0.038, 0.008, (t - 0.88) / 0.12);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.clamp(0.0, 1.0);
    final w = size.width;
    final top = 34.0;
    final bottom = size.height - 8;
    final h = bottom - top;

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.055 * p)
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final y = top + h * i / 3;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    final fullPath = Path();
    final fillPath = Path();

    for (double x = 0; x <= w; x++) {
      final t = x / w;
      final y = bottom - (_density(t) / 1.14) * h * 0.96;

      if (x == 0) {
        fullPath.moveTo(x, y);
        fillPath.moveTo(x, bottom);
        fillPath.lineTo(x, y);
      } else {
        fullPath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(w, bottom);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF5EF1FF).withOpacity(0.12 * p),
            const Color(0xFF8B5CFF).withOpacity(0.52 * p),
            const Color(0xFFFF5FD7).withOpacity(0.22 * p),
            const Color(0xFFFFD27D).withOpacity(0.08 * p),
          ],
        ).createShader(Rect.fromLTWH(0, top, w, h)),
    );

    final metric = fullPath.computeMetrics().first;
    final extract = metric.extractPath(0, metric.length * p);

    canvas.drawPath(
      extract,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF5EF1FF),
            Color(0xFF8B5CFF),
            Color(0xFFFF5FD7),
            Color(0xFFFFD27D),
          ],
        ).createShader(Rect.fromLTWH(0, top, w, h))
        ..strokeWidth = 4.35
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final markerX = ((percentile.clamp(0.0, 100.0) / 100.0) * w) * p;
    final t = markerX / w;
    final markerY = bottom - (_density(t) / 1.14) * h * 0.96;

    if (p > 0.08) {
      final uncertainty = (1.0 - confidence.clamp(0.0, 1.0)) * 28 + 7;

      final left = (markerX - uncertainty).clamp(0.0, w);
      final right = (markerX + uncertainty).clamp(0.0, w);

      final zoneRect = Rect.fromLTWH(
        left,
        top,
        (right - left).clamp(6.0, w),
        bottom - top,
      );

      canvas.drawRect(
        zoneRect,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withOpacity(0.00),
              _FreeResultCardState.electric.withOpacity(0.065 * p),
              Colors.white.withOpacity(0.00),
            ],
          ).createShader(zoneRect),
      );

      canvas.drawLine(
        Offset(markerX, top + 4),
        Offset(markerX, bottom),
        Paint()
          ..color = Colors.white.withOpacity(0.46 * p)
          ..strokeWidth = 1.45,
      );

      canvas.drawCircle(
        Offset(markerX, markerY),
        10.4,
        Paint()
          ..color = _FreeResultCardState.electric.withOpacity(0.40 * p)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      canvas.drawCircle(
        Offset(markerX, markerY),
        5.1,
        Paint()..color = Colors.white.withOpacity(0.98),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FutureGraphPainter oldDelegate) {
    return oldDelegate.percentile != percentile ||
        oldDelegate.confidence != confidence ||
        oldDelegate.progress != progress;
  }
}

class _FutureCardPainter extends CustomPainter {
  final double pulse;

  _FutureCardPainter({
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.18),
      size.width * 0.22,
      Paint()
        ..color = _FreeResultCardState.electric.withOpacity(0.050)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80),
    );

    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.72),
      size.width * 0.26,
      Paint()
        ..color = _FreeResultCardState.cyan.withOpacity(0.045)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _FreeResultCardState.deepViolet.withOpacity(0.40 + pulse * 0.08),
            _FreeResultCardState.violet.withOpacity(0.17),
            Colors.transparent,
          ],
          stops: const [0.0, 0.36, 1.0],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width * 0.50, size.height * 0.04),
            radius: size.width * 0.82,
          ),
        ),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _FreeResultCardState.pink.withOpacity(0.11),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width * 0.90, size.height * 0.60),
            radius: size.width * 0.62,
          ),
        ),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _FreeResultCardState.cyan.withOpacity(0.065),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width * 0.08, size.height * 0.78),
            radius: size.width * 0.55,
          ),
        ),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.036),
            Colors.transparent,
            _FreeResultCardState.violet.withOpacity(0.078),
          ],
        ).createShader(rect),
    );

    final rrect = RRect.fromRectAndRadius(
      rect.deflate(1),
      const Radius.circular(34),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withOpacity(0.070),
    );
  }

  @override
  bool shouldRepaint(covariant _FutureCardPainter oldDelegate) {
    return oldDelegate.pulse != pulse;
  }
}

class _ParticlePainter extends CustomPainter {
  final double shimmer;

  _ParticlePainter({
    required this.shimmer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (int i = 0; i < 22; i++) {
      final seed = i * 0.173;

      final dx =
          (math.sin((shimmer * 2 + seed) * math.pi) * 0.5 + 0.5) * size.width;

      final dy =
          (math.cos((shimmer * 1.3 + seed) * math.pi) * 0.5 + 0.5) * size.height;

      final radius = (i % 3 == 0) ? 2.0 : 1.15;

      paint.color = Colors.white.withOpacity(
        i % 2 == 0 ? 0.040 : 0.024,
      );

      canvas.drawCircle(
        Offset(dx, dy),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.shimmer != shimmer;
  }
}

class _TierPopCurve extends Curve {
  const _TierPopCurve();

  @override
  double transformInternal(double t) {
    final eased = Curves.easeOutCubic.transform(t);
    final overshoot = math.sin(t * math.pi) * 0.18;
    return (eased + overshoot).clamp(0.0, 1.14);
  }
}

class _SoftPopCurve extends Curve {
  const _SoftPopCurve();

  @override
  double transformInternal(double t) {
    final eased = Curves.easeOutCubic.transform(t);
    final overshoot = math.sin(t * math.pi) * 0.10;
    return (eased + overshoot).clamp(0.0, 1.10);
  }
}