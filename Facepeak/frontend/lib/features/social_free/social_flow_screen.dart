import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/features/analysis/screens/app_state.dart';

import 'package:frontend/features/social_free/social_features/social_home_screen.dart';
import 'package:frontend/features/social_free/social_features/social_live_screen.dart';
import 'package:frontend/features/social_free/social_auth_gate_screen.dart';

import 'auth_api.dart';
import 'package:frontend/features/social_free/social_features/social_api.dart';
import 'package:frontend/features/social_free/social_features/social_auth_guard.dart';

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
  bool _disposed = false;

  Map<String, dynamic> _user = {};
  Map<String, dynamic> _psl = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted || _disposed) return;
    setState(fn);
  }

  String _safeNameFrom(Map<String, dynamic>? user) {
    if (user == null) return "User";

    final raw = (user["username"] ??
            user["display_name"] ??
            user["name"] ??
            "")
        .toString()
        .trim();

    final cleaned = raw.replaceAll(RegExp(r'[^a-zA-Z]'), '');

    if (cleaned.isEmpty) return "User";

    final cut = cleaned.length > 8 ? cleaned.substring(0, 8) : cleaned;

    return cut[0].toUpperCase() + cut.substring(1).toLowerCase();
  }

  Map<String, dynamic> _normalizeUser(Map<String, dynamic>? user) {
    final base = user ?? <String, dynamic>{};
    final safeName = _safeNameFrom(base);

    return {
      ...base,
      "username": safeName,
      "display_name": safeName,
    };
  }

  Map<String, dynamic> _fallbackUser() {
    return {
      "username": "User",
      "display_name": "User",
      "image": "",
      "profile_image_url": "",
      "local_image_path": "",
      "followers": 0,
      "following": 0,
      "matches": 0,
      "profile_views": 0,
      "is_live": true,
    };
  }

  Map<String, dynamic> _fallbackPsl() {
    return {
      "psl_score": 0,
      "tier": "",
      "percentile": "",
      "confidence": 0.0,
      "weekly_potential_range": "",
    };
  }

  Future<void> _load() async {
  debugPrint("❌❌❌ SOCIAL_FLOW _load START");

  final localLive = await AppState.isSocialLive();
  final cachedUser = await AppState.getSocialUserSnapshot();
  final cachedPsl = await AppState.getSocialPslSnapshot();

  debugPrint("❌❌❌ SOCIAL_FLOW localLive = $localLive");
  debugPrint("❌❌❌ SOCIAL_FLOW cachedUser exists = ${cachedUser != null}");
  debugPrint("❌❌❌ SOCIAL_FLOW cachedPsl exists = ${cachedPsl != null}");

  if (!mounted || _disposed) return;

  if (localLive) {
    final safeCachedUser = _normalizeUser(cachedUser ?? _fallbackUser());

    _safeSetState(() {
      _loading = false;
      _loggedIn = true;
      _isLive = true;
      _user = safeCachedUser;
      _psl = cachedPsl ?? _fallbackPsl();
    });

    await AppState.setSocialSnapshot(
      user: safeCachedUser,
      psl: cachedPsl ?? _fallbackPsl(),
    );

    debugPrint("❌❌❌ SOCIAL_FLOW showing cached/live UI instantly");

    _refreshBackendSilently();
    return;
  }

  try {
    final token = await SocialAuthGuard.ensureBackendToken();

    if (token == null || token.isEmpty) {
      debugPrint("❌❌❌ SOCIAL_FLOW no valid token -> AuthGate");

      _safeSetState(() {
        _loading = false;
        _loggedIn = false;
        _isLive = false;
        _user = {};
        _psl = {};
      });

      return;
    }

    final user = await AuthApi.getMe(accessToken: token);
    final isLive = await SocialApi.getLiveStatus(token: token);

    debugPrint("❌❌❌ SOCIAL_FLOW backend isLive = $isLive");

    final safeUser = _normalizeUser(user);

    final psl =
        ((user["psl"] as Map?)?.cast<String, dynamic>()) ?? {};

    await AppState.setSocialLive(isLive);

    if (isLive) {
      await AppState.setSocialSnapshot(
        user: safeUser,
        psl: psl,
      );
    }

    if (!mounted || _disposed) return;

    _safeSetState(() {
      _loading = false;
      _loggedIn = true;
      _isLive = isLive;
      _user = safeUser;
      _psl = psl;
    });

    debugPrint("❌❌❌ SOCIAL_FLOW backend SUCCESS");
  } catch (e, s) {
    debugPrint("❌❌❌ SOCIAL_FLOW backend FAIL = $e");
    debugPrint("❌❌❌ SOCIAL_FLOW STACK = $s");

    if (!mounted || _disposed) return;

    _safeSetState(() {
      _loading = false;
      _loggedIn = false;
      _isLive = false;
      _user = {};
      _psl = {};
    });
  }
}

  Future<void> _refreshBackendSilently() async {
    debugPrint("❌❌❌ SOCIAL_FLOW silent refresh START");

    try {
      final token = await AppState.getToken();

      if (token == null || token.isEmpty) {
        debugPrint("❌❌❌ SOCIAL_FLOW no valid token -> keep cache");
        return;
      }

      final user = await AuthApi.getMe(accessToken: token);
      final isLive = await SocialApi.getLiveStatus(token: token);

      debugPrint("❌❌❌ SOCIAL_FLOW silent isLive = $isLive");

      final safeUser = _normalizeUser(user);
      final psl = ((user["psl"] as Map?)?.cast<String, dynamic>()) ?? {};

      await AppState.setSocialSnapshot(user: safeUser, psl: psl);

      await AppState.setSocialLive(isLive);

      if (!mounted || _disposed) return;

      _safeSetState(() {
        _loading = false;
        _loggedIn = true;
        _isLive = isLive;
        _user = safeUser;
        _psl = psl;
      });

      debugPrint("❌❌❌ SOCIAL_FLOW silent refresh SUCCESS");
    } catch (e, s) {
      debugPrint("❌❌❌ SOCIAL_FLOW silent refresh FAIL = $e");
      debugPrint("❌❌❌ SOCIAL_FLOW STACK = $s");
      debugPrint("❌❌❌ SOCIAL_FLOW keeping cached UI");
    }
  }

  Future<void> _handleGoogleLogin() async {
    debugPrint("❌❌❌ SOCIAL_FLOW Google login START");

    final userCredential = await GoogleAuthService.signInWithGoogle();
    if (userCredential == null) {
      debugPrint("❌❌❌ SOCIAL_FLOW Google login cancelled/null");
      return;
    }

    final user = userCredential.user;
    if (user == null) {
      debugPrint("❌❌❌ SOCIAL_FLOW Firebase user null");
      return;
    }

    final idToken = await user.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      debugPrint("❌❌❌ SOCIAL_FLOW idToken empty");
      return;
    }

    final authData = await AuthApi.googleLogin(idToken: idToken);

    final accessToken = authData["access_token"]?.toString();
    final refreshToken = authData["refresh_token"]?.toString();

    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      debugPrint("❌❌❌ SOCIAL_FLOW backend tokens empty");
      return;
    }

    await AppState.setTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    debugPrint("❌❌❌ SOCIAL_FLOW tokens saved, reloading");

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _SocialFlowLoadingScreen();
    }

    if (_isLive) {
      return SocialLiveScreen(
        user: _user,
        psl: _psl,
      );
    }

    if (!_loggedIn) {
      return SocialAuthGateScreen(
        onContinueWithGoogle: _handleGoogleLogin,
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