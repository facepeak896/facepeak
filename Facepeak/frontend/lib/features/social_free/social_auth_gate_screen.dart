import 'dart:ui';
import 'package:flutter/material.dart';

class SocialAuthGateScreen extends StatefulWidget {
  final Future<void> Function() onContinueWithGoogle;

  const SocialAuthGateScreen({
    super.key,
    required this.onContinueWithGoogle,
  });

  @override
  State<SocialAuthGateScreen> createState() => _SocialAuthGateScreenState();
}

class _SocialAuthGateScreenState extends State<SocialAuthGateScreen>
    with TickerProviderStateMixin {
  bool _loading = false;

  late final AnimationController _fade;
  late final AnimationController _pulse;
  late final Animation<double> _opacity;

  static const Color bg = Color(0xFF05070D);
  static const Color bg2 = Color(0xFF0B1020);
  static const Color gold = Color(0xFFFFC34D);
  static const Color gold2 = Color(0xFFFFD978);
  static const Color panel = Color(0xCC0B1220);

  @override
  void initState() {
    super.initState();

    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _opacity = CurvedAnimation(
      parent: _fade,
      curve: Curves.easeOut,
    );

    _fade.forward();
  }

  @override
  void dispose() {
    _fade.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      await widget.onContinueWithGoogle();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Google sign in failed. Please try again."),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;

    // Ako user cancel-a Google popup, SocialFlow neće otići dalje.
    // Zato vraćamo button normalno i ostajemo na ovom screenu.
    setState(() => _loading = false);
  }

  @override
Widget build(BuildContext context) {
  final media = MediaQuery.of(context);
  final bottom = media.padding.bottom;
  final compact = media.size.height < 760;

  return PopScope(
    canPop: false,
    child: Scaffold(
      backgroundColor: bg,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bg, bg2, bg],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: _backgroundFx()),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      22,
                      compact ? 18 : 28,
                      22,
                      26 + bottom,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: FadeTransition(
                        opacity: _opacity,
                        child: Column(
                          children: [
                            SizedBox(height: compact ? 18 : 34),
                            _heroIcon(),
                            const SizedBox(height: 30),
                            const Text(
                              "Unlock Social",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.4,
                                height: 0.95,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Continue with Google to create your live profile, see your rank, and unlock matches.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.64),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 28),
                            _featureRow(
                              Icons.verified_rounded,
                              "Secure profile sync",
                            ),
                            const SizedBox(height: 10),
                            _featureRow(
                              Icons.auto_graph_rounded,
                              "Rank, percentile & progress",
                            ),
                            const SizedBox(height: 10),
                            _featureRow(
                              Icons.favorite_rounded,
                              "Matches, followers & visibility",
                            ),
                            SizedBox(height: compact ? 34 : 54),
                            _googleButton(),
                            const SizedBox(height: 14),
                            Text(
                              "Google sign-in is required to use Social.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.42),
                                fontSize: 12.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_loading)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      color: Colors.black.withOpacity(0.42),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
  Widget _backgroundFx() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final p = _pulse.value;

        return Stack(
          children: [
            Positioned(
              top: -120,
              left: -100,
              right: -100,
              child: Container(
                height: 320,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      gold.withOpacity(0.06 + p * 0.035),
                      gold.withOpacity(0.015),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -140,
              left: -90,
              right: -90,
              child: Container(
                height: 360,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      gold2.withOpacity(0.055 + p * 0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _heroIcon() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final p = _pulse.value;

        return Container(
          width: 118,
          height: 118,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gold2.withOpacity(0.22),
                gold.withOpacity(0.10),
                Colors.white.withOpacity(0.025),
              ],
            ),
            border: Border.all(
              color: gold.withOpacity(0.28),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: gold.withOpacity(0.18 + p * 0.12),
                blurRadius: 34 + p * 18,
              ),
            ],
          ),
          child: const Icon(
            Icons.bolt_rounded,
            color: gold2,
            size: 58,
          ),
        );
      },
    );
  }

  Widget _featureRow(IconData icon, String text) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: gold2, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _googleButton() {
    return GestureDetector(
      onTap: _loading ? null : _continue,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: _loading ? 0.72 : 1,
        child: Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: gold.withOpacity(0.18),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.black,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "G",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Continue with Google",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.1,
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