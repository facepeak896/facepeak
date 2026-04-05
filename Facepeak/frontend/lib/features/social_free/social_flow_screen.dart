import 'package:flutter/material.dart';
import 'package:frontend/features/analysis/screens/app_state.dart';

// AUTH
import 'login_screen.dart';

// SOCIAL HOME
import 'package:frontend/features/social_free/social_features/social_home_screen.dart';

// API
import 'auth_api.dart';

class SocialFlow extends StatefulWidget {
  const SocialFlow({super.key});

  @override
  State<SocialFlow> createState() => _SocialFlowState();
}

class _SocialFlowState extends State<SocialFlow> {
  bool? _loggedIn;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// 🔥 INIT
  Future<void> _bootstrap() async {
    final token = await AppState.getToken();

    if (!mounted) return;

    if (token == null || token.isEmpty) {
      setState(() => _loggedIn = false);
      return;
    }

    try {
      final user = await AuthApi.getMe(token);

      if (!mounted) return;

      setState(() {
        _user = user;
        _loggedIn = true;
      });
    } catch (_) {
      await AppState.logout();

      if (!mounted) return;
      setState(() => _loggedIn = false);
    }
  }

  /// 🔥 LOGIN SUCCESS
  Future<void> _onAuthSuccess(String token) async {
    await AppState.setToken(token);

    if (!mounted) return;

    // instant UI switch
    setState(() {
      _loggedIn = true;
      _user = {};
    });

    // background fetch
    try {
      final user = await AuthApi.getMe(token);

      if (!mounted) return;

      setState(() {
        _user = user;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        /// 🔥 MAIN CONTENT (ISTO KO PRIJE)
        if (_loggedIn == null)
          const SizedBox() // ništa, jer overlay pokriva
        else if (_loggedIn == false)
          AuthScreen(
            onSuccess: _onAuthSuccess,
          )
        else
          SocialHomeFreeScreen(
            user: _user ?? {},
          ),

        /// 🔥 ELITE LOADING OVERLAY
        if (_loggedIn == null)
          const EliteLoadingOverlay(
            title: "Connecting...",
            subtitle: "Updating your profile",
          ),
      ],
    );
  }
}







// =======================================================
// 🔥 ELITE LOADING (U ISTOM FILEU)
// =======================================================

class EliteLoadingOverlay extends StatefulWidget {
  final String title;
  final String subtitle;

  const EliteLoadingOverlay({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  State<EliteLoadingOverlay> createState() => _EliteLoadingOverlayState();
}

class _EliteLoadingOverlayState extends State<EliteLoadingOverlay>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF06070B),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // 🔵 ROTATING RING
              SizedBox(
                width: 100,
                height: 100,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Transform.rotate(
                      angle: _controller.value * 2 * 3.1416,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 3,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF92A5FF),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // 🔥 TITLE
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 6),

              // 🧠 SUBTITLE
              Text(
                widget.subtitle,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}