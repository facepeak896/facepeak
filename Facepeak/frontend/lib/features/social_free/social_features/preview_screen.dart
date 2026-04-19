import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// SCREENS
import 'search_screen.dart';
import 'analytics_screen.dart';
import 'matches_screen.dart';
import 'edit_profile_screen.dart';
import 'profile_views_screen.dart';
import 'settings_screen.dart';
import 'social_api.dart';
import 'social_live_screen.dart';
import 'package:frontend/features/analysis/screens/app_state.dart';

class PreviewScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic> psl;

  const PreviewScreen({
    super.key,
    required this.user,
    required this.psl,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen>
    with TickerProviderStateMixin {
  final storage = const FlutterSecureStorage();

  late final AnimationController _pulse;
  late final AnimationController _scoreAnim;
  late final AnimationController _screenAnim;
  late final AnimationController _percentileAnim;
  late final AnimationController _shake;
  late final Animation<double> _screenOpacity;

  Map<String, dynamic> _user = {};
  Map<String, dynamic> _psl = {};

  int _displayScore = 0;

  static const Color bg = Color(0xFF0B0E14);

  static const Color gold1 = Color(0xFFB8922E);
  static const Color gold2 = Color(0xFFF0CF5A);
  static const Color gold3 = Color(0xFFFFEDB3);

  static const Color editColor = Color(0xFF111827);
  static const Color analyticsColor = Color(0xFF1F2937);
  static const Color matchesColor = Color(0xFF7C3AED);
  static const Color purple = Color(0xFF7C3AED);

  @override
  void initState() {
    super.initState();

    _user = {...widget.user};
    _psl = {...widget.psl};

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scoreAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _screenAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _percentileAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _screenOpacity = CurvedAnimation(
      parent: _screenAnim,
      curve: Curves.easeOut,
    );

    _screenAnim.forward();
    _percentileAnim.forward();

    _runScoreAnim();
  }

  void _runScoreAnim() {
    final target = _readInt(_psl["psl_score"]);

    _scoreAnim.addListener(() {
      if (!mounted) return;
      setState(() {
        _displayScore = (target * _scoreAnim.value).floor();
      });
    });

    _scoreAnim.forward();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _scoreAnim.dispose();
    _screenAnim.dispose();
    _percentileAnim.dispose();
    _shake.dispose();
    super.dispose();
  }

  int _readInt(dynamic v) => v is int ? v : int.tryParse("$v") ?? 0;

  double _readDouble(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse("$v") ?? 0.0;

  String _readString(dynamic v) => v?.toString() ?? "";

  String _username() {
    final username = _readString(_user["username"]).trim();
    return username.isEmpty ? "User" : username;
  }

  String _bioText() {
    final bio = _readString(_user["bio"]).trim();
    return bio.isEmpty ? "Ready to go live" : bio;
  }

  String _imagePath() {
    final local = _readString(_user["image"]).trim();
    if (local.isNotEmpty) return local;

    final profileUrl = _readString(_user["profile_image_url"]).trim();
    return profileUrl;
  }

  String _tierText() {
    final tier = _readString(_psl["tier"]).trim();
    return tier.isEmpty ? "Profile Ready" : tier;
  }

  String _percentileText() {
    final percentile = _psl["percentile"];
    if (percentile == null) return "";

    if (percentile is String) return percentile;
    if (percentile is num) return "Top ${percentile.toInt()}%";

    return percentile.toString();
  }

  int _percentileNumber() {
    final text = _percentileText().toLowerCase();
    final match = RegExp(r'(\d+)').firstMatch(text);

    if (match == null) return 0;
    return int.tryParse(match.group(1)!) ?? 0;
  }

  String _animatedPercentileText() {
    final target = _percentileNumber();
    final current =
        (target * _percentileAnim.value).floor().clamp(0, target);

    if (_percentileText().toLowerCase().contains("bottom")) {
      return "Bottom $current%";
    }

    if (target <= 0) return "Profile Ready";
    return "Top $current%";
  }

  int _pslScore() => _readInt(_psl["psl_score"]);

  double _confidence() => _readDouble(_psl["confidence"]);

  Color _heroPercentileColor() {
    final p = _percentileNumber();
    final score = _pslScore();

    if (p > 0 && p <= 15) return const Color(0xFF8FD8FF);
    if (p > 0 && p <= 30) return const Color(0xFFA9C8FF);
    if (score >= 7) return const Color(0xFFC8C7FF);
    if (score >= 5) return const Color(0xFFDCE8FF);
    return const Color(0xFFEFF5FF);
  }

  String _badgeText() {
    final tier = _tierText().toLowerCase();

    if (tier.contains("elite")) return "ELITE";
    if (tier.contains("chad")) return "CHAD";
    if (tier.contains("high")) return "HIGH";
    if (tier.contains("above")) return "STRONG";
    if (tier.contains("lower")) return "BUILD";
    if (tier.contains("need")) return "BUILD";
    return "READY";
  }

  String _rangeText() {
    final c = _confidence();

    double min;
    double max;

    if (c >= 0.9) {
      min = 0.1;
      max = 0.2;
    } else if (c >= 0.8) {
      min = 0.1;
      max = 0.25;
    } else if (c >= 0.7) {
      min = 0.1;
      max = 0.3;
    } else if (c >= 0.5) {
      min = 0.2;
      max = 0.4;
    } else {
      min = 0.3;
      max = 0.5;
    }

    return "+${min.toStringAsFixed(1)} → +${max.toStringAsFixed(1)} PSL";
  }

  int _nextTargetPercent() {
    final p = _percentileNumber();
    if (p <= 0) return 30;
    if (p <= 12) return (p - 2).clamp(5, 12);
    if (p <= 25) return (p - 4).clamp(10, 25);
    if (p <= 40) return (p - 6).clamp(15, 40);
    return (p - 8).clamp(20, 50);
  }

  String _leftInfoTitle() {
    final p = _percentileNumber();
    final next = _nextTargetPercent();

    if (p <= 0) return "Push higher this week 🔥";
    if (_percentileText().toLowerCase().contains("bottom")) {
      return "Break out fast this week 🔥";
    }
    return "Reach Top $next% 🔥";
  }

  String _leftInfoSubtitle() {
    final c = _confidence();

    if (c >= 0.85) return "Strong upside from this result";
    if (c >= 0.65) return "Clear momentum is possible";
    return "You still have room to rise";
  }

  String _premiumBlockTitle() {
    final score = _pslScore();
    if (score >= 7) return "AI Upgrade Plan";
    if (score >= 5) return "AI Game Plan";
    return "AI Coaching";
  }

  String _premiumBlockSubtitle() {
    final p = _percentileNumber();
    if (p > 0 && p <= 20) return "Sharpen your edge 🔒";
    if (p > 0 && p <= 40) return "Unlock exact next moves 🔒";
    return "Unlock exact plan 🔒";
  }

  String _unlockTitle() {
    final p = _percentileNumber();
    if (p > 0 && p <= 20) return "You are live-ready 🔥";
    if (p > 0 && p <= 40) return "You are ready to go live 🔥";
    return "You are ready to launch 🔥";
  }

  String _unlockSubtitle() {
    final badge = _badgeText();
    if (badge == "ELITE" || badge == "CHAD") {
      return "Go live to unlock visibility and let people start seeing you.";
    }
    if (badge == "HIGH" || badge == "STRONG") {
      return "Go live to unlock visibility, search, and match momentum.";
    }
    return "Go live to unlock visibility, search, and real traction.";
  }

  Map<String, dynamic> _buildPreviewPayload() {
    return {
      ..._user,
      "image": _imagePath(),
      "psl": {
        "psl_score": _pslScore(),
        "tier": _tierText(),
        "percentile": _percentileText(),
        "confidence": _confidence(),
        "weekly_potential_range": _rangeText(),
        "badge": _badgeText(),
      },
    };
  }

  void _triggerShake() {
    if (_shake.isAnimating) return;
    _shake.forward(from: 0);
  }

  double _shakeOffset() {
    final t = _shake.value;
    return math.sin(t * math.pi * 8) * 7 * (1 - t);
  }

  void _lockedTapFeedback() {
    _triggerShake();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF151922),
        content: Text(
          "Go live to unlock your profile 🔥",
          style: TextStyle(color: Colors.white),
        ),
        duration: Duration(milliseconds: 1150),
      ),
    );
  }

  Future<bool> _handleExit() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Leave preview?"),
        content: const Text(
          "Leaving now will close this preview and keep your current flow unfinished.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Stay"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Leave"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _pulse.stop();
      _scoreAnim.stop();
      _screenAnim.stop();
      _percentileAnim.stop();
      _shake.stop();

      if (!mounted) return false;
      Navigator.pop(context, {
        "action": "cancel_preview",
      });
    }

    return false;
  }

  Future<void> _handleCreateProfile() async {
  _pulse.stop();
  _scoreAnim.stop();
  _screenAnim.stop();
  _percentileAnim.stop();
  _shake.stop();

  final token = await AppState.getToken();

  if (token == null || token.isEmpty) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Missing token")),
    );
    return;
  }

  try {
    final res = await SocialApi.goLive(token: token);

    final backendUser =
        (res["user"] as Map<String, dynamic>?) ?? <String, dynamic>{};

    final backendPsl =
        (backendUser["psl"] as Map<String, dynamic>?) ?? <String, dynamic>{};

    final mergedUser = {
      ..._user,
      ...backendUser,
      "image": _imagePath(),
    };

    final mergedPsl = {
      ..._psl,
      ...backendPsl,
    };

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => SocialLiveScreen(
          user: mergedUser,
          psl: mergedPsl,
        ),
      ),
      (route) => false,
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleExit,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 760;
          final imageSize = compact ? 146.0 : 170.0;
          final glowSize = compact ? 192.0 : 216.0;
          final topGap = compact ? 8.0 : 12.0;
          final betweenGap = compact ? 8.0 : 10.0;
          final sectionGap = compact ? 9.0 : 11.0;

          return Scaffold(
            backgroundColor: bg,
            body: SafeArea(
              child: AnimatedBuilder(
                animation: Listenable.merge([_screenAnim, _shake]),
                builder: (context, child) {
                  final y = 18 * (1 - _screenAnim.value);
                  final shakeX = _shakeOffset();

                  return Transform.translate(
                    offset: Offset(shakeX, y),
                    child: Opacity(
                      opacity: _screenOpacity.value,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  child: Column(
                    children: [
                      _topBar(),
                      SizedBox(height: topGap),
                      _avatar(
                        imageSize: imageSize,
                        glowSize: glowSize,
                      ),
                      SizedBox(height: betweenGap),
                      _identityBlock(compact: compact),
                      SizedBox(height: sectionGap),
                      _stats(compact: compact),
                      SizedBox(height: compact ? 10 : 12),
                      _actions(),
                      SizedBox(height: sectionGap),
                      _infoBox(compact: compact),
                      const SizedBox(height: 6),
                      _unlockSection(compact: compact),
                      const Spacer(),
                      _bottomActions(compact: compact),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= TOP =================

  Widget _topBar() {
    return Row(
      children: [
        _topIcon(
          Icons.arrow_back_ios_new,
          _handleExit,
          size: 16,
        ),
        const Spacer(),
        _topIcon(
          Icons.remove_red_eye_outlined,
          null,
          size: 20,
          isDisabled: true,
        ),
        const SizedBox(width: 10),
        _topIcon(
          Icons.search_rounded,
          null,
          size: 20,
          isDisabled: true,
        ),
        const SizedBox(width: 10),
        _topIcon(
          Icons.favorite,
          null,
          size: 20,
          color: purple,
          isDisabled: true,
        ),
        const SizedBox(width: 10),
        _topIcon(
          Icons.menu,
          null,
          size: 20,
          isDisabled: true,
        ),
      ],
    );
  }

  Widget _topIcon(
    IconData icon,
    VoidCallback? onTap, {
    Color color = Colors.white,
    bool isDisabled = false,
    double size = 20,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? 0.45 : 1,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: size,
            color: color,
          ),
        ),
      ),
    );
  }

  // ================= AVATAR =================

  Widget _avatar({
    required double imageSize,
    required double glowSize,
  }) {
    final imagePath = _imagePath();
    final hasLocalImage = imagePath.isNotEmpty && !imagePath.startsWith("http");
    final hasNetworkImage =
        imagePath.isNotEmpty && imagePath.startsWith("http");

    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _screenAnim]),
      builder: (context, _) {
        final glow = _pulse.value;
        final reveal = Curves.easeOut.transform(_screenAnim.value);
        final scale = 0.962 + (0.038 * reveal);

        return Transform.scale(
          scale: scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: glowSize,
                height: glowSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(42),
                  boxShadow: [
                    BoxShadow(
                      color: gold2.withOpacity(0.18 + glow * 0.22),
                      blurRadius: 48 + glow * 18,
                      spreadRadius: 1.4,
                    ),
                    BoxShadow(
                      color: gold1.withOpacity(0.08 + glow * 0.06),
                      blurRadius: 90,
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Container(
                  width: imageSize,
                  height: imageSize,
                  color: Colors.black,
                  child: hasLocalImage
                      ? Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.person_rounded,
                              size: 72,
                              color: Colors.white38,
                            ),
                          ),
                        )
                      : hasNetworkImage
                          ? Image.network(
                              imagePath,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: gold2,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 72,
                                  color: Colors.white38,
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.person_rounded,
                                size: 72,
                                color: Colors.white38,
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

  // ================= IDENTITY =================

  Widget _identityBlock({required bool compact}) {
  final topAnim = CurvedAnimation(
    parent: _screenAnim,
    curve: const Interval(0.10, 0.50, curve: Curves.easeOut),
  );

  final percentileColor = _heroPercentileColor();

  return AnimatedBuilder(
    animation: Listenable.merge([_screenAnim, _pulse, _percentileAnim]),
    builder: (context, _) {
      final glow = _pulse.value;
      final percentile = _animatedPercentileText();

      return Column(
        children: [
          Opacity(
            opacity: topAnim.value,
            child: Transform.translate(
              offset: Offset(0, 8 * (1 - topAnim.value)),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    _username(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: compact ? 26 : 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  if (percentile.isNotEmpty) ...[
                    Text(
                      "•",
                      style: TextStyle(
                        fontSize: compact ? 18 : 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white24,
                        height: 1.0,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: percentileColor.withOpacity(0.18),
                        ),
                      ),
                      child: Text(
                        percentile,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: compact ? 24 : 28,
                          fontWeight: FontWeight.w900,
                          color: percentileColor,
                          height: 1.0,
                          shadows: [
                            Shadow(
                              color: percentileColor.withOpacity(
                                0.16 + glow * 0.10,
                              ),
                              blurRadius: 14 + glow * 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

  // ================= STATS =================

  Widget _stats({required bool compact}) {
    return GestureDetector(
      onTap: _lockedTapFeedback,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: compact ? 10 : 12,
          horizontal: compact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: purple.withOpacity(0.50)),
          color: Colors.white.withOpacity(0.025),
          boxShadow: [
            BoxShadow(
              color: purple.withOpacity(0.10),
              blurRadius: 22,
            ),
          ],
        ),
        child: Row(
          children: const [
            Expanded(
              child: _LockedStatCard(
                label: "Following",
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _LockedStatCard(
                label: "Followers",
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _LockedStatCard(
                label: "Matches",
                accent: purple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ACTIONS =================

  Widget _actions() {
    return AbsorbPointer(
      absorbing: true,
      child: Opacity(
        opacity: 0.82,
        child: Row(
          children: [
            Expanded(
              child: _btn(
                "Edit",
                Icons.edit,
                editColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _btn(
                "Analytics",
                Icons.bar_chart,
                analyticsColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _btn(
                "Matches",
                Icons.favorite,
                matchesColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(String t, IconData i, Color color) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glow = _pulse.value;

        return Container(
          height: 46,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.16 + glow * 0.14),
                blurRadius: 16 + glow * 8,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(i, color: Colors.white),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  t,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= INFO =================

  Widget _infoBox({required bool compact}) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glow = _pulse.value;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 16,
            vertical: compact ? 12 : 13,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: gold1.withOpacity(0.74)),
            color: Colors.white.withOpacity(0.02),
            boxShadow: [
              BoxShadow(
                color: gold1.withOpacity(0.09 + glow * 0.08),
                blurRadius: 18,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _miniInfoColumn(
                  _leftInfoTitle(),
                  _leftInfoSubtitle(),
                  Colors.white,
                  Colors.white70,
                ),
              ),
              Container(
                width: 1,
                height: compact ? 34 : 38,
                color: Colors.white12,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PreviewPremiumBlock(
                  title: _premiumBlockTitle(),
                  subtitle: _premiumBlockSubtitle(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _unlockSection({required bool compact}) {
  const unlockGold = Color(0xFFF3D058);

  Widget miniBullet(
    String text,
    IconData icon, {
    Color iconColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 11.8,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 5),
          Icon(
            icon,
            size: 12,
            color: iconColor,
          ),
        ],
      ),
    );
  }

  return Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(
      horizontal: 12,
      vertical: compact ? 8 : 9,
    ),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: unlockGold.withOpacity(0.22),
      ),
      color: Colors.white.withOpacity(0.02),
      boxShadow: [
        BoxShadow(
          color: unlockGold.withOpacity(0.05),
          blurRadius: 18,
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: unlockGold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(
            Icons.bolt_rounded,
            size: 16,
            color: unlockGold,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _unlockTitle(),
                style: const TextStyle(
                  fontSize: 12.6,
                  fontWeight: FontWeight.w900,
                  color: unlockGold,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Go live to unlock visibility.",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.8,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  miniBullet("Search", Icons.search_rounded),
                  miniBullet("Matches", Icons.favorite, iconColor: purple),
                  miniBullet("Visible", Icons.remove_red_eye_outlined),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _unlockBullet(
    IconData icon,
    String text, {
    Color iconColor = Colors.white,
  }) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 11,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11.8,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniInfoColumn(
    String title,
    String value,
    Color titleColor,
    Color valueColor,
  ) {
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

  // ================= CTA =================

  Widget _bottomActions({required bool compact}) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              await _handleExit();
            },
            child: Container(
              height: compact ? 52 : 54,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: const Center(
                child: Text(
                  "CANCEL",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final glow = _pulse.value;

              return GestureDetector(
                onTap: _handleCreateProfile,
                child: Container(
                  height: compact ? 52 : 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [gold2, gold3],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: gold2.withOpacity(0.46 + glow * 0.30),
                        blurRadius: 28 + glow * 12,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "GO LIVE NOW 🔥",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LockedStatCard extends StatelessWidget {
  final String label;
  final Color accent;

  const _LockedStatCard({
    required this.label,
    this.accent = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.035),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock_rounded,
            size: 18,
            color: accent.withOpacity(0.90),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white70,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPremiumBlock extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PreviewPremiumBlock({
    required this.title,
    required this.subtitle,
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
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}