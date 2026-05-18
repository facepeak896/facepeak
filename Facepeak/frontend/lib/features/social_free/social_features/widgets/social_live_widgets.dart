import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SocialLivePalette {
  static const Color bg = Color(0xFF0B0E14);
  static const Color deep = Color(0xFF05070C);
  static const Color gold1 = Color(0xFFB8922E);
  static const Color gold2 = Color(0xFFF0CF5A);
  static const Color gold3 = Color(0xFFFFEDB3);
  static const Color purple = Color(0xFF7C3AED);
  static const Color cyan = Color(0xFF8FD8FF);
  static const Color editColor = Color(0xFF111827);
  static const Color analyticsColor = Color(0xFF1F2937);
  static const Color matchesColor = Color(0xFF7C3AED);
}

class SocialLiveBackground extends StatelessWidget {
  const SocialLiveBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: SocialLivePalette.bg),
        ),
        Positioned(
          top: -120,
          left: -140,
          child: _GlowOrb(
            size: 330,
            color: SocialLivePalette.cyan.withOpacity(0.08),
            blur: 160,
          ),
        ),
        Positioned(
          top: 35,
          right: -145,
          child: _GlowOrb(
            size: 360,
            color: SocialLivePalette.purple.withOpacity(0.15),
            blur: 170,
          ),
        ),
        Positioned(
          bottom: -80,
          left: 10,
          right: 10,
          child: _GlowOrb(
            size: 260,
            color: SocialLivePalette.gold2.withOpacity(0.18),
            blur: 150,
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.05),
                  Colors.transparent,
                  Colors.black.withOpacity(0.20),
                  Colors.black.withOpacity(0.35),
                ],
                stops: const [0, 0.28, 0.74, 1],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double blur;

  const _GlowOrb({
    required this.size,
    required this.color,
    required this.blur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: blur,
            spreadRadius: 8,
          ),
        ],
      ),
    );
  }
}

class SocialLiveTopBar extends StatelessWidget {
  final VoidCallback onSettings;

