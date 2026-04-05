import 'dart:async';
import 'package:flutter/material.dart';

class AppIntroScreen extends StatefulWidget {
  const AppIntroScreen({super.key});

  @override
  State<AppIntroScreen> createState() => _AppIntroScreenState();
}

class _AppIntroScreenState extends State<AppIntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  static const Color bg = Color(0xFF05070D);
  static const Color gold = Color(0xFFF5C518);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

    // ⏱️ ukupno vrijeme introa
    Timer(const Duration(milliseconds: 1800), _goNext);
  }

  void _goNext() {
    if (!mounted) return;

    // ⛔️ OVDJE ĆEMO KASNIJE IĆI NA HOME
    // za sad samo Navigator.pop ili placeholder
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔥 LOGO MARK (krug)
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: gold.withOpacity(0.85),
                      width: 2.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: gold.withOpacity(0.25),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // 🏷️ APP NAME
                const Text(
                  "FACEPEAK",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),

                const SizedBox(height: 10),

                // ✨ PREMIUM TAGLINE
                Text(
                  "See your peak.",
                  style: TextStyle(
                    color: gold.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
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