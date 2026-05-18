import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:frontend/features/social_free/services/social_follow_service.dart';
import 'package:frontend/features/social_free/services/social_message_service.dart';
import 'package:frontend/features/social_free/social_features/social_api.dart';
import 'package:frontend/features/social_free/social_features/search_main_screen.dart';

class FollowingScreen extends StatefulWidget {
  final int userId;

  const FollowingScreen({
    super.key,
    required this.userId,
  });

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen>
    with TickerProviderStateMixin {
  static const Color bg = Color(0xFF02050A);
  static const Color bg2 = Color(0xFF07111A);
  static const Color panel = Color(0xD00A101B);
  static const Color gold = Color(0xFFFFC34D);
  static const Color gold2 = Color(0xFFFFE7A8);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purple2 = Color(0xFFA855F7);
  static const Color cyan = Color(0xFF8FD8FF);
  static const Color danger = Color(0xFFFF4D67);

  static const int _limit = 30;

  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scroll = ScrollController();

  late final AnimationController _pulseCtrl;
  late final AnimationController _enterCtrl;
  late final Animation<double> _fade;

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _actionLoading = false;

  int _offset = 0;
  int? _lastOffsetRequested;
  String _query = "";

  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _fade = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic);
    _enterCtrl.forward();

    _searchCtrl.addListener(() {
      final next = _searchCtrl.text;
      if (next != _query && mounted) {
        setState(() => _query = next);
      }
    });

    _scroll.addListener(_onScroll);

    _load(refresh: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _enterCtrl.dispose();
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_loading || _loadingMore || !_hasMore) return;
    if (_query.trim().isNotEmpty) return;

    final pos = _scroll.position;

