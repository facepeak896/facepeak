import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'analysis_capture_screen.dart';

class CreatePostScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const CreatePostScreen({
    super.key,
    required this.user,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _slide;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
    );

    _slide = Tween<double>(begin: 16, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _glow = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    HapticFeedback.heavyImpact();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalysisCaptureSimple(
          user: widget.user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070C),
      body: SafeArea(
        child: Stack(
          children: [
            const _CreatePostBackground(),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Opacity(
                  opacity: _fade.value,
                  child: Transform.translate(
                    offset: Offset(0, _slide.value),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          _topBar(),
                          const Spacer(),

                          AnimatedBuilder(
                            animation: _glow,
                            builder: (context, _) {
                              return Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFFFEDB0),
                                      Color(0xFFFFD86B),
                                      Color(0xFFF2C344),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD86B)
                                          .withOpacity(0.30 * _glow.value),
                                      blurRadius: 42,
                                      spreadRadius: 3,
                                      offset: const Offset(0, 14),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.workspace_premium_rounded,
                                  color: Colors.black,
                                  size: 42,
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 28),

                          const Text(
                            "Get your real score",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 41,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.6,
                              height: 0.95,
                            ),
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            "See where you really rank",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFFFE08A),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              height: 1.1,
                            ),
                          ),

                          const SizedBox(height: 28),

                          _middleCard(),

                          const SizedBox(height: 16),

                          _goldStrip(),

                          const Spacer(),

                          _ctaButton(),

                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.07),
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0xFFFFD86B).withOpacity(0.26),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD86B).withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Text(
            "REAL ONLY",
            style: TextStyle(
              color: Color(0xFFFFE08A),
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _middleCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(
              color: const Color(0xFFFFD86B).withOpacity(0.24),
              width: 1.15,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD86B).withOpacity(0.10),
                blurRadius: 34,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            children: [
              _compactRow(
                icon: Icons.verified_user_outlined,
                title: "Real photos only",
              ),
              const SizedBox(height: 14),
              _compactRow(
                icon: Icons.camera_alt_outlined,
                title: "You confirm your camera shot",
              ),
              const SizedBox(height: 14),
              _compactRow(
                icon: Icons.edit_outlined,
                title: "Change photo later in Edit",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _goldStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD86B).withOpacity(0.16),
            const Color(0xFFFFD86B).withOpacity(0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFFD86B).withOpacity(0.24),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shield_rounded,
            color: Color(0xFFFFE08A),
            size: 18,
          ),
          SizedBox(width: 10),
          Text(
            "Everyone here is verified",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.3,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ctaButton() {
    return GestureDetector(
      onTapDown: (_) => HapticFeedback.selectionClick(),
      onTap: _continue,
      child: Container(
        width: double.infinity,
        height: 69,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFEDB0),
              Color(0xFFFFD86B),
              Color(0xFFF2C344),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD86B).withOpacity(0.35),
              blurRadius: 36,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bolt_rounded,
              color: Colors.black,
              size: 21,
            ),
            SizedBox(width: 10),
            Text(
              "See my score",
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactRow({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFFFE08A),
            size: 19,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15.8,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _CreatePostBackground extends StatelessWidget {
  const _CreatePostBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: const Color(0xFF05070C)),
        ),
        Positioned(
          top: -120,
          left: -150,
          child: Container(
            width: 330,
            height: 330,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00C2FF).withOpacity(0.08),
                  blurRadius: 160,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 20,
          right: -145,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF2D55).withOpacity(0.10),
                  blurRadius: 165,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -70,
          left: 15,
          right: 15,
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD86B).withOpacity(0.16),
                  blurRadius: 135,
                  spreadRadius: 6,
                ),
              ],
            ),
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
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.28),
                ],
                stops: const [0.0, 0.26, 0.72, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}