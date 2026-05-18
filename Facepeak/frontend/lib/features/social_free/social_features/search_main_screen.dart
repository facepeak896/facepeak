import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/features/analysis/screens/app_state.dart';

import 'social_api.dart';
import 'social_profile_api.dart';
import 'package:frontend/features/social_free/services/social_follow_service.dart';
import 'package:frontend/features/social_free/services/social_match_service.dart';
import 'package:frontend/features/social_free/services/social_message_service.dart';
import 'package:frontend/features/social_free/helpers/social_action_state_helper.dart';

class SearchMainScreen extends StatefulWidget {
  final int userId;

  const SearchMainScreen({
    super.key,
    required this.userId,
  });

  @override
  State<SearchMainScreen> createState() => _SearchMainScreenState();
}

class _SearchMainScreenState extends State<SearchMainScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;
  String? _premiumText;

  late final AnimationController _enterCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _premiumCtrl;
  late final Animation<double> _fade;

  static const Color bg = Color(0xFF02050A);
  static const Color bg2 = Color(0xFF07111A);
  static const Color panel = Color(0xCC0A101B);

  static const Color gold = Color(0xFFFFC34D);
  static const Color gold2 = Color(0xFFFFD978);
  static const Color gold3 = Color(0xFFFFE7A8);
  static const Color purple = Color(0xFF7C3AED);

  @override
  void initState() {
    super.initState();

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 440),
    );

    _premiumCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _fade = CurvedAnimation(
      parent: _enterCtrl,
      curve: Curves.easeOutCubic,
    );

    _loadUser();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _pulseCtrl.dispose();
    _shakeCtrl.dispose();
    _premiumCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final token = await AppState.getToken();

      if (token == null || token.isEmpty) {
        throw Exception("NO_TOKEN");
      }

      final user = await SocialProfileApi.getUserById(
        token: token,
        userId: widget.userId,
      );

      if (!mounted) return;

      setState(() {
        _user = user;
        _loading = false;
        _error = null;
      });

      _enterCtrl.forward();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = "Failed to load profile";
      });
    }
  }

  bool get _isMe => _user?["is_me"] == true;

  bool get _matchesLocked => _user?["matches_locked"] == true;
  bool get _isBlocked {
  return _user?["is_blocked"] == true ||
      _user?["blocked"] == true ||
      _user?["blocked_by_me"] == true ||
      _user?["viewer_blocked_user"] == true;
}

  bool get _canFollow {
  final state = SocialActionStateHelper.follow(_user);
  debugPrint(
    "❌ SEARCH_MAIN _canFollow enabled=${state.enabled} label=${state.label} visual=${state.visualState}",
  );
  return state.enabled;
}
bool get _canMatch {
  final state = SocialActionStateHelper.match(_user);
  debugPrint(
    "❌ SEARCH_MAIN _canMatch enabled=${state.enabled} label=${state.label} visual=${state.visualState}",
  );
  return state.enabled;
}

bool get _canDm {
  final state = SocialActionStateHelper.message(_user);
  debugPrint(
    "❌ SEARCH_MAIN _canDm enabled=${state.enabled} label=${state.label} visual=${state.visualState}",
  );
  return state.enabled;
}


  String _username() {
    final raw = _user?["username"]?.toString().trim() ?? "";
    if (raw.isEmpty) return "User";
    return raw;
  }
  String get _followLabel {
  return SocialActionStateHelper.follow(_user).label;
}

String get _matchLabel {
  return SocialActionStateHelper.match(_user).label;
}

