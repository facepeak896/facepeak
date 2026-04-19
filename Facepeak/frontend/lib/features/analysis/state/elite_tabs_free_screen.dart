import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BottomTabBarElite extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChange;

  const BottomTabBarElite({
    super.key,
    required this.currentIndex,
    required this.onTabChange,
  });

  static const Color _bg = Color(0xFF05070D);
  static const Color _goldLight = Color(0xFFF8EFCB);
  static const Color _gold = Color(0xFFE8C76A);
  static const Color _goldDeep = Color(0xFFC3922E);

  void _go(int index) {
    if (index == currentIndex) {
      HapticFeedback.selectionClick();
      return;
    }

    HapticFeedback.mediumImpact();
    onTabChange(index);
  }

  IconData _iconFor(int index) {
    switch (index) {
      case 0:
        return Icons.home_outlined;
      case 1:
        return Icons.chat_bubble_outline_rounded;
      case 2:
        return Icons.favorite_border_rounded;
      case 3:
        return Icons.person_outline_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  Widget _tab(int index) {
    final active = index == currentIndex;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _go(index),
        onTapDown: (_) => HapticFeedback.lightImpact(),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1, end: active ? 1.08 : 1),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (active)
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _gold.withOpacity(0.16),
                          _goldDeep.withOpacity(0.07),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                Icon(
                  _iconFor(index),
                  size: active ? 30 : 27,
                  color: active
                      ? _goldLight
                      : Colors.white.withOpacity(0.38),
                  shadows: active
                      ? [
                          Shadow(
                            color: _goldDeep.withOpacity(0.45),
                            blurRadius: 10,
                          ),
                          Shadow(
                            color: _gold.withOpacity(0.26),
                            blurRadius: 16,
                          ),
                        ]
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final bottomInset = media.padding.bottom;
    final tabWidth = width / 4;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: _bg,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return SizedBox(
      width: double.infinity,
      height: 74 + bottomInset, // background layer + system nav area
      child: Stack(
        children: [
          // FULL-WIDTH BACKGROUND THAT MERGES WITH ANDROID NAV BAR
          Positioned.fill(
            child: Container(
              color: _bg,
            ),
          ),

          // TOP SEPARATOR / GLASS FEEL
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 1.0,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // GOLD AMBIENT STRIP
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _gold.withOpacity(0.07),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ACTUAL TAB CONTENT, SITS ABOVE SYSTEM NAV BUTTONS
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset > 0 ? bottomInset : 10,
            child: SizedBox(
              height: 74,
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    bottom: 8,
                    left: (tabWidth * currentIndex) + (tabWidth / 2) - 15,
                    child: Container(
                      width: 30,
                      height: 4.5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          colors: [
                            _goldDeep,
                            _gold,
                            _goldLight,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _gold.withOpacity(0.68),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      _tab(0),
                      _tab(1),
                      _tab(2),
                      _tab(3),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}