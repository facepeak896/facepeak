import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/features/analysis/screens/app_state.dart';
import 'package:frontend/features/social_free/social_features/social_api.dart';
import 'package:frontend/features/social_free/social_features/search_main_screen.dart';
import 'package:frontend/features/social_free/social_features/widgets/search_screen_widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

enum RelationTier {
  close,
  slightlyAbove,
  slightlyBelow,
  farAbove,
  farBelow,
  unknown,
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  late final AnimationController _enterCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _fade;

  Timer? _emptyRetryTimer;

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _hasLoadedOnce = false;
  bool _refreshing = false;
  String? _error;

  int _offset = 0;
  int? _lastOffsetRequested;
  int? _myPercentile;
  int _emptyRetryCount = 0;

  static const int _limit = 30;
  static const int _maxEmptyRetries = 5;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];

  static const Color bg = Color(0xFF02050A);
  static const Color bg2 = Color(0xFF07111A);
  static const Color panel = Color(0xCC0A101B);

  static const Color gold = Color(0xFFFFC34D);
  static const Color gold2 = Color(0xFFFFD978);
  static const Color gold3 = Color(0xFFFFE7A8);
  static const Color muted = Color(0xFFEFF5FF);

  @override
  void initState() {
    super.initState();

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _fade = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic);
    _enterCtrl.forward();

    _searchCtrl.addListener(_filter);
    _scrollCtrl.addListener(_onScroll);

    _loadMyPercentile();
    _loadUsers();
  }

  @override
  void dispose() {
    _emptyRetryTimer?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _enterCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _scheduleEmptyRetry() {
    if (_emptyRetryCount >= _maxEmptyRetries) return;

    _emptyRetryTimer?.cancel();
    _emptyRetryCount++;

    _emptyRetryTimer = Timer(
      Duration(milliseconds: 650 + (_emptyRetryCount * 450)),
      () {
        if (!mounted) return;
        if (_users.isNotEmpty) return;

        _loadUsers(refresh: true);
      },
    );
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    if (_loading) return;
    if (_loadingMore) return;
    if (!_hasMore) return;
    if (_searchCtrl.text.trim().isNotEmpty) return;

    final pos = _scrollCtrl.position;

    if (pos.pixels > pos.maxScrollExtent - 360) {
      _loadMore();
    }
  }

  Future<void> _loadMyPercentile() async {
    final psl = await AppState.getSocialPslSnapshot();
    if (!mounted || psl == null) return;

    final parsed = _percentileNumberFrom(psl["percentile"]) ??
        _percentileNumberFrom(psl["reach_target_percentile"]) ??
        _percentileNumberFrom(psl["target_percentile"]);

    if (parsed != null && parsed > 0) {
      setState(() => _myPercentile = parsed);
      _sortAndFilter();
    }
  }

  int _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? "") ?? 0;
  }

  String _safeName(dynamic value) {
    final raw = value?.toString().trim() ?? "";
    final cleaned = raw.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), "");
    if (cleaned.isEmpty) return "User";
    final cut = cleaned.length > 12 ? cleaned.substring(0, 12) : cleaned;
    return cut[0].toUpperCase() + cut.substring(1);
  }

  String _formatFollowers(int count) {
    if (count >= 1000000) return "${(count / 1000000).toStringAsFixed(1)}M";
    if (count >= 1000) return "${(count / 1000).toStringAsFixed(1)}K";
    return "$count";
  }

  String _imageOf(Map<String, dynamic> user) {
    return (user["profile_image_url"] ??
            user["image_url"] ??
            user["image"] ??
            user["local_image_path"] ??
            "")
        .toString()
        .trim();
  }

  dynamic _pslValue(Map<String, dynamic> user, String key) {
    final psl = user["psl"];
    if (psl is Map && psl[key] != null) return psl[key];
    return user[key];
  }

  int? _percentileNumberFrom(dynamic value) {
    if (value == null) return null;

    if (value is num && value > 0) {
      return value.toInt().clamp(1, 99);
    }

    final text = value.toString().toLowerCase().trim();
    if (text.isEmpty) return null;

    final match = RegExp(r'(\d+)').firstMatch(text);
    if (match == null) return null;

    final parsed = int.tryParse(match.group(1)!);
    if (parsed == null || parsed <= 0) return null;

    return parsed.clamp(1, 99);
  }

  int? _userPercentile(Map<String, dynamic> user) {
    return _percentileNumberFrom(_pslValue(user, "percentile")) ??
        _percentileNumberFrom(user["reach_target_percentile"]) ??
        _percentileNumberFrom(user["top_percentile"]);
  }

  String _percentileText(Map<String, dynamic> user) {
    final raw = _pslValue(user, "percentile");

    if (raw is String && raw.trim().isNotEmpty) {
      if (raw.toLowerCase().contains("top") ||
          raw.toLowerCase().contains("bottom")) {
        return raw.trim();
      }
    }

    final p = _userPercentile(user);
    if (p == null || p <= 0) return "";
    return "Top $p%";
  }

  Color _percentileColor(Map<String, dynamic> user) {
    final p = _userPercentile(user) ?? 99;

    if (p <= 10) return gold3;
    if (p <= 25) return gold2;
    if (p <= 50) return gold;
    return muted.withOpacity(0.86);
  }

  RelationTier _relationTier(Map<String, dynamic> user) {
    final mine = _myPercentile;
    final theirs = _userPercentile(user);

    if (mine == null || theirs == null) return RelationTier.unknown;

    final diff = theirs - mine;

    if (diff.abs() <= 4) return RelationTier.close;
    if (diff < -4 && diff >= -14) return RelationTier.slightlyAbove;
    if (diff > 4 && diff <= 14) return RelationTier.slightlyBelow;
    if (diff < -14) return RelationTier.farAbove;
    return RelationTier.farBelow;
  }

  Color _tierColor(Map<String, dynamic> user) {
    final p = _userPercentile(user) ?? 99;

    if (p <= 10) return gold3;
    if (p <= 25) return gold2;
    if (p <= 50) return gold;
    return gold.withOpacity(0.68);
  }

  double _rankIntensity(Map<String, dynamic> user) {
    final p = _userPercentile(user) ?? 99;

    if (p <= 10) return 1.0;
    if (p <= 25) return 0.70;
    if (p <= 50) return 0.42;
    return 0.18;
  }

  int _sortRank(Map<String, dynamic> user) {
    final p = _userPercentile(user);
    if (p == null || p <= 0) return 999;
    return p;
  }

  void _sortUsersInPlace(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      final ap = _sortRank(a);
      final bp = _sortRank(b);

      if (ap != bp) return ap.compareTo(bp);

      final af = _safeInt(a["followers_count"] ?? a["followers"]);
      final bf = _safeInt(b["followers_count"] ?? b["followers"]);

      return bf.compareTo(af);
    });
  }

  int _rankOfUser(Map<String, dynamic> user) {
    final id = _safeInt(user["id"]);
    final sorted = [..._users];
    _sortUsersInPlace(sorted);

    final index = sorted.indexWhere((u) => _safeInt(u["id"]) == id);
    if (index < 0) return 0;
    return index + 1;
  }

  List<Color> _rankGradient(int rank) {
    if (rank == 1) {
      return const [Color(0xFFFFF0B8), Color(0xFFFFC34D)];
    }

    if (rank == 2) {
      return const [Color(0xFFF2F5FA), Color(0xFF9EA8B8)];
    }

    if (rank == 3) {
      return const [Color(0xFFE7A15E), Color(0xFF8A4D28)];
    }

    if (rank <= 10) {
      return [
        const Color(0xFFE9EEF7).withOpacity(0.30),
        const Color(0xFF8793A6).withOpacity(0.16),
      ];
    }

    if (rank <= 100) {
      return [
        Colors.white.withOpacity(0.13),
        Colors.white.withOpacity(0.045),
      ];
    }

    if (rank <= 1000) {
      return [
        gold.withOpacity(0.14),
        Colors.white.withOpacity(0.035),
      ];
    }

    return [
      Colors.white.withOpacity(0.070),
      Colors.white.withOpacity(0.025),
    ];
  }

  Color _rankBorderColor(int rank) {
    if (rank == 1) return gold3.withOpacity(0.55);
    if (rank == 2) return const Color(0xFFE9EEF7).withOpacity(0.42);
    if (rank == 3) return const Color(0xFFE7A15E).withOpacity(0.44);
    if (rank <= 10) return const Color(0xFFE9EEF7).withOpacity(0.22);
    if (rank <= 100) return Colors.white.withOpacity(0.12);
    return gold.withOpacity(0.16);
  }

  Color _rankTextColor(int rank) {
    if (rank == 1) return Colors.black;
    if (rank == 2) return const Color(0xFF10151D);
    if (rank == 3) return Colors.white;
    if (rank <= 10) return const Color(0xFFE9EEF7);
    return gold3.withOpacity(0.92);
  }

  void _sortAndFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    final source = [..._users];

    _sortUsersInPlace(source);

    setState(() {
      _filtered = q.isEmpty
          ? source
          : source.where((u) {
              final name = _safeName(u["username"]).toLowerCase();
              final rank = _rankOfUser(u).toString();
              final hashRank = "#$rank";
              final percentile = _percentileText(u).toLowerCase();

              return name.contains(q) ||
                  rank == q.replaceAll("#", "") ||
                  hashRank == q ||
                  percentile.contains(q);
            }).toList();
    });
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    final hadOldUsers = _users.isNotEmpty;
    final oldUsers = List<Map<String, dynamic>>.from(_users);

    if (mounted) {
      setState(() {
        _error = null;

        if (refresh || hadOldUsers) {
          _refreshing = true;
        } else {
          _loading = true;
        }

        _offset = 0;
        _hasMore = true;
        _lastOffsetRequested = null;
      });
    }

    try {
      final token = await AppState.getToken();
      if (token == null || token.isEmpty) throw Exception("NO_TOKEN");

      final page = await SocialApi.getSocialUsersPage(
        token: token,
        limit: _limit,
        offset: 0,
      );

      final users = ((page["users"] ?? page["items"]) as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (!mounted) return;

      _sortUsersInPlace(users);

      if (users.isEmpty && oldUsers.isEmpty) {
        _scheduleEmptyRetry();
      }

      setState(() {
        if (users.isNotEmpty) {
          _emptyRetryCount = 0;
          _emptyRetryTimer?.cancel();
        }

        _users = users;
        _filtered = users;
        _offset = (page["next_offset"] as num?)?.toInt() ?? users.length;
        _hasMore = page["has_more"] == true;
        _lastOffsetRequested = null;
        _loading = false;
        _refreshing = false;
        _hasLoadedOnce = true;
        _error = null;
      });

      _sortAndFilter();
    } catch (e) {
      debugPrint("❌ SEARCH_SCREEN load ERROR = $e");

      if (!mounted) return;

      setState(() {
        _users = oldUsers;
        _loading = false;
        _refreshing = false;
        _hasLoadedOnce = true;
        _error = null;
      });

      _sortAndFilter();

      if (oldUsers.isEmpty) {
        _scheduleEmptyRetry();
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loading) return;
    if (_loadingMore) return;
    if (!_hasMore) return;
    if (_searchCtrl.text.trim().isNotEmpty) return;

    final offset = _offset;

    if (_lastOffsetRequested == offset) return;

    _lastOffsetRequested = offset;

    setState(() => _loadingMore = true);

    try {
      final token = await AppState.getToken();
      if (token == null || token.isEmpty) throw Exception("NO_TOKEN");

      final page = await SocialApi.getSocialUsersPage(
        token: token,
        limit: _limit,
        offset: offset,
      );

      final more = ((page["users"] ?? page["items"]) as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final existingIds = _users.map((u) => _safeInt(u["id"])).toSet();

      final fresh = more.where((u) {
        final id = _safeInt(u["id"]);
        return id > 0 && !existingIds.contains(id);
      }).toList();

      final nextOffset =
          (page["next_offset"] as num?)?.toInt() ?? offset + more.length;

      if (!mounted) return;

      setState(() {
        if (fresh.isNotEmpty) {
          _users.addAll(fresh);
          _sortUsersInPlace(_users);
        }

        _offset = nextOffset;
        _hasMore = page["has_more"] == true && nextOffset > offset;
        _loadingMore = false;
      });

      if (more.isEmpty || nextOffset <= offset) {
        if (!mounted) return;
        setState(() => _hasMore = false);
      }

      _sortAndFilter();
    } catch (e) {
      debugPrint("❌ SEARCH_SCREEN loadMore ERROR = $e");

      _lastOffsetRequested = null;

      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _filter() => _sortAndFilter();

  void _openUser(Map<String, dynamic> user) {
    HapticFeedback.selectionClick();

    final userId = _safeInt(user["id"]);
    if (userId <= 0) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchMainScreen(userId: userId),
      ),
    );
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
            colors: [bg, bg2, bg],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: _background()),
            SafeArea(
              child: FadeTransition(
                opacity: _fade,
                child: Column(
                  children: [
                    Expanded(child: _content()),
                  ],
                ),
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
                top: -150,
                left: -120,
                right: -120,
                child: Container(
                  height: 370,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        gold.withOpacity(0.105 + g * 0.035),
                        gold.withOpacity(0.015),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -180,
                left: -100,
                right: -100,
                child: Container(
                  height: 400,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        gold3.withOpacity(0.032),
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

  Widget _content() {
    if (_loading && _users.isEmpty && !_hasLoadedOnce) {
      return _loadingList();
    }

    return RefreshIndicator(
      color: gold,
      backgroundColor: bg2,
      onRefresh: () => _loadUsers(refresh: true),
      child: ListView(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          _searchBar(),
          const SizedBox(height: 14),

          if (_filtered.isEmpty &&
              _hasLoadedOnce &&
              !_loading &&
              !_refreshing &&
              _emptyRetryCount >= _maxEmptyRetries)
            _emptyState()
          else if (_filtered.isEmpty)
            _softLoadingState()
          else
            ...List.generate(
              _filtered.length,
              (index) => _userCard(_filtered[index], index),
            ),

          if (_refreshing && _filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 14),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: gold3.withOpacity(0.68),
                  ),
                ),
              ),
            ),

          if (_loadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: gold3,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 540),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, _) {
              final g = _pulseCtrl.value;

              return Container(
                height: 62,
                padding: const EdgeInsets.symmetric(horizontal: 17),
                decoration: BoxDecoration(
                  color: panel,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: gold.withOpacity(0.10 + g * 0.045),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gold.withOpacity(0.034 + g * 0.026),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.24),
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: gold3, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        maxLines: 1,
                        cursorColor: gold3,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Search name or #rank",
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.32),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    if (_searchCtrl.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          HapticFeedback.selectionClick();
                        },
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withOpacity(0.45),
                          size: 22,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> user, int index) {
  final rank = _rankOfUser(user);
  final name = _safeName(user["username"]);
  final image = _imageOf(user);
  final followers = _safeInt(user["followers_count"] ?? user["followers"]);
  final percentile = _percentileText(user);
  final percentileColor = _percentileColor(user);
  final p = _userPercentile(user) ?? 99;

  return SearchEliteUserCard(
    index: index,
    rank: rank,
    name: name,
    image: image,
    followersText: "${_formatFollowers(followers)} followers",
    percentile: percentile.isEmpty ? "Unranked" : percentile,
    percentileColor: percentileColor,
    percentileNumber: p,
    pulse: _pulseCtrl,
    baseUrl: SocialApi.baseUrl,
    onTap: () => _openUser(user),
  );
}

  Widget _cardTextBlock({
    required int rank,
    required String name,
    required String percentile,
    required Color percentileColor,
    required int followers,
    required double pulse,
    required bool isTop,
    required bool isFirst,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _rankPill(rank, isFirst),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                percentile.isNotEmpty ? percentile : "Unranked",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: percentileColor,
                  fontSize: isFirst ? 25.5 : 24.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.75,
                  height: 1.0,
                  shadows: [
                    Shadow(
                      color: percentileColor.withOpacity(
                        isTop ? 0.22 + pulse * 0.10 : 0.12 + pulse * 0.05,
                      ),
                      blurRadius: isTop ? 16 : 10,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.people_alt_rounded,
              color: gold3.withOpacity(0.88),
              size: 21,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                "${_formatFollowers(followers)} followers",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.64),
                  fontSize: 16.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.18,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _rankPill(int rank, bool isFirst) {
    final label = rank > 0 ? "#$rank" : "#—";

    return Container(
      height: isFirst ? 32 : 29,
      constraints: const BoxConstraints(minWidth: 48),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _rankGradient(rank),
        ),
        border: Border.all(color: _rankBorderColor(rank)),
        boxShadow: [
          if (rank <= 3)
            BoxShadow(
              color: _rankBorderColor(rank).withOpacity(0.55),
              blurRadius: rank == 1 ? 18 : 12,
            ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _rankTextColor(rank),
          fontSize: isFirst ? 14.2 : 13,
          fontWeight: FontWeight.w900,
          height: 1.0,
          letterSpacing: -0.25,
        ),
      ),
    );
  }

  Widget _arrow(Color color, double intensity, double breathe, bool isFirst) {
    final glow = breathe * intensity;

    return Container(
      width: isFirst ? 45 : 43,
      height: isFirst ? 45 : 43,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.080 + glow * 0.034),
        border: Border.all(color: color.withOpacity(0.24 + glow * 0.08)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.075 + glow * 0.055),
            blurRadius: 17 + glow * 7,
          ),
        ],
      ),
      child: Icon(
        Icons.chevron_right_rounded,
        color: color,
        size: 28,
      ),
    );
  }

  Widget _avatar(
    String image,
    String name,
    Color tierColor,
    RelationTier tier,
    int index,
  ) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) {
        final wave = ((_pulseCtrl.value + (index * 0.17)) % 1.0);
        final breathe = math.sin(wave * math.pi);

        return Container(
          width: 68,
          height: 68,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [tierColor, gold3]),
            boxShadow: [
              BoxShadow(
                color: tierColor.withOpacity(0.16 + breathe * 0.09),
                blurRadius: 18 + breathe * 6,
              ),
            ],
          ),
          child: ClipOval(child: _avatarImage(image, name)),
        );
      },
    );
  }

  Widget _avatarImage(String image, String name) {
    if (image.isEmpty) return _avatarFallback(name);

    if (image.startsWith("http://") || image.startsWith("https://")) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _avatarFallback(name),
      );
    }

    if (image.startsWith("/")) {
      return Image.network(
        "${SocialApi.baseUrl}$image",
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _avatarFallback(name),
      );
    }

    final file = File(image);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _avatarFallback(name),
      );
    }

    return _avatarFallback(name);
  }

  Widget _avatarFallback(String name) {
    return Container(
      color: const Color(0xFF090D14),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : "U",
        style: const TextStyle(
          color: gold3,
          fontSize: 25,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _loadingList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      itemCount: 6,
      itemBuilder: (_, i) {
        return AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (context, _) {
            final g = _pulseCtrl.value;
            return Container(
              height: 112,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(31),
                color: Colors.white.withOpacity(0.026 + g * 0.010),
                border: Border.all(color: Colors.white.withOpacity(0.045)),
                boxShadow: [
                  BoxShadow(
                    color: gold.withOpacity(0.018 + g * 0.012),
                    blurRadius: 18,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _softLoadingState() {
    return Padding(
      padding: const EdgeInsets.only(top: 90),
      child: Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: gold3,
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 90),
      child: Column(
        children: [
          const Icon(Icons.person_search_rounded, color: gold3, size: 44),
          const SizedBox(height: 13),
          const Text(
            "No profiles found",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try another name.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.52),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PressableUserCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableUserCard({
    required this.child,
    required this.onTap,
  });

  @override
  State<_PressableUserCard> createState() => _PressableUserCardState();
}

class _PressableUserCardState extends State<_PressableUserCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.972 : 1.0,
        duration: const Duration(milliseconds: 115),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _down ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 115),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}