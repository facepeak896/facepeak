import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// SCREENS
import 'search_screen.dart';
import 'analytics_screen.dart';
import 'matches_screen.dart';
import 'edit_profile_screen.dart';
import 'profile_views_screen.dart';
import 'settings_screen.dart';
import 'create_post_entry_screen.dart';
import 'followers_screen.dart';
import 'following_screen.dart';
import 'social_explainer_screen.dart';
class SocialLiveScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic> psl;

  const SocialLiveScreen({
    super.key,
    required this.user,
    required this.psl,
  });

  @override
  State<SocialLiveScreen> createState() => _SocialLiveScreenState();
}

class _SocialLiveScreenState extends State<SocialLiveScreen>
    with TickerProviderStateMixin {
  final storage = const FlutterSecureStorage();

  static const String _howItWorksSeenKey = 'social_live_how_it_works_seen';

  late final AnimationController _pulse;
  late final AnimationController _screenAnim;
  late final AnimationController _percentileAnim;
  late final AnimationController _statsAnim;
  late final Animation<double> _screenOpacity;

  Map<String, dynamic> _user = {};
  Map<String, dynamic> _psl = {};

  bool _showHowItWorks = true;

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
    _showHowItWorks = true;

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _screenAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    _percentileAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _statsAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _screenOpacity = CurvedAnimation(
      parent: _screenAnim,
      curve: Curves.easeOut,
    );

    

    _screenAnim.forward();
    _percentileAnim.forward();
    _statsAnim.forward();
  }

  

  @override
  void dispose() {
    _pulse.dispose();
    _screenAnim.dispose();
    _percentileAnim.dispose();
    _statsAnim.dispose();
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

  String _imagePath() {
  final image = _readString(_user["image"]).trim();
  if (image.isNotEmpty) return image;

  final profileUrl = _readString(_user["profile_image_url"]).trim();
  if (profileUrl.isNotEmpty) return profileUrl;

  return "";
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

    if (target <= 0) return "Top 50%";
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

    if (p <= 0) return "Reach Top 30% 🔥";
    if (_percentileText().toLowerCase().contains("bottom")) {
      return "Break out fast 🔥";
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

  Future<void> _push(Widget screen) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _user = {
          ..._user,
          ...result,
        };

        if (result["psl"] is Map<String, dynamic>) {
          _psl = {
            ..._psl,
            ...(result["psl"] as Map<String, dynamic>),
          };
        }
      });
    }
  }

  Future<void> _openEdit() async {
  final updated = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EditProfileScreen(user: _user),
    ),
  );

  if (updated != null && mounted) {
    setState(() {
      _user = {
        ..._user,
        ...updated,
      };
    });
  }
}