    if (pos.pixels >= pos.maxScrollExtent - 360) {
      _loadMore();
    }
  }

  Future<void> _load({bool refresh = false}) async {
    if (mounted) {
      setState(() {
        if (refresh) {
          _loading = true;
          _offset = 0;
          _hasMore = true;
          _lastOffsetRequested = null;
        }
      });
    }

    try {
      final page = await SocialFollowService.getFollowingPage(
        userId: widget.userId,
        limit: _limit,
        offset: 0,
      );

      final items = _items(page);

      if (!mounted) return;

      setState(() {
        _users = items;
        _offset = (page["next_offset"] as num?)?.toInt() ?? items.length;
        _hasMore = page["has_more"] == true;
        _lastOffsetRequested = null;
        _loading = false;
      });
    } catch (e, s) {
      debugPrint("❌❌❌ FOLLOWING_SCREEN load ERROR = $e");
      debugPrint("❌❌❌ FOLLOWING_SCREEN load STACK = $s");

      if (!mounted) return;
      setState(() => _loading = false);
      _toast("Could not load following");
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    if (_query.trim().isNotEmpty) return;

    final offset = _offset;

    if (_lastOffsetRequested == offset) return;
    _lastOffsetRequested = offset;

    setState(() => _loadingMore = true);

    try {
      final page = await SocialFollowService.getFollowingPage(
        userId: widget.userId,
        limit: _limit,
        offset: offset,
      );

      final items = _items(page);
      final existingIds = _users.map(_userId).where((id) => id > 0).toSet();

      final fresh = items.where((u) {
        final id = _userId(u);
        return id > 0 && !existingIds.contains(id);
      }).toList();

      final nextOffset =
          (page["next_offset"] as num?)?.toInt() ?? offset + items.length;

      if (!mounted) return;

      setState(() {
        if (fresh.isNotEmpty) {
          _users.addAll(fresh);
        }

        _offset = nextOffset;
        _hasMore = page["has_more"] == true && nextOffset > offset;
      });

      if (items.isEmpty || nextOffset <= offset) {
        setState(() => _hasMore = false);
      }
    } catch (e, s) {
      debugPrint("❌❌❌ FOLLOWING_SCREEN loadMore ERROR = $e");
      debugPrint("❌❌❌ FOLLOWING_SCREEN loadMore STACK = $s");

      _lastOffsetRequested = null;
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  List<Map<String, dynamic>> _items(Map<String, dynamic> page) {
    final raw = page["items"] ?? page["following"];

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _users;

    return _users.where((u) {
      return _name(u).toLowerCase().contains(q);
    }).toList();
  }

  int _userId(Map<String, dynamic> u) {
    final raw = u["user_id"] ?? u["id"];

    if (raw is int) return raw;
    if (raw is num) return raw.toInt();

    return int.tryParse(raw?.toString() ?? "") ?? 0;
  }

  String _name(Map<String, dynamic> u) {
    final raw = (u["username"] ?? u["display_name"] ?? u["name"] ?? "User")
        .toString()
        .trim();

    return raw.isEmpty ? "User" : raw;
  }

  String _image(Map<String, dynamic> u) {
    final raw = (u["profile_image_url"] ??
            u["image_url"] ??
            u["avatar_url"] ??
            u["image"] ??
            u["local_image_path"] ??
            "")
        .toString()
        .trim();

    if (raw.isEmpty) return "";
    if (raw.startsWith("http://") || raw.startsWith("https://")) return raw;
    if (raw.startsWith("/")) return "${SocialApi.baseUrl}$raw";

    return raw;
  }

  Future<void> _unfollow(Map<String, dynamic> u) async {
    final id = _userId(u);
    if (id <= 0 || _actionLoading) return;

    HapticFeedback.selectionClick();

    final oldUsers = [..._users];

    setState(() {
      _actionLoading = true;
      _users.removeWhere((x) => _userId(x) == id);
      _offset = _users.length;
    });

    try {
      await SocialFollowService.unfollowUser(targetUserId: id);

      if (!mounted) return;
      _toast("Unfollowed");
    } catch (e) {
      debugPrint("❌❌❌ FOLLOWING_SCREEN unfollow ERROR = $e");

      if (!mounted) return;

      setState(() {
        _users = oldUsers;
        _offset = oldUsers.length;
      });

      _toast("Could not unfollow");
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _blockUser(Map<String, dynamic> u) async {
    final id = _userId(u);
    if (id <= 0 || _actionLoading) return;

    HapticFeedback.heavyImpact();

    final oldUsers = [..._users];

    setState(() {
      _actionLoading = true;
      _users.removeWhere((x) => _userId(x) == id);
      _offset = _users.length;
    });

    try {
      await SocialMessageService.blockUser(targetUserId: id);

      if (!mounted) return;
      _toast("User blocked");
    } catch (e) {
      debugPrint("❌❌❌ FOLLOWING_SCREEN block ERROR = $e");

      if (!mounted) return;

      setState(() {
        _users = oldUsers;
        _offset = oldUsers.length;
      });

      _toast("Could not block user");
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  void _openProfile(Map<String, dynamic> u) {
    final id = _userId(u);
    if (id <= 0) return;

    HapticFeedback.selectionClick();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchMainScreen(userId: id),
      ),
    ).then((_) {
      if (mounted) _load(refresh: true);
    });
  }

  void _openActions(Map<String, dynamic> u) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.66),
      builder: (_) {
        final bottom = MediaQuery.of(context).padding.bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  color: const Color(0xF0060A12),
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.10)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gold.withOpacity(0.15),
                      blurRadius: 42,
                      offset: const Offset(0, -16),
                    ),
                    BoxShadow(
                      color: purple.withOpacity(0.20),
                      blurRadius: 46,
                      offset: const Offset(0, -18),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _sheetHandle(),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _avatar(u, size: 62),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _name(u),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "You follow this profile",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.50),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _sheetTile(
                        icon: Icons.person_rounded,
                        title: "View profile",
                        subtitle: "Open full social profile",
                        color: gold2,
                        onTap: () {
                          Navigator.pop(context);
                          _openProfile(u);
                        },
                      ),
                      const SizedBox(height: 10),
                      _sheetTile(
                        icon: Icons.remove_circle_outline_rounded,
                        title: "Unfollow",
                        subtitle: "Remove from your following list",
                        color: gold2,
                        onTap: () {
                          Navigator.pop(context);
                          _unfollow(u);
                        },
                      ),
                      const SizedBox(height: 10),
                      _sheetTile(
                        icon: Icons.block_rounded,
                        title: "Block user",
                        subtitle: "Stop interactions with this user",
                        color: danger,
                        onTap: () {
                          Navigator.pop(context);
                          _blockUser(u);
                        },
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

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF111827),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          Positioned.fill(child: _background()),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _top(),
                    const SizedBox(height: 14),
                    _search(),
                    const SizedBox(height: 18),
                    Expanded(
                      child: _loading
                          ? _loadingState()
                          : RefreshIndicator(
                              color: gold2,
                              backgroundColor: const Color(0xFF080D15),
                              onRefresh: () => _load(refresh: true),
                              child: _filtered.isEmpty
                                  ? _empty()
                                  : ListView.builder(
                                      controller: _scroll,
                                      physics:
                                          const AlwaysScrollableScrollPhysics(
                                        parent: BouncingScrollPhysics(),
                                      ),
                                      keyboardDismissBehavior:
                                          ScrollViewKeyboardDismissBehavior
                                              .onDrag,
                                      padding: EdgeInsets.only(
                                        bottom: 34 + bottom,
                                      ),
                                      itemCount: _filtered.length +
                                          (_loadingMore ? 1 : 0),
                                      itemBuilder: (_, i) {
                                        if (i >= _filtered.length) {
                                          return _bottomLoader();
                                        }

                                        return _userCard(_filtered[i], i);
                                      },
                                    ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _top() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
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
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            "Following",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
            ),
          ),
        ),
        _countPill(),
      ],
    );
  }

  Widget _countPill() {
    final count = _query.trim().isEmpty ? _users.length : _filtered.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            gold.withOpacity(0.20),
            purple.withOpacity(0.18),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: gold.withOpacity(0.10),
            blurRadius: 20,
          ),
        ],
      ),
      child: Text(
        count > 99 ? "99+" : count.toString(),
        style: const TextStyle(
          color: gold2,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _search() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) {
            final g = _pulseCtrl.value;

            return Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: gold.withOpacity(0.09 + g * 0.035),
                ),
                boxShadow: [
                  BoxShadow(
                    color: gold.withOpacity(0.035 + g * 0.020),
                    blurRadius: 26,
                    offset: const Offset(0, 13),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: gold2.withOpacity(0.88),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      cursorColor: gold2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Search following",
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.34),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  if (_searchCtrl.text.trim().isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _searchCtrl.clear();
                      },
                      child: Container(
                        width: 31,
                        height: 31,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.065),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.075),
                          ),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withOpacity(0.68),
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> u, int i) {
    final id = _userId(u);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 240 + (i.clamp(0, 8) * 35)),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _openProfile(u),
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) {
            final wave = ((_pulseCtrl.value + (i * 0.11)) % 1.0);
            final breathe = math.sin(wave * math.pi);
            final glow = breathe * (i < 3 ? 1.0 : 0.45);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(1.1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    gold.withOpacity(i == 0 ? 0.50 : 0.30 + glow * 0.05),
                    purple.withOpacity(0.22 + glow * 0.03),
                    cyan.withOpacity(0.045),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: gold.withOpacity(0.10 + glow * 0.04),
                    blurRadius: 24 + glow * 9,
                    offset: const Offset(0, 13),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.30),
                    blurRadius: 28,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Container(
                height: 98,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(29),
                  color: panel,
                  border: Border.all(color: Colors.white.withOpacity(0.050)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.070),
                      Colors.white.withOpacity(0.030),
                      Colors.white.withOpacity(0.012),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Hero(
                      tag: "social_user_avatar_$id",
                      child: _avatar(u, size: 66),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _name(u),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19.2,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.45,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              Icon(
                                Icons.favorite_rounded,
                                color: gold2,
                                size: 15,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "Following • tap to view profile",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.56),
                                    fontSize: 13.2,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _openActions(u),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.065),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: const Icon(
                          Icons.more_horiz_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _avatar(Map<String, dynamic> u, {required double size}) {
    final img = _image(u);

    if (img.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(1.7),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const SweepGradient(
            colors: [gold2, gold, purple2, cyan, gold2],
          ),
          boxShadow: [
            BoxShadow(color: gold.withOpacity(0.20), blurRadius: 20),
          ],
        ),
        child: ClipOval(
          child: Image.network(
            img,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __,___) => _avatarFallback(size),
          ),
        ),
      );
    }

    return _avatarFallback(size);
  }

  Widget _avatarFallback(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [gold2, purple2]),
        boxShadow: [
          BoxShadow(color: gold.withOpacity(0.20), blurRadius: 20),
        ],
      ),
      child: Icon(
        Icons.person_rounded,
        color: Colors.black54,
        size: size * 0.52,
      ),
    );
  }

  Widget _sheetHandle() {
    return Container(
      width: 44,
      height: 5,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.18),
      ),
    );
  }

  Widget _sheetTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _actionLoading ? null : onTap,
      child: AnimatedOpacity(
        opacity: _actionLoading ? 0.55 : 1,
        duration: const Duration(milliseconds: 160),
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
                        fontWeight: FontWeight.w700,
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
      ),
    );
  }

  Widget _loadingState() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 2),
      itemCount: 6,
      itemBuilder: (_, i) {
        return AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) {
            final g = _pulseCtrl.value;

            return Container(
              height: 98,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.white.withOpacity(0.026 + g * 0.012),
                border: Border.all(color: Colors.white.withOpacity(0.045)),
                boxShadow: [
                  BoxShadow(
                    color: gold.withOpacity(0.020 + g * 0.014),
                    blurRadius: 22,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _bottomLoader() {
    return const Padding(
      padding: EdgeInsets.all(18),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: gold2,
            strokeWidth: 2.4,
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 110),
        Center(
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [gold, gold2]),
                  boxShadow: [
                    BoxShadow(
                      color: gold.withOpacity(0.26),
                      blurRadius: 28,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.black,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "Not following anyone yet",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _query.trim().isEmpty
                    ? "Profiles this user follows will appear here."
                    : "Try another name.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.54),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _background() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final g = _pulseCtrl.value;

        return Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [bg, bg2, bg],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -165,
              left: -110,
              right: -110,
              child: Container(
                height: 410,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      purple2.withOpacity(0.18 + g * 0.035),
                      purple.withOpacity(0.065),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -185,
              left: -130,
              right: -130,
              child: Container(
                height: 430,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      gold.withOpacity(0.13 + g * 0.020),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 240,
              right: -120,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      cyan.withOpacity(0.070),
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
}