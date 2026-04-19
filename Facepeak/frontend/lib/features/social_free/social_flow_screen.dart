import 'package:flutter/material.dart';
import 'package:frontend/features/analysis/screens/app_state.dart';

// SOCIAL
import 'package:frontend/features/social_free/social_features/social_home_screen.dart';
import 'package:frontend/features/social_free/social_features/social_live_screen.dart';

// API
import 'auth_api.dart';
import 'package:frontend/features/social_free/social_features/social_api.dart';

// GOOGLE AUTH
import 'package:frontend/features/social_free/social_features/google_auth_service.dart';

class SocialFlow extends StatefulWidget {
  const SocialFlow({super.key});

  @override
  State<SocialFlow> createState() => _SocialFlowState();
}

class _SocialFlowState extends State<SocialFlow> {
  bool _loading = true;
  bool _loggedIn = false;
  bool _isLive = false;
  Map<String, dynamic> _user = {};
  Map<String, dynamic> _psl = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });

    final token = await AppState.getToken();

    if (!mounted) return;

    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _loggedIn = false;
        _isLive = false;
        _user = {};
        _psl = {};
      });
      return;
    }

    try {
      final user = await AuthApi.getMe(accessToken: token);
      final isLive = await SocialApi.getLiveStatus(token: token);

      final psl = ((user["psl"] as Map?)?.cast<String, dynamic>()) ?? {};

      if (!mounted) return;

      setState(() {
        _loading = false;
        _loggedIn = true;
        _isLive = isLive;
        _user = user;
        _psl = psl;
      });
    } catch (_) {
      await AppState.logout();

      if (!mounted) return;

      setState(() {
        _loading = false;
        _loggedIn = false;
        _isLive = false;
        _user = {};
        _psl = {};
      });
    }
  }

  // 🔥 GOOGLE LOGIN → BACKEND ACCESS + REFRESH
  Future<void> _handleGoogleLogin() async {
    final userCredential = await GoogleAuthService.signInWithGoogle();
    if (userCredential == null) return;

    final user = userCredential.user;
    if (user == null) return;

    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) return;

    final authData = await AuthApi.googleLogin(idToken: idToken);

    final accessToken = authData["access_token"]?.toString();
    final refreshToken = authData["refresh_token"]?.toString();

    if (accessToken == null || accessToken.isEmpty) return;

    await AppState.setToken(accessToken);

    // kasnije ako dodaš refresh storage:
    // if (refreshToken != null && refreshToken.isNotEmpty) {
    //   await AppState.setRefreshToken(refreshToken);
    // }

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _SocialFlowLoadingScreen();
    }

    if (!_loggedIn) {
      return SocialHomeFreeScreen(
        user: const {},
        onRequireAuth: _handleGoogleLogin,
      );
    }

    if (_isLive) {
      return SocialLiveScreen(
        user: _user,
        psl: _psl,
      );
    }

    return SocialHomeFreeScreen(
      user: _user,
      onRequireAuth: null,
    );
  }
}

class _SocialFlowLoadingScreen extends StatelessWidget {
  const _SocialFlowLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF06070B),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}