Future<void> _openHowItWorks() async {
  if (!mounted) return;

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const SocialExplainerScreen(),
    ),
  );
}

  
  
  

  
  Future<void> _openScoreAgain() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(
          user: _user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 760;
        final imageSize = compact ? 146.0 : 170.0;
        final glowSize = compact ? 192.0 : 216.0;
        final topGap = compact ? 8.0 : 12.0;
        final betweenGap = compact ? 8.0 : 10.0;
        final sectionGap = compact ? 8.0 : 10.0;

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _screenAnim,
                  builder: (context, child) {
                    final y = 18 * (1 - _screenAnim.value);

                    return Transform.translate(
                      offset: Offset(0, y),
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
                        SizedBox(height: compact ? 8 : 10),
                        _actions(),
                        SizedBox(height: sectionGap),
                        _infoBox(compact: compact),
                        if (_showHowItWorks) ...[
                          const SizedBox(height: 8),
                          _howItWorksEntry(),
                        ],
                        const Spacer(),
                        _bottomCta(compact: compact),
                      ],
                    ),
                  ),
                ),

                IgnorePointer(
                  ignoring: true,
                  child: AnimatedBuilder(
                    animation: _screenAnim,
                    builder: (context, _) {
                      final overlayOpacity =
                          (1 - Curves.easeOut.transform(_screenAnim.value))
                              .clamp(0.0, 1.0);

                      if (overlayOpacity <= 0.01) {
                        return const SizedBox.shrink();
                      }

                      return Opacity(
                        opacity: overlayOpacity,
                        child: Container(
                          color: bg,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: gold2.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: gold2.withOpacity(0.28),
                                        blurRadius: 24,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.bolt_rounded,
                                    color: gold2,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  "Going live...",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
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
              ],
            ),
          ),
        );
      },
    );
  }
  

  // ================= TOP =================

  Widget _topBar() {
    return Row(
      children: [
        _topIcon(
          Icons.arrow_back_ios_new,
          () => Navigator.maybePop(context),
          size: 16,
        ),
        const Spacer(),
        _topIcon(
          Icons.remove_red_eye_outlined,
          () => _push(const ProfileViewsScreen()),
          size: 20,
        ),
        const SizedBox(width: 10),
        _topIcon(
          Icons.search_rounded,
          () => _push(const SearchScreen()),
          size: 20,
        ),
        const SizedBox(width: 10),
        _topIcon(
          Icons.favorite,
          () => _push(const MatchesScreen()),
          size: 20,
          color: purple,
        ),
        const SizedBox(width: 10),
        _topIcon(
          Icons.menu,
          () => _push(const SettingsScreen()),
          size: 20,
        ),
      ],
    );
  }

  Widget _topIcon(
    IconData icon,
    VoidCallback onTap, {
    Color color = Colors.white,
    double size = 20,
  }) {
    return GestureDetector(
      onTap: onTap,
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
    );
  }

  // ================= AVATAR =================

  Widget _avatar({
  required double imageSize,
  required double glowSize,
}) {
  final imagePath = _imagePath();
  final hasImage = imagePath.isNotEmpty;
  final isNetworkImage =
      hasImage &&
      (imagePath.startsWith("http://") || imagePath.startsWith("https://"));
  final isLocalImage = hasImage && !isNetworkImage;

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
                    color: gold2.withOpacity(0.18 + glow * 0.24),
                    blurRadius: 52 + glow * 18,
                    spreadRadius: 1.6,
                  ),
                  BoxShadow(
                    color: gold1.withOpacity(0.10 + glow * 0.06),
                    blurRadius: 96,
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
                child: isLocalImage
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
                    : isNetworkImage
                        ? Image.network(
                            imagePath,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
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
    curve: const Interval(0.08, 0.46, curve: Curves.easeOut),
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
              offset: Offset(0, 10 * (1 - topAnim.value)),
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
                        boxShadow: [
                          BoxShadow(
                            color: percentileColor.withOpacity(
                              0.05 + glow * 0.04,
                            ),
                            blurRadius: 14,
                          ),
                        ],
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
  final reveal = CurvedAnimation(
    parent: _statsAnim,
    curve: const Interval(0.10, 0.95, curve: Curves.easeOut),
  );

  return AnimatedBuilder(
    animation: _statsAnim,
    builder: (context, _) {
      return Opacity(
        opacity: reveal.value,
        child: Transform.scale(
          scale: 0.96 + (0.04 * reveal.value),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: compact ? 9 : 10,
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
              children: [
                Expanded(
                  child: _LiveStatCard(
                    label: "Following",
                    value: _readInt(_user["following"]),
                    onTap: () => _push(const FollowingScreen()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LiveStatCard(
                    label: "Followers",
                    value: _readInt(_user["followers"]),
                    onTap: () => _push(const FollowersScreen()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LiveStatCard(
                    label: "Matches",
                    value: _readInt(_user["matches"]),
                    accent: purple,
                    onTap: () => _push(const MatchesScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
  // ================= ACTIONS =================

  Widget _actions() {
    return Row(
      children: [
        Expanded(
          child: _btn(
            "Edit",
            Icons.edit,
            editColor,
            _openEdit,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _btn(
            "Analytics",
            Icons.bar_chart,
            analyticsColor,
            () => _push(const AnalyticsScreen()),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _btn(
            "Matches",
            Icons.favorite,
            matchesColor,
            () => _push(const MatchesScreen()),
          ),
        ),
      ],
    );
  }

  Widget _btn(
    String t,
    IconData i,
    Color color,
    VoidCallback onTap,
  ) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glow = _pulse.value;

        return GestureDetector(
          onTap: onTap,
          child: Container(
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

Widget _howItWorksEntry() {
  return GestureDetector(
    onTap: _openHowItWorks,
    child: AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glow = _pulse.value;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: gold2.withOpacity(0.24 + glow * 0.10),
            ),
            color: Colors.white.withOpacity(0.025),
            boxShadow: [
              BoxShadow(
                color: gold2.withOpacity(0.08 + glow * 0.08),
                blurRadius: 16 + glow * 8,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [gold2, gold3],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gold2.withOpacity(0.35),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  size: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "SEE HOW SOCIAL WORKS 💥",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.8,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const Icon(
                Icons.trending_flat_rounded,
                size: 18,
                color: gold2,
              ),
            ],
          ),
        );
      },
    ),
  );
}

  // ================= CTA =================

  Widget _bottomCta({required bool compact}) {
  return AnimatedBuilder(
    animation: _pulse,
    builder: (context, _) {
      final glow = _pulse.value;

      return GestureDetector(
        onTap: _openScoreAgain,
        child: Container(
          width: double.infinity,
          height: compact ? 50 : 52,
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
              "GET YOUR SCORE AGAIN",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14.2,
                color: Colors.black,
              ),
            ),
          ),
        ),
      );
    },
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
}

class _LiveStatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color accent;
  final VoidCallback onTap;

  const _LiveStatCard({
    required this.label,
    required this.value,
    required this.onTap,
    this.accent = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(0.035),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "$value",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: accent, 
                height: 1.0,
              ),
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

class _HowSocialWorksScreen extends StatelessWidget {
  const _HowSocialWorksScreen();

  static const Color bg = Color(0xFF0B0E14);
  static const Color gold2 = Color(0xFFF0CF5A);
  static const Color purple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text(
          "How social works",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          children: [
            _HowCard(
              icon: Icons.search_rounded,
              iconColor: Colors.white,
              title: "Search",
              text: "People can now find your profile through search.",
            ),
            const SizedBox(height: 12),
            _HowCard(
              icon: Icons.favorite,
              iconColor: purple,
              title: "Matches",
              text: "Your profile is now active for matches and interaction.",
            ),
            const SizedBox(height: 12),
            _HowCard(
              icon: Icons.remove_red_eye_outlined,
              iconColor: Colors.white,
              title: "Visibility",
              text: "You are now visible inside the social part of the app.",
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: gold2.withOpacity(0.35)),
                color: Colors.white.withOpacity(0.03),
              ),
              child: const Text(
                "The better your score, the stronger your social reach can become.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HowCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String text;

  const _HowCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 12.8,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}