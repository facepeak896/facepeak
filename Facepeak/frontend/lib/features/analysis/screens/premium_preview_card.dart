import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'free_result_card.dart';

class PremiumPreviewCard extends StatefulWidget {
  final ViralResultUiData data;

  const PremiumPreviewCard({
    super.key,
    required this.data,
  });

  @override
  State<PremiumPreviewCard> createState() => _PremiumPreviewCardState();
}

class _PremiumPreviewCardState extends State<PremiumPreviewCard>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _edge;
  late final AnimationController _scan;
  late final AnimationController _shine;
  late final AnimationController _coach;

  static const Color black = Color(0xFF050403);
  static const Color gold = Color(0xFFFFD978);
  static const Color goldSoft = Color(0xFFFFEAB0);
  static const Color amber = Color(0xFFFFA114);
  static const Color violet = Color(0xFF6D28D9);

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _edge = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7200),
    )..repeat();

    _scan = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);

    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4600),
    )..repeat();

    _coach = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _edge.dispose();
    _scan.dispose();
    _shine.dispose();
    _coach.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _edge, _scan, _shine, _coach]),
      builder: (context, _) {
        final p = _pulse.value;

        return Container(
          width: 342,
          height: 610,
          padding: const EdgeInsets.all(13),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(38),
            color: black,
            border: Border.all(
              color: Color.lerp(
                gold.withOpacity(0.44),
                goldSoft.withOpacity(0.92),
                p,
              )!,
              width: 1.35,
            ),
            boxShadow: [
              BoxShadow(
                color: gold.withOpacity(0.18 + p * 0.13),
                blurRadius: 66,
                spreadRadius: 3,
              ),
              BoxShadow(
                color: violet.withOpacity(0.08),
                blurRadius: 88,
                spreadRadius: 8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _LuxuryBackgroundPainter(
                      pulse: p,
                      scan: _scan.value,
                      shine: _shine.value,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _EdgeLightPainter(t: _edge.value),
                  ),
                ),
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 18),
                  child: Column(
                    children: [
                      _AvatarStage(data: d, scan: _scan.value),
                      const SizedBox(height: 12),
                      _ScrollHint(pulse: p),
                      const SizedBox(height: 14),

                      const _HiddenPotentialHero(),

                      const SizedBox(height: 10),

                      const _CurrentReachableHero(),

                      const SizedBox(height: 14),

                      const _SectionTitle('WHAT HELPS & HOLDS YOU BACK'),

                      const SizedBox(height: 9),

                      const _SignalsPreview(),

                      const SizedBox(height: 14),

                      const _SectionTitle('FASTEST VISIBLE IMPROVEMENTS'),

                      const SizedBox(height: 9),

                      const _FixPlanPreview(),

                      const SizedBox(height: 14),

                      const _SectionTitle('PROJECTED TIER CEILING'),

                      const SizedBox(height: 9),

                      _TierMapBig(percentile: d.percentile),

                      const SizedBox(height: 14),

                      const _SectionTitle('DEKKER AI • PERSONALIZED 1-ON-1 COACH'),

                      const SizedBox(height: 9),

                      _DekkerPreview(glow: _coach.value),

                      const SizedBox(height: 14),

                      const _PremiumBottomHint(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AvatarStage extends StatelessWidget {
  final ViralResultUiData data;
  final double scan;

  const _AvatarStage({
    required this.data,
    required this.scan,
  });

  @override
  Widget build(BuildContext context) {
    final scanY = 18 + scan * 82;

    return SizedBox(
      height: 132,
      child: Center(
        child: Container(
          width: 112,
          height: 112,
          padding: const EdgeInsets.all(3),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
            border: Border.all(
              color: _PremiumPreviewCardState.goldSoft.withOpacity(0.74),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _PremiumPreviewCardState.gold.withOpacity(0.20),
                blurRadius: 30,
              ),
            ],
          ),
          child: ClipOval(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: Image.file(
                    data.imageFile,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  top: scanY,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Colors.transparent,
                          _PremiumPreviewCardState.goldSoft,
                          _PremiumPreviewCardState.gold,
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _PremiumPreviewCardState.gold.withOpacity(0.58),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScrollHint extends StatelessWidget {
  final double pulse;

  const _ScrollHint({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -2.2 * pulse),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: _PremiumPreviewCardState.gold.withOpacity(0.13 + pulse * 0.045),
          border: Border.all(
            color: _PremiumPreviewCardState.goldSoft.withOpacity(0.36 + pulse * 0.14),
          ),
          boxShadow: [
            BoxShadow(
              color: _PremiumPreviewCardState.gold.withOpacity(0.14 + pulse * 0.08),
              blurRadius: 22,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('👇', style: TextStyle(fontSize: 15)),
            SizedBox(width: 7),
            Flexible(
              child: Text(
                'SCROLL TO REVEAL YOUR HIDDEN POTENTIAL',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _PremiumPreviewCardState.goldSoft,
                  fontSize: 9.6,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.72,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HiddenPotentialHero extends StatelessWidget {
  const _HiddenPotentialHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.black.withOpacity(0.60),
        border: Border.all(
          color: _PremiumPreviewCardState.gold.withOpacity(0.38),
        ),
        boxShadow: [
          BoxShadow(
            color: _PremiumPreviewCardState.gold.withOpacity(0.13),
            blurRadius: 28,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_rounded,
            size: 19,
            color: _PremiumPreviewCardState.goldSoft,
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HIDDEN POTENTIAL',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _PremiumPreviewCardState.goldSoft,
                    fontSize: 12.4,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.08,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Your reachable tier projection is ready',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 4.7, sigmaY: 4.7),
            child: const Row(
              children: [
                _LuxuryBar(width: 54),
                SizedBox(width: 7),
                _LuxuryBar(width: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentReachableHero extends StatelessWidget {
  const _CurrentReachableHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 98,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.052),
        border: Border.all(
          color: _PremiumPreviewCardState.gold.withOpacity(0.36),
        ),
        boxShadow: [
          BoxShadow(
            color: _PremiumPreviewCardState.gold.withOpacity(0.12),
            blurRadius: 28,
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: _ReachableSide(
              label: 'CURRENT',
              value: '4.8',
              sub: 'starting point',
              muted: true,
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.42),
              border: Border.all(
                color: _PremiumPreviewCardState.gold.withOpacity(0.32),
              ),
              boxShadow: [
                BoxShadow(
                  color: _PremiumPreviewCardState.gold.withOpacity(0.10),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: _PremiumPreviewCardState.goldSoft,
              size: 22,
            ),
          ),
          const Expanded(
            child: _ReachableSide(
              label: 'REACHABLE',
              value: '6.1',
              sub: 'projected ceiling',
              muted: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReachableSide extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final bool muted;

  const _ReachableSide({
    required this.label,
    required this.value,
    required this.sub,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: muted
                ? Colors.white.withOpacity(0.43)
                : _PremiumPreviewCardState.goldSoft.withOpacity(0.88),
            fontSize: 9.6,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.05,
          ),
        ),
        const SizedBox(height: 7),
        ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: muted ? 1.85 : 1.45,
            sigmaY: muted ? 1.85 : 1.45,
          ),
          child: Text(
            value,
            style: TextStyle(
              color: muted ? Colors.white : _PremiumPreviewCardState.goldSoft,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              height: 1,
              shadows: muted
                  ? null
                  : [
                      Shadow(
                        color: _PremiumPreviewCardState.gold.withOpacity(0.32),
                        blurRadius: 18,
                      ),
                    ],
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          sub,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(0.36),
            fontSize: 9.1,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SignalsPreview extends StatelessWidget {
  const _SignalsPreview();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _SignalPanel(
            title: 'BEST TRAITS',
            icon: Icons.auto_awesome_rounded,
            lines: [
              'Strongest features...',
              'Natural advantages...',
              'High-value signals...',
            ],
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _SignalPanel(
            title: 'LIMITING TRAITS',
            icon: Icons.warning_amber_rounded,
            lines: [
              'Holding score back...',
              'Highest ROI fixes...',
              'Fastest improvements...',
            ],
          ),
        ),
      ],
    );
  }
}

class _SignalPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> lines;

  const _SignalPanel({
    required this.title,
    required this.icon,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 142,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(0.040),
        border: Border.all(
          color: _PremiumPreviewCardState.gold.withOpacity(0.27),
        ),
        boxShadow: [
          BoxShadow(
            color: _PremiumPreviewCardState.gold.withOpacity(0.07),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: _PremiumPreviewCardState.goldSoft),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _PremiumPreviewCardState.goldSoft.withOpacity(0.92),
                    fontSize: 8.7,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.72,
                  ),
                ),
              ),
              Icon(
                Icons.lock_rounded,
                size: 13,
                color: _PremiumPreviewCardState.gold.withOpacity(0.84),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final line in lines) ...[
            _BlurredTextLine(text: line),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _FixPlanPreview extends StatelessWidget {
  const _FixPlanPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(0.046),
        border: Border.all(
          color: _PremiumPreviewCardState.gold.withOpacity(0.31),
        ),
        boxShadow: [
          BoxShadow(
            color: _PremiumPreviewCardState.gold.withOpacity(0.09),
            blurRadius: 24,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.bolt_rounded,
            size: 17,
            color: _PremiumPreviewCardState.goldSoft,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 1.55, sigmaY: 1.55),
              child: const Text(
                'Your 3 highest-impact improvements are ready.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.7,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Icon(
            Icons.lock_rounded,
            size: 14,
            color: _PremiumPreviewCardState.gold.withOpacity(0.88),
          ),
        ],
      ),
    );
  }
}

class _TierMapBig extends StatelessWidget {
  final double percentile;

  const _TierMapBig({required this.percentile});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 156,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: Colors.black.withOpacity(0.50),
        border: Border.all(
          color: _PremiumPreviewCardState.gold.withOpacity(0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: _PremiumPreviewCardState.gold.withOpacity(0.09),
            blurRadius: 24,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 1.65, sigmaY: 1.65),
            child: CustomPaint(
              painter: _PremiumGraphPainter(percentile: percentile),
              size: Size.infinite,
            ),
          ),
          Text(
            'PROJECTED TIER CEILING',
            style: TextStyle(
              color: Colors.white.withOpacity(0.58),
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.black.withOpacity(0.66),
                    border: Border.all(
                      color: _PremiumPreviewCardState.gold.withOpacity(0.52),
                    ),
                  ),
                  child: const Text(
                    'PRIVATE',
                    style: TextStyle(
                      color: _PremiumPreviewCardState.goldSoft,
                      fontWeight: FontWeight.w900,
                      fontSize: 10.8,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DekkerPreview extends StatelessWidget {
  final double glow;

  const _DekkerPreview({required this.glow});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 122,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.white.withOpacity(0.055),
        border: Border.all(
          color: Color.lerp(
            _PremiumPreviewCardState.gold.withOpacity(0.30),
            _PremiumPreviewCardState.goldSoft.withOpacity(0.52),
            glow,
          )!,
        ),
        boxShadow: [
          BoxShadow(
            color: _PremiumPreviewCardState.gold.withOpacity(0.10 + glow * 0.06),
            blurRadius: 28,
          ),
          BoxShadow(
            color: _PremiumPreviewCardState.violet.withOpacity(0.09),
            blurRadius: 34,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _PremiumPreviewCardState.gold.withOpacity(0.15 + glow * 0.04),
              border: Border.all(
                color: _PremiumPreviewCardState.goldSoft.withOpacity(0.38 + glow * 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: _PremiumPreviewCardState.gold.withOpacity(0.14 + glow * 0.08),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(
              Icons.psychology_alt_rounded,
              color: _PremiumPreviewCardState.goldSoft,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 0.35, sigmaY: 0.35),
                  child: const Text(
                    'Dekker AI built your private 1-on-1 improvement path.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.25,
                      height: 1.18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    _MiniChip('Best Traits'),
                    _MiniChip('Limiting Traits'),
                    _MiniChip('Fastest Fixes'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.lock_rounded,
            size: 15,
            color: _PremiumPreviewCardState.gold.withOpacity(0.90),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;

  const _MiniChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withOpacity(0.36),
        border: Border.all(
          color: _PremiumPreviewCardState.gold.withOpacity(0.22),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: _PremiumPreviewCardState.goldSoft.withOpacity(0.72),
          fontSize: 8.2,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PremiumBottomHint extends StatelessWidget {
  const _PremiumBottomHint();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Your personalized report is waiting.',
      style: TextStyle(
        color: _PremiumPreviewCardState.goldSoft.withOpacity(0.58),
        fontSize: 10.8,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _BlurredTextLine extends StatelessWidget {
  final String text;

  const _BlurredTextLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 1.65, sigmaY: 1.65),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _PremiumPreviewCardState.goldSoft,
            boxShadow: [
              BoxShadow(
                color: _PremiumPreviewCardState.gold.withOpacity(0.45),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _PremiumPreviewCardState.goldSoft.withOpacity(0.84),
              fontSize: 9.2,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.88,
            ),
          ),
        ),
      ],
    );
  }
}

class _LuxuryBar extends StatelessWidget {
  final double width;

  const _LuxuryBar({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 7,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.22),
            _PremiumPreviewCardState.gold.withOpacity(0.32),
            _PremiumPreviewCardState.goldSoft.withOpacity(0.18),
          ],
        ),
      ),
    );
  }
}

class _PremiumGraphPainter extends CustomPainter {
  final double percentile;

  _PremiumGraphPainter({required this.percentile});

  @override
  void paint(Canvas canvas, Size size) {
    final top = 34.0;
    final bottom = size.height - 12;
    final h = bottom - top;
    final w = size.width;

    final path = Path()..moveTo(0, bottom);

    for (double x = 0; x <= w; x++) {
      final t = x / w;
      final bell = math.exp(-math.pow((t - 0.56) / 0.24, 2));
      final y = bottom - bell * h * 0.88;
      path.lineTo(x, y);
    }

    path.lineTo(w, bottom);
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [
            _PremiumPreviewCardState.gold.withOpacity(0.06),
            _PremiumPreviewCardState.gold.withOpacity(0.40),
            _PremiumPreviewCardState.amber.withOpacity(0.12),
          ],
        ).createShader(Rect.fromLTWH(0, top, w, h)),
    );

    final markerX = (percentile.clamp(0, 100) / 100) * w;

    canvas.drawLine(
      Offset(markerX, top),
      Offset(markerX, bottom),
      Paint()
        ..color = _PremiumPreviewCardState.gold.withOpacity(0.72)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _PremiumGraphPainter oldDelegate) {
    return oldDelegate.percentile != percentile;
  }
}

class _LuxuryBackgroundPainter extends CustomPainter {
  final double pulse;
  final double scan;
  final double shine;

  _LuxuryBackgroundPainter({
    required this.pulse,
    required this.scan,
    required this.shine,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF090604),
            Color(0xFF050403),
            Color(0xFF070506),
          ],
        ).createShader(rect),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _PremiumPreviewCardState.gold.withOpacity(0.13 + pulse * 0.035),
            _PremiumPreviewCardState.amber.withOpacity(0.030),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width * 0.50, size.height * 0.10),
            radius: size.width * 0.95,
          ),
        ),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _PremiumPreviewCardState.violet.withOpacity(0.075),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width * 0.20, size.height * 0.92),
            radius: size.width * 0.75,
          ),
        ),
    );

    final y = size.height * (0.14 + scan * 0.72);

    canvas.drawRect(
      Rect.fromLTWH(0, y, size.width, 1.1),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            _PremiumPreviewCardState.gold.withOpacity(0.16),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, y, size.width, 1.1)),
    );

    final x = (shine * size.width * 1.8) - size.width * 0.5;

    canvas.drawRect(
      Rect.fromLTWH(x, 0, 90, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.028),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(x, 0, 90, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant _LuxuryBackgroundPainter oldDelegate) {
    return oldDelegate.pulse != pulse ||
        oldDelegate.scan != scan ||
        oldDelegate.shine != shine;
  }
}

class _EdgeLightPainter extends CustomPainter {
  final double t;

  _EdgeLightPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final rrect = RRect.fromRectAndRadius(
      rect.deflate(2),
      const Radius.circular(33),
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..shader = SweepGradient(
        transform: GradientRotation(t * math.pi * 2),
        colors: [
          Colors.transparent,
          _PremiumPreviewCardState.gold.withOpacity(0.13),
          _PremiumPreviewCardState.goldSoft.withOpacity(0.84),
          _PremiumPreviewCardState.amber.withOpacity(0.30),
          Colors.transparent,
        ],
        stops: const [0.0, 0.33, 0.43, 0.52, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _EdgeLightPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}