  const SocialLiveTopBar({
    super.key,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        GestureDetector(
          onTap: onSettings,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.055),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.07)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.more_horiz_rounded,
              size: 23,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class SocialLiveAvatar extends StatelessWidget {
  final String imagePath;
  final double imageSize;
  final double glowSize;
  final Animation<double> pulse;
  final Animation<double> screenAnim;

  const SocialLiveAvatar({
    super.key,
    required this.imagePath,
    required this.imageSize,
    required this.glowSize,
    required this.pulse,
    required this.screenAnim,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath.isNotEmpty;
    final isNetworkImage =
        hasImage && (imagePath.startsWith("http://") || imagePath.startsWith("https://"));
    final isLocalImage = hasImage && !isNetworkImage;

    return AnimatedBuilder(
      animation: Listenable.merge([pulse, screenAnim]),
      builder: (context, _) {
        final glow = pulse.value;
        final reveal = Curves.easeOut.transform(screenAnim.value);
        final scale = 0.955 + (0.045 * reveal);

        return Transform.scale(
          scale: scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: glowSize,
                height: glowSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(46),
                  boxShadow: [
                    BoxShadow(
                      color: SocialLivePalette.gold2.withOpacity(0.12 + glow * 0.13),
                      blurRadius: 36 + glow * 12,
                      spreadRadius: 1.2,
                    ),
                    BoxShadow(
                      color: SocialLivePalette.purple.withOpacity(0.10 + glow * 0.06),
                      blurRadius: 54,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      SocialLivePalette.gold3.withOpacity(0.90),
                      SocialLivePalette.gold2.withOpacity(0.48),
                      SocialLivePalette.purple.withOpacity(0.34),
                      Colors.white.withOpacity(0.10),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.38),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(33),
                  child: Container(
                    width: imageSize,
                    height: imageSize,
                    color: Colors.black,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (isLocalImage)
                          Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const _AvatarFallback(),
                          )
                        else if (isNetworkImage)
                          Image.network(
                            imagePath,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: SocialLivePalette.gold2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => const _AvatarFallback(),
                          )
                        else
                          const _AvatarFallback(),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.06),
                                Colors.transparent,
                                Colors.black.withOpacity(0.16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.person_rounded,
        size: 72,
        color: Colors.white38,
      ),
    );
  }
}

class SocialLiveIdentityBlock extends StatelessWidget {
  final String username;
  final String percentile;
  final Color percentileColor;
  final bool compact;
  final Animation<double> pulse;
  final Animation<double> screenAnim;
  final Animation<double> percentileAnim;

  const SocialLiveIdentityBlock({
    super.key,
    required this.username,
    required this.percentile,
    required this.percentileColor,
    required this.compact,
    required this.pulse,
    required this.screenAnim,
    required this.percentileAnim,
  });

  @override
  Widget build(BuildContext context) {
    final topAnim = CurvedAnimation(
      parent: screenAnim,
      curve: const Interval(0.08, 0.46, curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: Listenable.merge([screenAnim, pulse, percentileAnim]),
      builder: (context, _) {
        final glow = pulse.value;

        return Opacity(
          opacity: topAnim.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - topAnim.value)),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 5,
              children: [
                Text(
                  username,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: compact ? 27 : 31,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.8,
                    height: 1.0,
                  ),
                ),
                if (percentile.isNotEmpty) ...[
                  Text(
                    "•",
                    style: TextStyle(
                      fontSize: compact ? 18 : 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white24,
                      height: 1.0,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.045),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: percentileColor.withOpacity(0.22),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: percentileColor.withOpacity(0.06 + glow * 0.045),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: Text(
                      percentile,
                      style: TextStyle(
                        fontSize: compact ? 23 : 27,
                        fontWeight: FontWeight.w900,
                        color: percentileColor,
                        height: 1.0,
                        letterSpacing: -0.6,
                        shadows: [
                          Shadow(
                            color: percentileColor.withOpacity(0.18 + glow * 0.08),
                            blurRadius: 12 + glow * 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class SocialLiveStatsPanel extends StatelessWidget {
  final int following;
  final int followers;
  final int matches;
  final bool compact;
  final Animation<double> statsAnim;
  final VoidCallback onFollowing;
  final VoidCallback onFollowers;
  final VoidCallback onMatches;

  const SocialLiveStatsPanel({
    super.key,
    required this.following,
    required this.followers,
    required this.matches,
    required this.compact,
    required this.statsAnim,
    required this.onFollowing,
    required this.onFollowers,
    required this.onMatches,
  });

  @override
  Widget build(BuildContext context) {
    final reveal = CurvedAnimation(
      parent: statsAnim,
      curve: const Interval(0.10, 0.95, curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: statsAnim,
      builder: (context, _) {
        return Opacity(
          opacity: reveal.value,
          child: Transform.scale(
            scale: 0.96 + (0.04 * reveal.value),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: compact ? 8 : 10,
                horizontal: compact ? 8 : 12,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: SocialLivePalette.purple.withOpacity(0.48),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.050),
                    Colors.white.withOpacity(0.020),
                    SocialLivePalette.purple.withOpacity(0.035),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: SocialLivePalette.purple.withOpacity(0.11),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.24),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SocialLiveStatCard(
                      label: "Following",
                      value: following,
                      compact: compact,
                      onTap: onFollowing,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SocialLiveStatCard(
                      label: "Followers",
                      value: followers,
                      compact: compact,
                      onTap: onFollowers,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SocialLiveStatCard(
                      label: "Matches",
                      value: matches,
                      accent: SocialLivePalette.purple,
                      compact: compact,
                      onTap: onMatches,
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
}

class SocialLiveStatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color accent;
  final VoidCallback onTap;
  final bool compact;

  const SocialLiveStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.accent = Colors.white,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: EdgeInsets.symmetric(
          vertical: compact ? 9 : 12,
          horizontal: 4,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.040),
          border: Border.all(color: Colors.white.withOpacity(0.055)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (child, anim) {
                return FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(scale: anim, child: child),
                );
              },
              child: Text(
                "$value",
                key: ValueKey("$label$value"),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 18 : 21,
                  fontWeight: FontWeight.w900,
                  color: accent,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 10.5 : 12,
                fontWeight: FontWeight.w800,
                color: Colors.white70,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SocialLiveActions extends StatelessWidget {
  final Animation<double> pulse;
  final VoidCallback onEdit;
  final VoidCallback onAnalytics;
  final VoidCallback onMatches;

  const SocialLiveActions({
    super.key,
    required this.pulse,
    required this.onEdit,
    required this.onAnalytics,
    required this.onMatches,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SocialLiveButton(
            title: "Edit",
            icon: Icons.edit,
            color: SocialLivePalette.editColor,
            pulse: pulse,
            onTap: onEdit,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SocialLiveButton(
            title: "Analytics",
            icon: Icons.bar_chart,
            color: SocialLivePalette.analyticsColor,
            pulse: pulse,
            onTap: onAnalytics,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SocialLiveButton(
            title: "Matches",
            icon: Icons.favorite,
            color: SocialLivePalette.matchesColor,
            pulse: pulse,
            onTap: onMatches,
          ),
        ),
      ],
    );
  }
}

class SocialLiveButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Animation<double> pulse;
  final VoidCallback onTap;

  const SocialLiveButton({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.pulse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final glow = pulse.value;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            height: 47,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(1),
                  Color.lerp(color, Colors.black, 0.20)!,
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.045)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.14 + glow * 0.09),
                  blurRadius: 16 + glow * 6,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 19),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 13.2,
                    ),
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

class SocialLiveInfoBox extends StatelessWidget {
  final bool compact;
  final Animation<double> pulse;
  final String leftTitle;
  final String leftSubtitle;
  final String premiumTitle;
  final String premiumSubtitle;

  const SocialLiveInfoBox({
    super.key,
    required this.compact,
    required this.pulse,
    required this.leftTitle,
    required this.leftSubtitle,
    required this.premiumTitle,
    required this.premiumSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final glow = pulse.value;

        return ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 14 : 16,
                vertical: compact ? 12 : 14,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: SocialLivePalette.gold1.withOpacity(0.58),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    SocialLivePalette.gold2.withOpacity(0.060 + glow * 0.025),
                    Colors.white.withOpacity(0.020),
                    SocialLivePalette.purple.withOpacity(0.025),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: SocialLivePalette.gold1.withOpacity(0.08 + glow * 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _MiniInfoColumn(
                      title: leftTitle,
                      value: leftSubtitle,
                      titleColor: Colors.white,
                      valueColor: Colors.white70,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: compact ? 34 : 38,
                    color: Colors.white12,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniInfoColumn(
                      title: premiumTitle,
                      value: premiumSubtitle,
                      titleColor: Colors.white,
                      valueColor: Colors.white70,
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
}

class _MiniInfoColumn extends StatelessWidget {
  final String title;
  final String value;
  final Color titleColor;
  final Color valueColor;

  const _MiniInfoColumn({
    required this.title,
    required this.value,
    required this.titleColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class SocialLiveHowItWorksEntry extends StatelessWidget {
  final Animation<double> pulse;
  final VoidCallback onTap;

  const SocialLiveHowItWorksEntry({
    super.key,
    required this.pulse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, _) {
          final glow = pulse.value;

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: SocialLivePalette.gold2.withOpacity(0.22 + glow * 0.07),
              ),
              gradient: LinearGradient(
                colors: [
                  SocialLivePalette.gold2.withOpacity(0.06),
                  Colors.white.withOpacity(0.025),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: SocialLivePalette.gold2.withOpacity(0.07 + glow * 0.05),
                  blurRadius: 14 + glow * 5,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 29,
                  height: 29,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        SocialLivePalette.gold2,
                        SocialLivePalette.gold3,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: SocialLivePalette.gold2.withOpacity(0.22),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    size: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "SEE HOW SOCIAL WORKS 💥",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.8,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const Icon(
                  Icons.trending_flat_rounded,
                  size: 18,
                  color: SocialLivePalette.gold2,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SocialLiveBottomCta extends StatefulWidget {
  final bool compact;
  final bool locked;
  final String countdownText;
  final Animation<double> pulse;
  final VoidCallback onTap;

  const SocialLiveBottomCta({
    super.key,
    required this.compact,
    required this.locked,
    required this.countdownText,
    required this.pulse,
    required this.onTap,
  });

  @override
  State<SocialLiveBottomCta> createState() => _SocialLiveBottomCtaState();
}

class _SocialLiveBottomCtaState extends State<SocialLiveBottomCta>
    with SingleTickerProviderStateMixin {
  bool _tapLocked = false;

  late final AnimationController _press;

  @override
  void initState() {
    super.initState();

    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_tapLocked) return;

    setState(() {
      _tapLocked = true;
    });

    HapticFeedback.selectionClick();
    widget.onTap();

    await Future.delayed(const Duration(milliseconds: 850));

    if (!mounted) return;

    setState(() {
      _tapLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.locked
        ? widget.countdownText == "SYNC"
            ? "Syncing status"
            : "Next analysis"
        : "Analyze again";

    final String subtitle = widget.locked
        ? widget.countdownText == "SYNC"
            ? "Checking availability"
            : widget.countdownText
        : "Instant rescore";

    return Listener(
      onPointerDown: (_) => _press.forward(),
      onPointerUp: (_) => _press.reverse(),
      onPointerCancel: (_) => _press.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([widget.pulse, _press]),
        builder: (context, _) {
          final glow = widget.pulse.value;
          final scale = 1 - (_press.value * 0.018);

          return Transform.scale(
            scale: scale,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _handleTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    width: double.infinity,
                    height: widget.compact ? 62 : 68,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.locked
                            ? [
                                const Color(0xFF191A24).withOpacity(0.96),
                                const Color(0xFF231A35).withOpacity(0.94),
                                const Color(0xFF0B0E14).withOpacity(0.98),
                              ]
                            : const [
                                SocialLivePalette.gold3,
                                SocialLivePalette.gold2,
                                SocialLivePalette.purple,
                              ],
                      ),
                      border: Border.all(
                        color: widget.locked
                            ? Colors.white.withOpacity(0.095)
                            : SocialLivePalette.gold3.withOpacity(0.50),
                        width: 1.15,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.locked
                              ? SocialLivePalette.purple.withOpacity(
                                  0.12 + glow * 0.05,
                                )
                              : SocialLivePalette.gold2.withOpacity(
                                  0.22 + glow * 0.10,
                                ),
                          blurRadius: widget.locked ? 28 : 42,
                          offset: const Offset(0, 16),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.44),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: widget.compact ? 40 : 44,
                          height: widget.compact ? 40 : 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.locked
                                ? Colors.white.withOpacity(0.055)
                                : Colors.black.withOpacity(0.14),
                            border: Border.all(
                              color: widget.locked
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.12),
                            ),
                          ),
                          child: Icon(
                            widget.locked
                                ? Icons.lock_clock_rounded
                                : Icons.auto_awesome_rounded,
                            size: widget.compact ? 18 : 20,
                            color: widget.locked
                                ? SocialLivePalette.gold2
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: widget.locked
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: widget.compact ? 15.5 : 16.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.25,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: widget.locked
                                      ? Colors.white.withOpacity(0.55)
                                      : Colors.black.withOpacity(0.62),
                                  fontSize: widget.compact ? 11.5 : 12.2,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.05,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          widget.locked
                              ? Icons.workspace_premium_rounded
                              : Icons.arrow_forward_rounded,
                          size: widget.compact ? 20 : 22,
                          color: widget.locked
                              ? SocialLivePalette.gold2
                              : Colors.black,
                        ),
                      ],
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
}

class SocialLiveLoadingOverlay extends StatelessWidget {
  const SocialLiveLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SocialLivePalette.bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: SocialLivePalette.gold2.withOpacity(0.10),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: SocialLivePalette.gold2.withOpacity(0.18),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: SocialLivePalette.gold2,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "Going live...",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SocialSuggestedUsersDialog extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final String Function(Map<String, dynamic>) nameOf;
  final String Function(Map<String, dynamic>) imageOf;
  final String Function(Map<String, dynamic>) percentileOf;
  final VoidCallback onClose;
  final VoidCallback onExplore;
  final ValueChanged<Map<String, dynamic>> onUserTap;

  const SocialSuggestedUsersDialog({
    super.key,
    required this.users,
    required this.nameOf,
    required this.imageOf,
    required this.percentileOf,
    required this.onClose,
    required this.onExplore,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xF5070B12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: SocialLivePalette.gold2.withOpacity(0.16)),
        boxShadow: [
          BoxShadow(
            color: SocialLivePalette.gold2.withOpacity(0.10),
            blurRadius: 30,
          ),
          BoxShadow(
            color: SocialLivePalette.purple.withOpacity(0.12),
            blurRadius: 34,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Suggested users",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white.withOpacity(0.72),
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Find people close to your rank and start interacting.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.58),
              fontSize: 13.4,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          ...users.map(
            (u) => _SuggestedUserTile(
              name: nameOf(u),
              imageUrl: imageOf(u),
              percentile: percentileOf(u),
              onTap: () => onUserTap(u),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onExplore,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [
                    SocialLivePalette.gold2,
                    SocialLivePalette.gold3,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: SocialLivePalette.gold2.withOpacity(0.16),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  "EXPLORE USERS",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
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

class _SuggestedUserTile extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String percentile;
  final VoidCallback onTap;

  const _SuggestedUserTile({
    required this.name,
    required this.imageUrl,
    required this.percentile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21),
          color: Colors.white.withOpacity(0.045),
          border: Border.all(color: Colors.white.withOpacity(0.065)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(1.4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    SocialLivePalette.gold3,
                    SocialLivePalette.cyan,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: SocialLivePalette.gold3.withOpacity(0.10),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: ClipOval(
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallbackAvatar(),
                      )
                    : _fallbackAvatar(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    percentile,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: SocialLivePalette.cyan.withOpacity(0.92),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.38),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      color: const Color(0xFF090D14),
      child: const Icon(
        Icons.person_rounded,
        color: SocialLivePalette.gold3,
        size: 26,
      ),
    );
  }
}