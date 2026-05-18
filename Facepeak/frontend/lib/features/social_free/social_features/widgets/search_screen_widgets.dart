import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SearchEliteUserCard extends StatefulWidget {
  final int index;
  final int rank;
  final String name;
  final String image;
  final String followersText;
  final String percentile;
  final Color percentileColor;
  final int percentileNumber;
  final Animation<double> pulse;
  final String baseUrl;
  final VoidCallback onTap;

  const SearchEliteUserCard({
    super.key,
    required this.index,
    required this.rank,
    required this.name,
    required this.image,
    required this.followersText,
    required this.percentile,
    required this.percentileColor,
    required this.percentileNumber,
    required this.pulse,
    required this.baseUrl,
    required this.onTap,
  });

  @override
  State<SearchEliteUserCard> createState() => _SearchEliteUserCardState();
}

class _SearchEliteUserCardState extends State<SearchEliteUserCard> {
  bool _down = false;

  static const Color bg = Color(0xFF04050A);
  static const Color card = Color(0xFF0B1020);
  static const Color card2 = Color(0xFF111827);

  static const Color purple = Color(0xFF7B4DFF);
  static const Color purpleSoft = Color(0xFF9F7CFF);

  static const Color gold = Color(0xFFFFCC66);
  static const Color goldSoft = Color(0xFFFFE2A8);

  static const Color white = Color(0xFFF8FAFC);
  static const Color muted = Color(0xFF94A3B8);

  bool get _isFirst => widget.rank == 1;
  bool get _topThree => widget.rank > 0 && widget.rank <= 3;
  bool get _elite => widget.percentileNumber <= 15;

  Color get _accent {
    if (_isFirst) return gold;
    return purpleSoft;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(
        milliseconds: 220 + widget.index.clamp(0, 8) * 28,
      ),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) {
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - v)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) {
          HapticFeedback.selectionClick();
          setState(() => _down = true);
        },
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        child: AnimatedScale(
          scale: _down ? 0.972 : 1,
          duration: const Duration(milliseconds: 115),
          curve: Curves.easeOutCubic,
          child: AnimatedBuilder(
            animation: widget.pulse,
            builder: (_, __) {
              final wave = (widget.pulse.value + widget.index * 0.08) % 1;
              final breathe = math.sin(wave * math.pi);

              final glowOpacity = _isFirst
                  ? 0.18 + breathe * 0.06
                  : 0.085 + breathe * 0.025;

              return Container(
                margin: const EdgeInsets.only(bottom: 11),
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _accent.withOpacity(_isFirst ? 0.34 : 0.18),
                      purple.withOpacity(0.13),
                      Colors.white.withOpacity(0.035),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withOpacity(glowOpacity),
                      blurRadius: _isFirst ? 28 : 22,
                      spreadRadius: -8,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.38),
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      height: 92,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            card2.withOpacity(0.96),
                            card.withOpacity(0.98),
                            bg.withOpacity(0.98),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.055),
                        ),
                      ),
                      child: Row(
                        children: [
                          _avatar(breathe),
                          const SizedBox(width: 12),
                          Expanded(child: _textBlock(breathe)),
                          const SizedBox(width: 8),
                          _openButton(breathe),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _avatar(double breathe) {
    return Container(
      width: 58,
      height: 58,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            _accent,
            _isFirst ? goldSoft : purpleSoft,
            _accent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(
              _isFirst ? 0.22 + breathe * 0.08 : 0.14 + breathe * 0.04,
            ),
            blurRadius: _isFirst ? 18 : 14,
          ),
        ],
      ),
      child: ClipOval(
        child: _avatarImage(),
      ),
    );
  }

  Widget _avatarImage() {
    final image = widget.image.trim();

    if (image.isEmpty) return _avatarFallback();

    if (image.startsWith("http://") || image.startsWith("https://")) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _avatarFallback(),
      );
    }

    if (image.startsWith("/")) {
      return Image.network(
        "${widget.baseUrl}$image",
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _avatarFallback(),
      );
    }

    final file = File(image);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _avatarFallback(),
      );
    }

    return _avatarFallback();
  }

  Widget _avatarFallback() {
    return Container(
      color: card,
      alignment: Alignment.center,
      child: Text(
        widget.name.isNotEmpty ? widget.name[0].toUpperCase() : "U",
        style: TextStyle(
          color: _isFirst ? goldSoft : purpleSoft,
          fontSize: 23,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _textBlock(double breathe) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _rankPill(),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                widget.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.45,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Text(
              widget.percentile,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _isFirst ? gold : widget.percentileColor,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.25,
                shadows: [
                  Shadow(
                    color: (_isFirst ? gold : widget.percentileColor)
                        .withOpacity(0.12 + breathe * 0.06),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: muted.withOpacity(0.42),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.followersText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: muted.withOpacity(0.82),
                  fontSize: 12.7,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _rankPill() {
    final rank = widget.rank;
    final label = rank > 0 ? "#$rank" : "#—";

    return Container(
      height: 25,
      constraints: const BoxConstraints(minWidth: 43),
      padding: const EdgeInsets.symmetric(horizontal: 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: _isFirst
            ? const LinearGradient(colors: [gold, goldSoft])
            : LinearGradient(
                colors: [
                  purpleSoft.withOpacity(0.18),
                  purple.withOpacity(0.10),
                ],
              ),
        border: Border.all(
          color: _isFirst
              ? goldSoft.withOpacity(0.55)
              : purpleSoft.withOpacity(0.24),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _isFirst ? Colors.black : goldSoft.withOpacity(0.92),
          fontSize: 12.2,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.15,
        ),
      ),
    );
  }

  Widget _openButton(double breathe) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _accent.withOpacity(_isFirst ? 0.17 : 0.11),
        border: Border.all(
          color: _accent.withOpacity(_isFirst ? 0.35 : 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(
              _isFirst ? 0.15 + breathe * 0.05 : 0.08 + breathe * 0.03,
            ),
            blurRadius: 12,
          ),
        ],
      ),
      child: Icon(
        Icons.chevron_right_rounded,
        color: _isFirst ? goldSoft : Colors.white.withOpacity(0.82),
        size: 27,
      ),
    );
  }
}