String get _dmLabel {
  return SocialActionStateHelper.message(_user).label;
}

  String _img() {
    if (_user == null) return "";

    final raw = (_user!["profile_image_url"] ??
            _user!["image"] ??
            _user!["local_image_path"] ??
            "")
        .toString()
        .trim();

    if (raw.isEmpty) return "";
    if (raw.startsWith("http://") || raw.startsWith("https://")) return raw;
    if (raw.startsWith("/")) return "${SocialApi.baseUrl}$raw";
    return raw;
  }

  int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? "") ?? 0;
  }

  int? _percentileNumber() {
    final p = _user?["percentile"] ??
        _user?["reach_target_percentile"] ??
        _user?["top_percentile"];

    if (p is num && p > 0) return p.toInt().clamp(1, 99);

    final text = p?.toString().toLowerCase().trim() ?? "";
    final match = RegExp(r'(\d+)').firstMatch(text);
    if (match == null) return null;

    final parsed = int.tryParse(match.group(1)!);
    if (parsed == null || parsed <= 0) return null;

    return parsed.clamp(1, 99);
  }

  String _percentile() {
    final p = _percentileNumber();
    if (p == null || p <= 0) return "";
    return "Top $p%";
  }

  Color _heroPercentileColor() {
    final p = _percentileNumber();

    if (p != null && p <= 15) return const Color(0xFF8FD8FF);
    if (p != null && p <= 30) return const Color(0xFFA9C8FF);
    return const Color(0xFFDCE8FF);
  }

  void _showPremiumTeaser(String label) {
    HapticFeedback.heavyImpact();

    setState(() {
      _premiumText = "Upgrade to Premium to see $label";
    });

    _shakeCtrl
      ..reset()
      ..forward();

    _premiumCtrl
      ..reset()
      ..forward();
  }
  void _showActionToast(String text) {
  setState(() {
    _premiumText = text;
  });

  _premiumCtrl
    ..reset()
    ..forward();
  }
  Future<void> _refreshUserState() async {
  try {
    final token = await AppState.getToken();
    if (token == null || token.isEmpty) throw Exception("NO_TOKEN");

    final user = await SocialProfileApi.getUserById(
      token: token,
      userId: widget.userId,
    );

    if (!mounted) return;

    setState(() {
      _user = user;
      _error = null;
    });
  } catch (e) {
    debugPrint("❌ SEARCH_MAIN refresh state ERROR = $e");
  }
}

void _openProfileActions() {
  if (_isMe || _actionLoading) return;

  HapticFeedback.mediumImpact();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.68),
    builder: (_) {
      return _ProfileActionsSheet(
        username: _username(),
        imageUrl: _img(),
        isBlocked: _isBlocked,
        onBlock: () {
          Navigator.pop(context);
          _confirmBlockUser();
        },
        onUnblock: () {
          Navigator.pop(context);
          _confirmUnblockUser();
        },
        onReport: () {
          Navigator.pop(context);
          _openReportSheet();
        },
      );
    },
  );
}

void _confirmBlockUser() {
  HapticFeedback.heavyImpact();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.72),
    builder: (_) {
      return _ConfirmSheet(
        icon: Icons.block_rounded,
        title: "Block ${_username()}?",
        subtitle:
            "They won’t be able to message you, match with you, or send requests.",
        confirmText: "Block",
        danger: true,
        onConfirm: () {
          Navigator.pop(context);
          _blockUser();
        },
      );
    },
  );
}

void _confirmUnblockUser() {
  HapticFeedback.mediumImpact();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.68),
    builder: (_) {
      return _ConfirmSheet(
        icon: Icons.lock_open_rounded,
        title: "Unblock ${_username()}?",
        subtitle: "They may be able to interact with you again.",
        confirmText: "Unblock",
        danger: false,
        onConfirm: () {
          Navigator.pop(context);
          _unblockUser();
        },
      );
    },
  );
}

Future<void> _blockUser() async {
  if (_actionLoading || _isMe) return;

  setState(() => _actionLoading = true);

  try {
    await SocialMessageService.blockUser(targetUserId: widget.userId);

    if (!mounted) return;

    await _refreshUserState();
    _showActionToast("${_username()} blocked");
  } catch (e) {
    debugPrint("❌ SEARCH_MAIN block ERROR = $e");
    if (!mounted) return;
    _showActionToast("Could not block user");
  } finally {
    if (mounted) setState(() => _actionLoading = false);
  }
}

