import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:frontend/features/analysis/screens/app_state.dart';

import 'package:frontend/features/social_free/auth_api.dart';
import 'package:frontend/features/social_free/social_features/widgets/social_live_widgets.dart';

import 'social_api.dart';

// SCREENS
import 'search_screen.dart';
import 'search_main_screen.dart';
import 'analytics_screen.dart';
import 'matches_screen.dart';
import 'edit_profile_screen.dart';
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
  static const String _suggestedSeenKey = 'social_live_suggested_seen_v1';
  static const String _scoreAgainNextAtKey =
      'social_live_score_again_next_at_v1';

  late final AnimationController _pulse;
  late final AnimationController _screenAnim;
  late final AnimationController _percentileAnim;
  late final AnimationController _statsAnim;
  late final Animation<double> _screenOpacity;

  Timer? _scoreAgainTimer;
  DateTime? _scoreAgainNextAt;
  Duration _scoreAgainRemaining = Duration.zero;

  Map<String, dynamic> _user = {};
  Map<String, dynamic> _psl = {};

  bool _showHowItWorks = true;
  bool _suggestedPopupChecked = false;
  bool _refreshing = false;
  bool _cooldownReady = false;

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

    _loadHowItWorksSeen();
    _loadScoreAgainCooldown();
    _syncScoreAgainCooldownFromBackend();

    _screenAnim.forward();
    _percentileAnim.forward();
    _statsAnim.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowSuggestedPopup();
      _refreshMe();
    });
  }

  @override
  void dispose() {
    _scoreAgainTimer?.cancel();
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
    final localImage = _readString(_user["local_image_path"]).trim();

    if (localImage.isNotEmpty && File(localImage).existsSync()) {
      return localImage;
    }

    final image = _readString(_user["image"]).trim();
    final profileUrl = _readString(_user["profile_image_url"]).trim();
    final raw = image.isNotEmpty ? image : profileUrl;

    if (raw.isEmpty) return "";
    if (raw.startsWith("http://") || raw.startsWith("https://")) return raw;
    if (raw.startsWith("/storage/")) return "${SocialApi.baseUrl}$raw";

    return raw;
  }

  String _percentileText() {
    final percentile = _psl["percentile"];

    if (percentile is String && percentile.trim().isNotEmpty) {
      return percentile;
    }

    if (percentile is num && percentile > 0) {
      return "Top ${percentile.toInt()}%";
    }

    final saved = _user["reach_target_percentile"];
    if (saved is num && saved > 0) {
      return "Top ${saved.toInt()}%";
    }

    return "";
  }

  int _percentileNumber() {
    final saved = _user["reach_target_percentile"];

    if (saved is num && saved > 0) return saved.toInt();

    final percentile = _psl["percentile"];

    if (percentile is num && percentile > 0) return percentile.toInt();

    final text = _percentileText().toLowerCase();
    final match = RegExp(r'(\d+)').firstMatch(text);

    if (match == null) return 0;

    return int.tryParse(match.group(1)!) ?? 0;
  }

  String _animatedPercentileText() {
    final target = _percentileNumber();
    final current = (target * _percentileAnim.value).floor().clamp(0, target);

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

  Future<void> _refreshMe() async {
  if (_refreshing) return;

  _refreshing = true;

  try {
    final token = await AppState.getToken();
    if (token == null || token.isEmpty) return;

    final freshUser = await AuthApi.getMe(accessToken: token);

    if (!mounted) return;

    _applyFreshUser(freshUser);

    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    final freshUser2 = await AuthApi.getMe(accessToken: token);
    if (!mounted) return;

    _applyFreshUser(freshUser2);

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final freshUser3 = await AuthApi.getMe(accessToken: token);
    if (!mounted) return;

    _applyFreshUser(freshUser3);
  } catch (e) {
    debugPrint("❌ SOCIAL_LIVE refreshMe ERROR = $e");
  } finally {
    _refreshing = false;
  }
  }
  void _applyFreshUser(Map<String, dynamic> freshUser) {
  final freshPsl =
      ((freshUser["psl"] as Map?)?.cast<String, dynamic>()) ??
          <String, dynamic>{};

  final stats =
      ((freshUser["stats"] as Map?)?.cast<String, dynamic>()) ??
          <String, dynamic>{};

  final followers = freshUser["followers"] ??
      freshUser["followers_count"] ??
      freshUser["followersCount"] ??
      stats["followers"] ??
      stats["followers_count"] ??
      stats["followersCount"] ??
      _user["followers"] ??
      0;

  final following = freshUser["following"] ??
      freshUser["following_count"] ??
      freshUser["followingCount"] ??
      stats["following"] ??
      stats["following_count"] ??
      stats["followingCount"] ??
      _user["following"] ??
      0;

  final matches = freshUser["matches"] ??
      freshUser["matches_count"] ??
      freshUser["matchesCount"] ??
      stats["matches"] ??
      stats["matches_count"] ??
      stats["matchesCount"] ??
      _user["matches"] ??
      0;

  setState(() {
    _user = {
      ..._user,
      ...freshUser,
      "followers": followers,
      "following": following,
      "matches": matches,
    };

    if (freshPsl.isNotEmpty) {
      _psl = {
        ..._psl,
        ...freshPsl,
      };
    }
  });

  AppState.setSocialSnapshot(user: _user, psl: _psl);
}

  Future<void> _onPullRefresh() async {
    HapticFeedback.selectionClick();
    await _refreshMe();
    await _syncScoreAgainCooldownFromBackend();
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
          "followers": result["followers"] ??
              result["followers_count"] ??
              _user["followers"] ??
              0,
          "following": result["following"] ??
              result["following_count"] ??
              _user["following"] ??
              0,
          "matches": result["matches"] ??
              result["matches_count"] ??
              _user["matches"] ??
              0,
        };

        if (result["psl"] is Map<String, dynamic>) {
          _psl = {
            ..._psl,
            ...(result["psl"] as Map<String, dynamic>),
          };
        }
      });

      await AppState.setSocialSnapshot(user: _user, psl: _psl);
    }

    await _refreshMe();
  }

  Future<void> _loadHowItWorksSeen() async {
    final seen = await storage.read(key: _howItWorksSeenKey);

    if (!mounted) return;

    setState(() {
      _showHowItWorks = seen != "1";
    });
  }

  Future<void> _loadScoreAgainCooldown() async {
  final raw = await storage.read(key: _scoreAgainNextAtKey);

  if (raw == null || raw.isEmpty) {
    if (!mounted) return;
    setState(() => _cooldownReady = true);
    return;
  }

  final dt = DateTime.tryParse(raw)?.toLocal();

  if (dt == null || DateTime.now().isAfter(dt)) {
    await storage.delete(key: _scoreAgainNextAtKey);

    if (!mounted) return;
    setState(() {
      _scoreAgainNextAt = null;
      _scoreAgainRemaining = Duration.zero;
      _cooldownReady = true;
    });

    return;
  }

  _startScoreAgainTimer(dt);

  if (!mounted) return;
  setState(() => _cooldownReady = true);
}

  void _startScoreAgainTimer(DateTime nextAt) {
  _scoreAgainTimer?.cancel();

  setState(() {
    _scoreAgainNextAt = nextAt;
    _scoreAgainRemaining = nextAt.difference(DateTime.now());
  });

  _scoreAgainTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
    if (!mounted || _scoreAgainNextAt == null) return;

    final remaining = _scoreAgainNextAt!.difference(DateTime.now());

    if (remaining <= Duration.zero) {
      _scoreAgainTimer?.cancel();

      await storage.delete(key: _scoreAgainNextAtKey);

      await _syncScoreAgainCooldownFromBackend();
      await _refreshMe();

      if (!mounted) return;

      setState(() {
        _scoreAgainNextAt = null;
        _scoreAgainRemaining = Duration.zero;
      });

      return;
    }

    setState(() {
      _scoreAgainRemaining = remaining;
    });
  });
}

  String _scoreAgainCountdownText() {
    final d = _scoreAgainRemaining;

    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);

    if (h > 0) return "${h}H ${m.toString().padLeft(2, '0')}M";
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  DateTime? _cooldownFromResult(dynamic result) {
    if (result is! Map) return null;

    final raw = result["next_available_at"] ??
        result["cooldown_until"] ??
        result["retry_after_at"] ??
        result["score_again_next_at"];

    if (raw == null) return null;

    return DateTime.tryParse(raw.toString())?.toLocal();
  }

  Future<void> _saveAndStartCooldown(DateTime nextAt) async {
    await storage.write(
      key: _scoreAgainNextAtKey,
      value: nextAt.toUtc().toIso8601String(),
    );

    if (!mounted) return;
    _startScoreAgainTimer(nextAt);
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

      await AppState.setSocialSnapshot(user: _user, psl: _psl);
    }

    await _refreshMe();
  }

  Future<void> _openHowItWorks() async {
    await storage.write(key: _howItWorksSeenKey, value: "1");

    if (!mounted) return;

    setState(() {
      _showHowItWorks = false;
    });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SocialExplainerScreen(),
      ),
    );
  }

  Future<void> _syncScoreAgainCooldownFromBackend() async {
  try {
    final token = await AppState.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() => _cooldownReady = true);
      return;
    }

    final data = await SocialApi.getSocialRescoreStatus(token: token);

    final raw = data["next_available_at"];
    if (raw == null || raw.toString().isEmpty) {
      await storage.delete(key: _scoreAgainNextAtKey);

      if (!mounted) return;

      setState(() {
        _scoreAgainNextAt = null;
        _scoreAgainRemaining = Duration.zero;
        _cooldownReady = true;
      });

      return;
    }

    final nextAt = DateTime.tryParse(raw.toString())?.toLocal();
    if (nextAt == null) {
      if (!mounted) return;
      setState(() => _cooldownReady = true);
      return;
    }

    if (DateTime.now().isBefore(nextAt)) {
      await _saveAndStartCooldown(nextAt);
    }

    if (!mounted) return;
    setState(() => _cooldownReady = true);
  } catch (e) {
    debugPrint("❌ SOCIAL_LIVE cooldown sync ERROR = $e");

    if (!mounted) return;
    setState(() => _cooldownReady = true);
  }
}

  void _openUpgradeToPremium() {
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "Upgrade to Premium to analyze again instantly.",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: purple,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _openScoreAgain() async {
  if (!_cooldownReady) return;

  final locked =
      _scoreAgainNextAt != null && DateTime.now().isBefore(_scoreAgainNextAt!);

  if (locked) {
    _openUpgradeToPremium();
    return;
  }

  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CreatePostScreen(
        user: _user,
      ),
    ),
  );

  final cooldownAt = _cooldownFromResult(result);

  if (cooldownAt != null && DateTime.now().isBefore(cooldownAt)) {
    await _saveAndStartCooldown(cooldownAt);
  }

  await _refreshMe();
}

  Future<void> _maybeShowSuggestedPopup() async {
    if (_suggestedPopupChecked) return;
    _suggestedPopupChecked = true;

    final seen = await storage.read(key: _suggestedSeenKey);
    if (seen == "1") return;

    await Future.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;

    try {
      final token = await AppState.getToken();
      if (token == null || token.isEmpty) return;

      final page = await SocialApi.getSocialUsersPage(
        token: token,
        limit: 8,
        offset: 0,
      );

      final myId = _readInt(_user["id"] ?? _user["user_id"]);

      final users = ((page["users"] ?? page["items"]) as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((u) => _readInt(u["id"] ?? u["user_id"]) != myId)
          .take(3)
          .toList();

      if (!mounted || users.isEmpty) return;

      await showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.76),
        builder: (dialogContext) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: SocialSuggestedUsersDialog(
              users: users,
              nameOf: _suggestedName,
              imageOf: _suggestedImage,
              percentileOf: _suggestedPercentile,
              onClose: () async {
                await storage.write(key: _suggestedSeenKey, value: "1");
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              onExplore: () async {
                await storage.write(key: _suggestedSeenKey, value: "1");
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                _push(const SearchScreen());
              },
              onUserTap: (user) async {
                await storage.write(key: _suggestedSeenKey, value: "1");
                if (dialogContext.mounted) Navigator.pop(dialogContext);

                final id = _readInt(user["id"] ?? user["user_id"]);
                if (id > 0) {
                  _push(SearchMainScreen(userId: id));
                }
              },
            ),
          );
        },
      );
    } catch (e) {
      debugPrint("❌ SOCIAL_LIVE suggested popup ERROR = $e");
    }
  }

  String _suggestedName(Map<String, dynamic> user) {
    final raw = (user["username"] ?? user["display_name"] ?? user["name"] ?? "")
        .toString()
        .trim();

    if (raw.isEmpty) return "User";
    return raw;
  }

  String _suggestedImage(Map<String, dynamic> user) {
    final raw = (user["profile_image_url"] ??
            user["image_url"] ??
            user["image"] ??
            user["local_image_path"] ??
            "")
        .toString()
        .trim();

    if (raw.isEmpty) return "";
    if (raw.startsWith("http://") || raw.startsWith("https://")) return raw;
    if (raw.startsWith("/")) return "${SocialApi.baseUrl}$raw";
    return raw;
  }

  String _suggestedPercentile(Map<String, dynamic> user) {
    final p = user["percentile"] ??
        user["reach_target_percentile"] ??
        user["top_percentile"];

    if (p is String && p.trim().isNotEmpty) {
      if (p.toLowerCase().contains("top") ||
          p.toLowerCase().contains("bottom")) {
        return p.trim();
      }
    }

    if (p is num && p > 0) return "Top ${p.toInt()}%";

    final text = p?.toString().toLowerCase().trim() ?? "";
    final match = RegExp(r'(\d+)').firstMatch(text);

    if (match == null) return "Live profile";
    return "Top ${match.group(1)}%";
  }

  @override
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final media = MediaQuery.of(context);
      final bottomSafe = media.padding.bottom;

      final compact = constraints.maxHeight < 760;
      final tiny = constraints.maxHeight < 690;
      final ultraTiny = constraints.maxHeight < 640;

      final imageSize = ultraTiny ? 108.0 : tiny ? 122.0 : compact ? 136.0 : 158.0;
      final glowSize = ultraTiny ? 132.0 : tiny ? 148.0 : compact ? 164.0 : 190.0;

      final topGap = ultraTiny ? 4.0 : tiny ? 6.0 : compact ? 8.0 : 10.0;
      final betweenGap = ultraTiny ? 5.0 : tiny ? 7.0 : compact ? 8.0 : 10.0;
      final sectionGap = ultraTiny ? 7.0 : tiny ? 8.0 : compact ? 9.0 : 11.0;

      final userId = _readInt(_user["id"] ?? _user["user_id"]);

      final locked = !_cooldownReady ||
          (_scoreAgainNextAt != null &&
              DateTime.now().isBefore(_scoreAgainNextAt!));

      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              const SocialLiveBackground(),

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
                child: RefreshIndicator(
                  color: gold2,
                  backgroundColor: const Color(0xFF111827),
                  displacement: 34,
                  onRefresh: _onPullRefresh,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: EdgeInsets.only(
                      bottom: bottomSafe + (ultraTiny ? 92 : tiny ? 98 : 108),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight -
                            media.padding.top -
                            media.padding.bottom,
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          ultraTiny ? 16 : 20,
                          ultraTiny ? 6 : 10,
                          ultraTiny ? 16 : 20,
                          0,
                        ),
                        child: Column(
                          children: [
                            SocialLiveTopBar(
                              onSettings: () => _push(const SettingsScreen()),
                            ),
                            SizedBox(height: topGap),

                            SocialLiveAvatar(
                              imagePath: _imagePath(),
                              imageSize: imageSize,
                              glowSize: glowSize,
                              pulse: _pulse,
                              screenAnim: _screenAnim,
                            ),

                            SizedBox(height: betweenGap),

                            SocialLiveIdentityBlock(
                              username: _username(),
                              percentile: _animatedPercentileText(),
                              percentileColor: _heroPercentileColor(),
                              compact: compact || ultraTiny,
                              pulse: _pulse,
                              screenAnim: _screenAnim,
                              percentileAnim: _percentileAnim,
                            ),

                            SizedBox(height: sectionGap),

                            SocialLiveStatsPanel(
                              followers: _readInt(_user["followers"]),
                              following: _readInt(_user["following"]),
                              matches: _readInt(_user["matches"]),
                              compact: compact || ultraTiny,
                              statsAnim: _statsAnim,
                              onFollowers: () =>
                                  _push(FollowersScreen(userId: userId)),
                              onFollowing: () =>
                                  _push(FollowingScreen(userId: userId)),
                              onMatches: () => _push(const MatchesScreen()),
                            ),

                            SizedBox(height: ultraTiny ? 7 : compact ? 8 : 10),

                            SocialLiveActions(
                              pulse: _pulse,
                              onEdit: _openEdit,
                              onAnalytics: () => _push(const AnalyticsScreen()),
                              onMatches: () => _push(const MatchesScreen()),
                            ),

                            SizedBox(height: sectionGap),

                            SocialLiveInfoBox(
                              compact: compact || ultraTiny,
                              pulse: _pulse,
                              leftTitle: _leftInfoTitle(),
                              leftSubtitle: _leftInfoSubtitle(),
                              premiumTitle: _premiumBlockTitle(),
                              premiumSubtitle: _premiumBlockSubtitle(),
                            ),

                            if (_showHowItWorks) ...[
                              const SizedBox(height: 8),
                              SocialLiveHowItWorksEntry(
                                pulse: _pulse,
                                onTap: _openHowItWorks,
                              ),
                            ],

                            SizedBox(height: ultraTiny ? 10 : compact ? 12 : 18),

                            SocialLiveBottomCta(
                              compact: compact || ultraTiny,
                              locked: locked,
                              countdownText: !_cooldownReady
                                  ? "SYNC"
                                  : _scoreAgainCountdownText(),
                              pulse: _pulse,
                              onTap: _openScoreAgain,
                            ),
                          ],
                        ),
                      ),
                    ),
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
                      child: const SocialLiveLoadingOverlay(),
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
}