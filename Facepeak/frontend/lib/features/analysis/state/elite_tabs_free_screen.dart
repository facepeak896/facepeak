import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BottomTabBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChange;

  const BottomTabBar({
    super.key,
    required this.currentIndex,
    required this.onTabChange,
  });

  void _go(int index) {
    if (index == currentIndex) {
      HapticFeedback.selectionClick();
      return;
    }

    HapticFeedback.mediumImpact();
    onTabChange(index);
  }

  Widget _tab(IconData icon, int index) {
    final active = index == currentIndex;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _go(index),
        onTapDown: (_) => HapticFeedback.lightImpact(),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1, end: active ? 1.12 : 1),
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Icon(
              icon,
              size: 25,
              color: active
                  ? const Color(0xFFE8C76A) // 💎 refined gold
                  : Colors.white30,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final tabWidth = width / 4;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
          child: Container(
            height: 74,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),

              // 🔥 GLASS BASE
              color: const Color(0xFF050505).withOpacity(0.88),

              // 🔥 FRAME (KEY DIFFERENCE)
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
                width: 1,
              ),

              boxShadow: [

                // 🔥 DEPTH
                BoxShadow(
                  color: Colors.black.withOpacity(0.95),
                  blurRadius: 50,
                  offset: const Offset(0, 25),
                ),

                // 🔥 OUTER GOLD AMBIENT (VERY SUBTLE)
                BoxShadow(
                  color: const Color(0xFFE8C76A).withOpacity(0.06),
                  blurRadius: 100,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              children: [

                /// 🔥 TOP INNER LIGHT LINE (premium glass effect)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1.2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                /// 🔥 LIQUID INDICATOR (ULTRA CLEAN)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  bottom: 10,
                  left: tabWidth * currentIndex + tabWidth / 2 - 16,
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFE8C76A),
                          Color(0xFFFFF2B0),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE8C76A).withOpacity(0.7),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                /// 🔥 TABS
                SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      _tab(Icons.home_rounded, 0),
                      _tab(Icons.chat_bubble_rounded, 1),
                      _tab(Icons.favorite_rounded, 2),
                      _tab(Icons.person_rounded, 3),
                    ],
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