Future<void> _unblockUser() async {
  if (_actionLoading || _isMe) return;

  setState(() => _actionLoading = true);

  try {
    await SocialMessageService.unblockUser(targetUserId: widget.userId);

    if (!mounted) return;

    await _refreshUserState();
    _showActionToast("${_username()} unblocked");
  } catch (e) {
    debugPrint("❌ SEARCH_MAIN unblock ERROR = $e");
    if (!mounted) return;
    _showActionToast("Could not unblock user");
  } finally {
    if (mounted) setState(() => _actionLoading = false);
  }
}

void _openReportSheet() {
  HapticFeedback.mediumImpact();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.68),
    builder: (_) {
      return _ReportSheet(
        onReport: (reason) {
          Navigator.pop(context);
          _reportUser(reason);
        },
      );
    },
  );
}

Future<void> _reportUser(String reason) async {
  if (_actionLoading || _isMe) return;

  setState(() => _actionLoading = true);

  try {
    await SocialMessageService.reportUser(
      targetUserId: widget.userId,
      reason: reason,
    );

    if (!mounted) return;
    _showActionToast("Report sent");
  } catch (e) {
    debugPrint("❌ SEARCH_MAIN report ERROR = $e");
    if (!mounted) return;
    _showActionToast("Could not report user");
  } finally {
    if (mounted) setState(() => _actionLoading = false);
  }
}

  Future<void> _runAction(String action) async {
  debugPrint("❌❌❌ SEARCH_MAIN ACTION START = $action");

  if (_actionLoading || _isMe) return;

  if (action == "follow" && !_canFollow) {
    debugPrint("❌ SEARCH_MAIN follow blocked frontend");
    return;
  }

  if (action == "match" && !_canMatch) {
    debugPrint("❌ SEARCH_MAIN match blocked frontend");
    return;
  }

  if (action == "message" && !_canDm) {
    debugPrint("❌ SEARCH_MAIN message blocked frontend");
    return;
  }

  HapticFeedback.mediumImpact();

  setState(() => _actionLoading = true);

  try {
    if (action == "follow") {
      await SocialFollowService.followUser(
        targetUserId: widget.userId,
      );

      if (!mounted) return;

      setState(() {
        _user = SocialActionStateHelper.markPending(
          _user,
          SocialActionType.follow,
        );
      });

      debugPrint("✅ SOCIAL_ACTION follow marked pending user=$_user");
      _showActionToast("Request sent");
    } else if (action == "match") {
      await SocialMatchService.sendMatchRequest(
        targetUserId: widget.userId,
      );

      if (!mounted) return;

      setState(() {
        _user = SocialActionStateHelper.markPending(
          _user,
          SocialActionType.match,
        );
      });

      debugPrint("✅ SOCIAL_ACTION match marked pending user=$_user");
      _showActionToast("Match sent");
    } else if (action == "message") {
      await SocialMessageService.sendMessageRequest(
        targetUserId: widget.userId,
      );

      if (!mounted) return;

      setState(() {
        _user = SocialActionStateHelper.markPending(
          _user,
          SocialActionType.message,
        );
      });

      debugPrint("✅ SOCIAL_ACTION message marked pending user=$_user");
      _showActionToast("Message sent");
    }

    debugPrint("✅✅✅ SEARCH_MAIN ACTION SUCCESS = $action");
  } catch (e, s) {
    debugPrint("❌❌❌ SEARCH_MAIN ACTION ERROR action=$action error=$e");
    debugPrint("❌❌❌ SEARCH_MAIN ACTION STACK = $s");

    if (!mounted) return;
    _showActionToast("Could not send");
  } finally {
    if (mounted) {
      setState(() => _actionLoading = false);
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF02050A),
              Color(0xFF07111A),
              Color(0xFF02050A),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: _background()),
            SafeArea(
              child: _loading
                  ? _loadingState()
                  : _error != null
                      ? _errorState()
                      : FadeTransition(
                          opacity: _fade,
                          child: _mainContent(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _background() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, _) {
          final g = _pulseCtrl.value;

          return Stack(
            children: [
              Positioned(
                top: -170,
                left: -120,
                right: -120,
                child: Container(
                  height: 360,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        gold.withOpacity(0.065 + g * 0.022),
                        gold.withOpacity(0.010),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 155,
                left: -130,
                right: -130,
                child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        _heroPercentileColor().withOpacity(0.040),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -220,
                left: -130,
                right: -130,
                child: Container(
                  height: 320,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        gold3.withOpacity(0.018),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _mainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 760;
        final avatarSize = compact ? 158.0 : 180.0;
        final glowSize = compact ? 184.0 : 210.0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(18, 10, 18, compact ? 26 : 32),
          child: Column(
            children: [
              _topBar(),
              SizedBox(height: compact ? 18 : 26),
              _heroAvatar(avatarSize: avatarSize, glowSize: glowSize),
              SizedBox(height: compact ? 16 : 20),
              _identityBlock(),
              SizedBox(height: compact ? 18 : 22),
              _statsBlock(),
              SizedBox(height: compact ? 18 : 22),
              _actionsShell(),
              const SizedBox(height: 14),
              _premiumToast(),
            ],
          ),
        );
      },
    );
  }

  Widget _topBar() {
  return Row(
    children: [
      _glassIcon(
        icon: Icons.arrow_back_ios_new_rounded,
        onTap: () => Navigator.pop(context),
      ),
      const Spacer(),
      if (!_isMe)
        _glassIcon(
          icon: Icons.more_horiz_rounded,
          onTap: _openProfileActions,
        ),
    ],
  );
}

  Widget _glassIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.055),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.24),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _topLivePill() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) {
        final g = _pulseCtrl.value;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              colors: [
                gold3.withOpacity(0.18 + g * 0.035),
                gold.withOpacity(0.095),
              ],
            ),
            border: Border.all(color: gold3.withOpacity(0.28 + g * 0.05)),
            boxShadow: [
              BoxShadow(
                color: gold.withOpacity(0.080 + g * 0.035),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: gold3,
                size: 14,
                shadows: [
                  Shadow(
                    color: gold3.withOpacity(0.35),
                    blurRadius: 8,
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Text(
                "LIVE PROFILE",
                style: TextStyle(
                  color: gold3,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.15,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _heroAvatar({
    required double avatarSize,
    required double glowSize,
  }) {
    final image = _img();
    final rankColor = _heroPercentileColor();

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) {
        final g = _pulseCtrl.value;

        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: glowSize,
              height: glowSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(48),
                boxShadow: [
                  BoxShadow(
                    color: gold.withOpacity(0.090 + g * 0.045),
                    blurRadius: 32 + g * 8,
                    spreadRadius: 0.3,
                  ),
                  BoxShadow(
                    color: rankColor.withOpacity(0.045 + g * 0.025),
                    blurRadius: 40,
                  ),
                ],
              ),
            ),
            Container(
              width: avatarSize + 8,
              height: avatarSize + 8,
              padding: const EdgeInsets.all(2.4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(38),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    gold3,
                    rankColor.withOpacity(0.90),
                    Colors.white.withOpacity(0.18),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: gold.withOpacity(0.11 + g * 0.045),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: Container(
                  color: const Color(0xFF070A10),
                  child: _avatarImage(image),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _avatarImage(String image) {
    if (image.isEmpty) {
      return const Icon(Icons.person_rounded, size: 82, color: Colors.white38);
    }

    if (image.startsWith("http://") || image.startsWith("https://")) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.person_rounded,
          size: 82,
          color: Colors.white38,
        ),
      );
    }

    final file = File(image);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.person_rounded,
          size: 82,
          color: Colors.white38,
        ),
      );
    }

    return const Icon(Icons.person_rounded, size: 82, color: Colors.white38);
  }

  Widget _identityBlock() {
  final percentile = _percentile();
  final rankColor = _heroPercentileColor();
  final p = _percentileNumber();

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Flexible(
        child: Text(
          _username(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 31,
            height: 1.0,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
      ),
      if (percentile.isNotEmpty) ...[
        const SizedBox(width: 9),
        _percentileInline(percentile, rankColor, p),
      ],
    ],
  );
}

Widget _percentileInline(String text, Color color, int? p) {
  final isElite = p != null && p <= 15;
  final isStrong = p != null && p <= 30;

  return AnimatedBuilder(
    animation: _pulseCtrl,
    builder: (context, _) {
      final g = _pulseCtrl.value;

      return Transform.translate(
        offset: Offset(0, -0.8 + g * 1.6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.5, vertical: 5.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(isElite ? 0.20 : 0.12),
                Colors.white.withOpacity(isElite ? 0.060 : 0.035),
                color.withOpacity(isStrong ? 0.10 : 0.060),
              ],
            ),
            border: Border.all(
              color: color.withOpacity(0.26 + g * (isElite ? 0.12 : 0.055)),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(
                  isElite ? 0.16 + g * 0.12 : 0.08 + g * 0.045,
                ),
                blurRadius: isElite ? 16 + g * 8 : 10 + g * 4,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isElite) ...[
                Icon(
                  Icons.workspace_premium_rounded,
                  size: 13,
                  color: color,
                ),
                const SizedBox(width: 4),
              ] else if (isStrong) ...[
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 12.5,
                  color: color,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: isElite ? 14 : 13.2,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.22,
                  height: 1.0,
                  shadows: [
                    Shadow(
                      color: color.withOpacity(isElite ? 0.26 : 0.14),
                      blurRadius: isElite ? 12 + g * 5 : 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _statsBlock() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _shakeCtrl]),
      builder: (context, _) {
        final g = _pulseCtrl.value;
        final shake = _shakeCtrl.isAnimating
            ? (1 - _shakeCtrl.value) *
                (4 * (1 - 2 * ((_shakeCtrl.value * 5) % 1)))
            : 0.0;

        return Transform.translate(
          offset: Offset(shake, 0),
          child: Container(
            padding: const EdgeInsets.all(1.1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                colors: [
                  gold.withOpacity(0.22 + g * 0.050),
                  purple.withOpacity(0.15),
                  Colors.white.withOpacity(0.035),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: gold.withOpacity(0.045 + g * 0.030),
                  blurRadius: 21,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: panel,
                border: Border.all(color: Colors.white.withOpacity(0.060)),
              ),
              child: Row(
                children: [
                  _stat(
                    "Following",
                    _int(_user?["following"]).toString(),
                    onTap: () => _showPremiumTeaser("following"),
                  ),
                  const SizedBox(width: 10),
                  _stat(
                    "Followers",
                    _int(_user?["followers"]).toString(),
                    onTap: () => _showPremiumTeaser("followers"),
                  ),
                  const SizedBox(width: 10),
                  _stat(
                    "Matches",
                    _matchesLocked ? "Locked" : _int(_user?["matches"]).toString(),
                    accent: purple,
                    locked: _matchesLocked,
                    onTap: () => _showPremiumTeaser("matches"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _stat(
    String label,
    String value, {
    Color accent = Colors.white,
    bool locked = false,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: _isMe ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            color: Colors.white.withOpacity(0.034),
            border: Border.all(color: Colors.white.withOpacity(0.045)),
          ),
          child: Column(
            children: [
              locked
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          size: 18,
                          color: accent,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "Locked",
                          style: TextStyle(
                            color: accent,
                            fontSize: 15.2,
                            height: 1.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.25,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      value,
                      style: TextStyle(
                        color: accent,
                        fontSize: 22,
                        height: 1.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.60),
                  fontSize: 12,
                  height: 1.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionsShell() {
  if (_isMe) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(1.1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            gold3.withOpacity(0.24),
            gold.withOpacity(0.10),
            Colors.white.withOpacity(0.035),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: gold.withOpacity(0.050),
            blurRadius: 18,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(23),
          color: panel,
          border: Border.all(color: Colors.white.withOpacity(0.055)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_rounded, color: gold3, size: 20),
            SizedBox(width: 9),
            Text(
              "This is your profile",
              style: TextStyle(
                color: gold3,
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  final followState = SocialActionStateHelper.follow(_user);
  final matchState = SocialActionStateHelper.match(_user);
  final dmState = SocialActionStateHelper.message(_user);

  debugPrint(
    "❌ ACTION_SHELL follow=${followState.label} enabled=${followState.enabled} visual=${followState.visualState}",
  );
  debugPrint(
    "❌ ACTION_SHELL match=${matchState.label} enabled=${matchState.enabled} visual=${matchState.visualState}",
  );
  debugPrint(
    "❌ ACTION_SHELL dm=${dmState.label} enabled=${dmState.enabled} visual=${dmState.visualState}",
  );

  return Container(
    padding: const EdgeInsets.all(1.1),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(
        colors: [
          gold3.withOpacity(0.22),
          purple.withOpacity(0.18),
          Colors.white.withOpacity(0.040),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: gold.withOpacity(0.060),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        color: panel,
        border: Border.all(color: Colors.white.withOpacity(0.055)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: followState.label,
              icon: followState.icon,
              accent: gold3,
              filled: true,
              enabled: followState.enabled && !_actionLoading,
              pulse: _pulseCtrl,
              phase: 0.00,
              onTap: () => _runAction("follow"),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _ActionButton(
              label: matchState.label,
              icon: matchState.icon,
              accent: purple,
              filled: false,
              enabled: matchState.enabled && !_actionLoading,
              pulse: _pulseCtrl,
              phase: 0.28,
              onTap: () => _runAction("match"),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _ActionButton(
              label: dmState.label,
              icon: dmState.icon,
              accent: Colors.white,
              filled: false,
              enabled: dmState.enabled && !_actionLoading,
              pulse: _pulseCtrl,
              phase: 0.56,
              onTap: () => _runAction("message"),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _premiumToast() {
    return AnimatedBuilder(
      animation: _premiumCtrl,
      builder: (context, _) {
        if (_premiumText == null || _premiumCtrl.value <= 0) {
          return const SizedBox.shrink();
        }

        final v = Curves.easeOutCubic.transform(_premiumCtrl.value);
        final opacity = _premiumCtrl.value < 0.82
            ? v
            : (1 - ((_premiumCtrl.value - 0.82) / 0.18)).clamp(0.0, 1.0);

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - v)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    gold3.withOpacity(0.98),
                    gold.withOpacity(0.94),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: gold.withOpacity(0.24),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.black,
                    size: 21,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _premiumText ?? "",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 13.8,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.15,
                      ),
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

  Widget _loadingState() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, _) {
          final g = _pulseCtrl.value;

          return Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: gold.withOpacity(0.08 + g * 0.04),
              border: Border.all(color: gold.withOpacity(0.18 + g * 0.08)),
              boxShadow: [
                BoxShadow(
                  color: gold.withOpacity(0.18 + g * 0.14),
                  blurRadius: 28,
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: gold3,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: gold3, size: 42),
            const SizedBox(height: 12),
            const Text(
              "Failed to load profile",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _loadUser();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(colors: [gold, gold3]),
                  boxShadow: [
                    BoxShadow(
                      color: gold.withOpacity(0.25),
                      blurRadius: 22,
                    ),
                  ],
                ),
                child: const Text(
                  "Retry",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final bool filled;
  final bool enabled;
  final VoidCallback onTap;
  final Animation<double> pulse;
  final double phase;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.filled,
    required this.enabled,
    required this.onTap,
    required this.pulse,
    required this.phase,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _down = false;

  static const Color gold3 = Color(0xFFFFE7A8);

  @override
  Widget build(BuildContext context) {
    final isWhite = widget.accent == Colors.white;
    final opacity = widget.enabled ? 1.0 : 0.36;

    return AnimatedBuilder(
      animation: widget.pulse,
      builder: (context, _) {
        final raw = (widget.pulse.value + widget.phase) % 1.0;
        final micro = (raw - 0.5).abs();
        final lift = widget.enabled ? (0.9 - micro * 1.8) : 0.0;

        return Transform.translate(
          offset: Offset(0, -lift),
          child: GestureDetector(
            onTap: widget.enabled ? widget.onTap : null,
            onTapDown: widget.enabled ? (_) => setState(() => _down = true) : null,
            onTapCancel:
                widget.enabled ? () => setState(() => _down = false) : null,
            onTapUp: widget.enabled ? (_) => setState(() => _down = false) : null,
            child: AnimatedScale(
              scale: _down ? 0.945 : 1.0,
              duration: const Duration(milliseconds: 115),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: opacity,
                duration: const Duration(milliseconds: 160),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: widget.filled
                        ? LinearGradient(colors: [widget.accent, gold3])
                        : null,
                    color:
                        widget.filled ? null : widget.accent.withOpacity(0.095),
                    border: Border.all(
                      color: widget.filled
                          ? Colors.transparent
                          : widget.accent.withOpacity(isWhite ? 0.12 : 0.24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accent.withOpacity(
                          widget.filled ? 0.17 : 0.070,
                        ),
                        blurRadius: widget.filled ? 16 : 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.icon,
                        size: 18,
                        color: widget.filled ? Colors.black : widget.accent,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          widget.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                widget.filled ? Colors.black : widget.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
class _ProfileActionsSheet extends StatelessWidget {
  final String username;
  final String imageUrl;
  final bool isBlocked;
  final VoidCallback onBlock;
  final VoidCallback onUnblock;
  final VoidCallback onReport;

  const _ProfileActionsSheet({
    required this.username,
    required this.imageUrl,
    required this.isBlocked,
    required this.onBlock,
    required this.onUnblock,
    required this.onReport,
  });

  static const Color panel = Color(0xF0060A12);
  static const Color gold = Color(0xFFFFC34D);
  static const Color gold3 = Color(0xFFFFE7A8);
  static const Color purple = Color(0xFF7C3AED);
  static const Color danger = Color(0xFFFF4D67);
  static const Color cyan = Color(0xFF8FD8FF);

  @override
  Widget build(BuildContext context) {
    return _BottomGlassSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),
          const SizedBox(height: 18),
          Row(
            children: [
              _SheetAvatar(imageUrl: imageUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SheetTile(
            icon: Icons.report_gmailerrorred_rounded,
            title: "Report user",
            subtitle: "Send this profile to admin review",
            color: cyan,
            onTap: onReport,
          ),
          const SizedBox(height: 10),
          _SheetTile(
            icon: isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
            title: isBlocked ? "Unblock user" : "Block user",
            subtitle: isBlocked
                ? "Allow interactions again"
                : "Stop messages, matches and requests",
            color: isBlocked ? gold3 : danger,
            onTap: isBlocked ? onUnblock : onBlock,
          ),
        ],
      ),
    );
  }
}

class _ReportSheet extends StatelessWidget {
  final ValueChanged<String> onReport;

  const _ReportSheet({
    required this.onReport,
  });

  static const Color gold3 = Color(0xFFFFE7A8);
  static const Color cyan = Color(0xFF8FD8FF);

  @override
  Widget build(BuildContext context) {
    return _BottomGlassSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),
          const SizedBox(height: 18),
          const Text(
            "Report reason",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 16),
          _SheetTile(
            icon: Icons.flag_rounded,
            title: "Harassment",
            subtitle: "Submit report",
            color: gold3,
            onTap: () => onReport("Harassment"),
          ),
          const SizedBox(height: 10),
          _SheetTile(
            icon: Icons.flag_rounded,
            title: "Spam or fake profile",
            subtitle: "Submit report",
            color: gold3,
            onTap: () => onReport("Spam or fake profile"),
          ),
          const SizedBox(height: 10),
          _SheetTile(
            icon: Icons.flag_rounded,
            title: "Inappropriate messages",
            subtitle: "Submit report",
            color: gold3,
            onTap: () => onReport("Inappropriate messages"),
          ),
          const SizedBox(height: 10),
          _SheetTile(
            icon: Icons.flag_rounded,
            title: "Other",
            subtitle: "Submit report",
            color: cyan,
            onTap: () => onReport("Other"),
          ),
        ],
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String confirmText;
  final bool danger;
  final VoidCallback onConfirm;

  const _ConfirmSheet({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.confirmText,
    required this.danger,
    required this.onConfirm,
  });

  static const Color gold = Color(0xFFFFC34D);
  static const Color gold3 = Color(0xFFFFE7A8);
  static const Color dangerColor = Color(0xFFFF4D67);

  @override
  Widget build(BuildContext context) {
    final color = danger ? dangerColor : gold3;

    return _BottomGlassSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),
          const SizedBox(height: 22),
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.13),
              border: Border.all(color: color.withOpacity(0.22)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.18),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 36),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.56),
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _ConfirmButton(
                  text: "Cancel",
                  filled: false,
                  danger: false,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ConfirmButton(
                  text: confirmText,
                  filled: true,
                  danger: danger,
                  onTap: onConfirm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final String text;
  final bool filled;
  final bool danger;
  final VoidCallback onTap;

  const _ConfirmButton({
    required this.text,
    required this.filled,
    required this.danger,
    required this.onTap,
  });

  static const Color gold = Color(0xFFFFC34D);
  static const Color gold3 = Color(0xFFFFE7A8);
  static const Color red = Color(0xFFFF4D67);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: filled
              ? LinearGradient(
                  colors: danger ? [red, Color(0xFFFF7A8B)] : [gold, gold3],
                )
              : null,
          color: filled ? null : Colors.white.withOpacity(0.065),
          border: Border.all(
            color: filled ? Colors.transparent : Colors.white.withOpacity(0.10),
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: filled ? Colors.black : Colors.white.withOpacity(0.86),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomGlassSheet extends StatelessWidget {
  final Widget child;

  const _BottomGlassSheet({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: const Color(0xF0060A12),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.10)),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFC34D).withOpacity(0.10),
                  blurRadius: 42,
                  offset: const Offset(0, -16),
                ),
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.18),
                  blurRadius: 44,
                  offset: const Offset(0, -18),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 5,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.18),
      ),
    );
  }
}

class _SheetAvatar extends StatelessWidget {
  final String imageUrl;

  const _SheetAvatar({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    const size = 62.0;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(1.8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const SweepGradient(
          colors: [
            Color(0xFFFFE7A8),
            Color(0xFFFFC34D),
            Color(0xFFA855F7),
            Color(0xFF8FD8FF),
            Color(0xFFFFE7A8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFC34D).withOpacity(0.20),
            blurRadius: 22,
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _SheetAvatarFallback(),
              )
            : _SheetAvatarFallback(),
      ),
    );
  }
}

class _SheetAvatarFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF090D14),
      child: const Icon(
        Icons.person_rounded,
        color: Color(0xFFFFE7A8),
        size: 32,
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SheetTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(23),
          color: Colors.white.withOpacity(0.055),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.48),
                      fontSize: 12.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.34),
            ),
          ],
        ),
      ),
    );
  }
}