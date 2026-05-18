import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:frontend/features/social_free/services/social_match_service.dart';
import 'package:frontend/features/social_free/social_features/social_api.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with TickerProviderStateMixin {
  static const Color bg = Color(0xFF02050A);
  static const Color panel = Color(0xCC0A101B);
  static const Color gold = Color(0xFFFFC34D);
  static const Color gold2 = Color(0xFFFFE7A8);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purple2 = Color(0xFFA855F7);
  static const Color pink = Color(0xFFFF4FD8);
  static const Color cyan = Color(0xFF8FD8FF);

  static const int _limit = 30;

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _scroll = ScrollController();

  bool _loading = true;
  bool _actionLoading = false;
  bool _loadingMore = false;
  bool _hasMore = true;

  int _offset = 0;
  int? _lastOffsetRequested;

  String _query = "";

  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _matches = [];

  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _scroll.addListener(_onScroll);

    _searchFocus.addListener(() {
      if (!mounted) return;
      setState(() {});
    });

    _load();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scroll.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_loading) return;
    if (_loadingMore) return;
    if (!_hasMore) return;
    if (_query.trim().isNotEmpty) return;

    final pos = _scroll.position;

    if (pos.pixels >= pos.maxScrollExtent - 360) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);

    try {
      final incoming = await SocialMatchService.getIncomingRequests(
        limit: _limit,
        offset: 0,
      );

      final page = await SocialMatchService.getMatchesPage(
        limit: _limit,
        offset: 0,
      );

      final items = _items(page);

      if (!mounted) return;

      setState(() {
        _requests = incoming;
        _matches = items;
        _offset = (page["next_offset"] as num?)?.toInt() ?? items.length;
        _hasMore = page["has_more"] == true;
        _lastOffsetRequested = null;
        _loadingMore = false;
        _loading = false;
      });
    } catch (e, s) {
      debugPrint("❌ MATCHES_SCREEN load ERROR = $e");
      debugPrint("❌ MATCHES_SCREEN load STACK = $s");

      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading) return;
    if (_loadingMore) return;
    if (!_hasMore) return;
    if (_query.trim().isNotEmpty) return;

    final offset = _offset;

    if (_lastOffsetRequested == offset) return;

    _lastOffsetRequested = offset;

    setState(() => _loadingMore = true);

    try {
      final page = await SocialMatchService.getMatchesPage(
        limit: _limit,
        offset: offset,
      );

      final items = _items(page);

      final existingIds = _matches
          .map((m) => _safeId(m, ["match_id", "id"]))
          .where((id) => id > 0)
          .toSet();

      final fresh = items.where((m) {
        final id = _safeId(m, ["match_id", "id"]);
        return id > 0 && !existingIds.contains(id);
      }).toList();

      final nextOffset =
          (page["next_offset"] as num?)?.toInt() ?? offset + items.length;

      if (!mounted) return;

      setState(() {
        if (fresh.isNotEmpty) {
          _matches.addAll(fresh);
        }

        _offset = nextOffset;
        _hasMore = page["has_more"] == true && nextOffset > offset;
      });

      if (items.isEmpty || nextOffset <= offset) {
        if (!mounted) return;
        setState(() => _hasMore = false);
      }
    } catch (e, s) {
      debugPrint("❌ MATCHES_SCREEN loadMore ERROR = $e");
      debugPrint("❌ MATCHES_SCREEN loadMore STACK = $s");

      _lastOffsetRequested = null;
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _accept(int requestId) async {
    if (_actionLoading || requestId <= 0) return;

    HapticFeedback.mediumImpact();
    setState(() => _actionLoading = true);

    try {
      await SocialMatchService.acceptRequest(requestId: requestId);

      if (!mounted) return;

      _toast("Matched. Energy confirmed.");
      await _load();
    } catch (e, s) {
      debugPrint("❌ MATCHES_SCREEN accept ERROR = $e");
      debugPrint("❌ MATCHES_SCREEN accept STACK = $s");

      if (!mounted) return;
      _toast("Could not accept match");
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _reject(int requestId) async {
    if (_actionLoading || requestId <= 0) return;

    HapticFeedback.selectionClick();
    setState(() => _actionLoading = true);

    try {
      await SocialMatchService.rejectRequest(requestId: requestId);

      if (!mounted) return;

      _toast("Request declined");
      await _load();
    } catch (e, s) {
      debugPrint("❌ MATCHES_SCREEN reject ERROR = $e");
      debugPrint("❌ MATCHES_SCREEN reject STACK = $s");

      if (!mounted) return;
      _toast("Could not decline request");
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  List<Map<String, dynamic>> _items(Map<String, dynamic> page) {
    final raw = page["items"];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  dynamic _deepValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) return value;
    }

    final nestedKeys = [
      "user",
      "sender",
      "receiver",
      "target_user",
      "matched_user",
      "other_user",
      "profile",
    ];

    for (final nestedKey in nestedKeys) {
      final nested = data[nestedKey];
      if (nested is Map) {
        final nestedMap = Map<String, dynamic>.from(nested);
        for (final key in keys) {
          final value = nestedMap[key];
          if (value != null && value.toString().trim().isNotEmpty) {
            return value;
          }
        }
      }
    }

    return null;
  }

  int _safeId(Map<String, dynamic> data, List<String> keys) {
    final value = _deepValue(data, keys);
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? "") ?? 0;
  }

  String _name(Map<String, dynamic> user) {
    final raw = (_deepValue(user, [
              "username",
              "display_name",
              "name",
            ]) ??
            "User")
        .toString()
        .trim();

    return raw.isEmpty ? "User" : raw;
  }

  String _image(Map<String, dynamic> user) {
    final raw = (_deepValue(user, [
              "profile_image_url",
              "image_url",
              "avatar_url",
              "image",
              "local_image_path",
            ]) ??
            "")
        .toString()
        .trim();

    if (raw.isEmpty) return "";
    if (raw.startsWith("http://") || raw.startsWith("https://")) return raw;
    if (raw.startsWith("/")) return "${SocialApi.baseUrl}$raw";

    return raw;
  }

  String _matchLine(Map<String, dynamic> match, int index) {
    if (index == 0) return "Newest mutual energy";
    if (index <= 2) return "High-pull connection";
    if (index <= 7) return "Matched and waiting";
    return "Mutual interest locked in";
  }

  List<Map<String, dynamic>> get _filteredRequests {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _requests;

    return _requests.where((e) {
      return _name(e).toLowerCase().contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredMatches {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _matches;

    return _matches.where((e) {
      return _name(e).toLowerCase().contains(q) ||
          _matchLine(e, 0).toLowerCase().contains(q);
    }).toList();
  }

  void _clearSearch() {
    HapticFeedback.selectionClick();
    _searchCtrl.clear();
    _searchFocus.unfocus();
    setState(() => _query = "");
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF111827),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final requests = _filteredRequests;
    final matches = _filteredMatches;
    final hasContent = requests.isNotEmpty || matches.isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (_searchFocus.hasFocus) _searchFocus.unfocus();
      },
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            Positioned.fill(child: _background()),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _top(),
                    const SizedBox(height: 15),
                    _search(),
                    const SizedBox(height: 18),
                    Expanded(
                      child: _loading
                          ? _loadingState()
                          : RefreshIndicator(
                              color: gold2,
                              backgroundColor: const Color(0xFF080D15),
                              onRefresh: _load,
                              child: !hasContent
                                  ? _empty()
                                  : ListView(
                                      controller: _scroll,
                                      keyboardDismissBehavior:
                                          ScrollViewKeyboardDismissBehavior
                                              .onDrag,
                                      physics:
                                          const AlwaysScrollableScrollPhysics(
                                        parent: BouncingScrollPhysics(),
                                      ),
                                      padding: EdgeInsets.only(
                                        bottom: 118 + bottomSafe,
                                      ),
                                      children: [
                                        _heroStats(
                                          requestCount: requests.length,
                                          matchCount: matches.length,
                                        ),
                                        const SizedBox(height: 20),
                                        if (requests.isNotEmpty) ...[
                                          _sectionTitle(
                                            "Waiting on you",
                                            requests.length,
                                            Icons.bolt_rounded,
                                            true,
                                          ),
                                          const SizedBox(height: 14),
                                          ...List.generate(
                                            requests.length,
                                            (i) => _requestCard(requests[i], i),
                                          ),
                                          const SizedBox(height: 18),
                                        ],
                                        if (matches.isNotEmpty) ...[
                                          _sectionTitle(
                                            _query.trim().isEmpty
                                                ? "Your match circle"
                                                : "Search results",
                                            matches.length,
                                            Icons.favorite_rounded,
                                            false,
                                          ),
                                          const SizedBox(height: 14),
                                          ...List.generate(
                                            matches.length,
                                            (i) => _matchCard(matches[i], i),
                                          ),
                                        ],
                                        if (_loadingMore) ...[
                                          const SizedBox(height: 18),
                                          const Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: gold2,
                                                strokeWidth: 2.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _top() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Matches",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.1,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Mutual interest. No noise.",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.50),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        GestureDetector(
          onTap: _load,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              color: Colors.white.withOpacity(0.055),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: gold.withOpacity(0.055),
                  blurRadius: 18,
                ),
              ],
            ),
            child: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
        ),
      ],
    );
  }

  Widget _search() {
    final hasText = _query.trim().isNotEmpty;
    final focused = _searchFocus.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 190),
      curve: Curves.easeOutCubic,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          if (focused)
            BoxShadow(
              color: purple.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(23),
              border: Border.all(
                color: focused
                    ? gold2.withOpacity(0.18)
                    : Colors.white.withOpacity(0.075),
              ),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.060),
                  purple.withOpacity(focused ? 0.080 : 0.030),
                  Colors.white.withOpacity(0.025),
                ],
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: focused ? gold2 : Colors.white.withOpacity(0.38),
                  size: 22,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    cursorColor: gold2,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: -0.15,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Search names",
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.34),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                AnimatedScale(
                  scale: hasText ? 1 : 0.65,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutBack,
                  child: AnimatedOpacity(
                    opacity: hasText ? 1 : 0,
                    duration: const Duration(milliseconds: 120),
                    child: GestureDetector(
                      onTap: hasText ? _clearSearch : null,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withOpacity(0.78),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroStats({
    required int requestCount,
    required int matchCount,
  }) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) {
        final g = _pulseCtrl.value;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(1.15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: [
                gold2.withOpacity(0.28 + g * 0.04),
                pink.withOpacity(0.14),
                purple.withOpacity(0.20),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: gold.withOpacity(0.06 + g * 0.04),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(17, 16, 17, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(29),
              color: panel,
              border: Border.all(color: Colors.white.withOpacity(0.055)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [gold2, gold]),
                    boxShadow: [
                      BoxShadow(
                        color: gold.withOpacity(0.26),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.black,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    requestCount > 0
                        ? "$requestCount request${requestCount == 1 ? "" : "s"} waiting. Choose the energy."
                        : matchCount == 1
                            ? "1 mutual match in your circle."
                            : "$matchCount mutual matches in your circle.",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.35,
                      height: 1.15,
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

  Widget _sectionTitle(
    String title,
    int count,
    IconData icon,
    bool hot,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: hot ? gold2 : pink,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17.5,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.35,
          ),
        ),
        const SizedBox(width: 9),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: (hot ? gold : purple).withOpacity(0.16),
            border: Border.all(
              color: (hot ? gold2 : purple2).withOpacity(0.22),
            ),
          ),
          child: Text(
            count > 99 ? "99+" : count.toString(),
            style: const TextStyle(
              color: gold2,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _requestCard(Map<String, dynamic> req, int i) {
    final requestId = _safeId(req, ["request_id", "id"]);
    final img = _image(req);
    final name = _name(req);

    return _animatedEntry(
      i,
      Container(
        margin: const EdgeInsets.only(bottom: 17),
        padding: const EdgeInsets.all(1.15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(31),
          gradient: LinearGradient(
            colors: [
              gold2.withOpacity(0.70),
              pink.withOpacity(0.24),
              purple.withOpacity(0.26),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: gold.withOpacity(0.16),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.055)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _avatar(img, i, size: 68, hot: true),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.55,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              "Wants to match with you",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.58),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [pink, purple2],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: pink.withOpacity(0.28),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _smallAction(
                          label: "Decline",
                          icon: Icons.close_rounded,
                          filled: false,
                          onTap: requestId <= 0 ? null : () => _reject(requestId),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _smallAction(
                          label: "Match",
                          icon: Icons.check_rounded,
                          filled: true,
                          onTap: requestId <= 0 ? null : () => _accept(requestId),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _matchCard(Map<String, dynamic> match, int i) {
    final img = _image(match);
    final name = _name(match);

    return _animatedEntry(
      i,
      Container(
        margin: const EdgeInsets.only(bottom: 17),
        padding: const EdgeInsets.all(1.05),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(31),
          gradient: LinearGradient(
            colors: [
              i == 0 ? gold2.withOpacity(0.70) : gold.withOpacity(0.42),
              i <= 2 ? pink.withOpacity(0.22) : purple.withOpacity(0.20),
              Colors.white.withOpacity(0.055),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: (i == 0 ? gold : purple).withOpacity(0.13),
              blurRadius: 27,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: 108,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.045)),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.055),
                    purple.withOpacity(i <= 2 ? 0.055 : 0.025),
                    Colors.white.withOpacity(0.018),
                  ],
                ),
              ),
              child: Row(
                children: [
                  _avatar(img, i, size: 68, hot: i <= 2),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.55,
                                ),
                              ),
                            ),
                            if (i == 0) ...[
                              const SizedBox(width: 7),
                              const Icon(
                                Icons.auto_awesome_rounded,
                                color: gold2,
                                size: 15,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          _matchLine(match, i),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.57),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Mutual match",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: gold2.withOpacity(0.78),
                            fontSize: 12.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.07),
                      border: Border.all(
                        color: gold2.withOpacity(0.18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: gold.withOpacity(0.12),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: gold2,
                      size: 21,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallAction({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: _actionLoading ? null : onTap,
      child: AnimatedOpacity(
        opacity: _actionLoading ? 0.55 : 1,
        duration: const Duration(milliseconds: 160),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            gradient:
                filled ? const LinearGradient(colors: [gold, gold2]) : null,
            color: filled ? null : Colors.white.withOpacity(0.065),
            border: Border.all(
              color: filled
                  ? Colors.transparent
                  : Colors.white.withOpacity(0.10),
            ),
            boxShadow: [
              if (filled)
                BoxShadow(
                  color: gold.withOpacity(0.22),
                  blurRadius: 16,
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: filled ? Colors.black : Colors.white.withOpacity(0.82),
                size: 19,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: filled ? Colors.black : Colors.white.withOpacity(0.82),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(
    String img,
    int i, {
    required double size,
    required bool hot,
  }) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(1.8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: hot
              ? const [gold2, gold, pink, purple2, cyan, gold2]
              : const [gold2, gold, purple2, gold2],
        ),
        boxShadow: [
          BoxShadow(
            color: (hot ? pink : gold).withOpacity(0.21),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipOval(
        child: img.isNotEmpty
            ? Image.network(
                img,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarFallback(i, size),
              )
            : _avatarFallback(i, size),
      ),
    );
  }

  Widget _avatarFallback(int i, double size) {
    final colors = [
      [gold2, gold],
      [purple, purple2],
      [cyan, const Color(0xFF6EA8FF)],
      [pink, gold],
    ][i % 4];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: colors),
      ),
      child: Icon(
        Icons.person_rounded,
        color: Colors.black54,
        size: size * 0.52,
      ),
    );
  }

  Widget _animatedEntry(int i, Widget child) {
    return TweenAnimationBuilder<double>(
      key: ValueKey("match_entry_$i"),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + (i.clamp(0, 8) * 42)),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) {
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - v)),
            child: Transform.scale(
              scale: 0.985 + (v * 0.015),
              child: c,
            ),
          ),
        );
      },
      child: child,
    );
  }

  Widget _loadingState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 180),
        Center(child: CircularProgressIndicator(color: gold2)),
      ],
    );
  }

  Widget _empty() {
    final height = MediaQuery.of(context).size.height;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      children: [
        SizedBox(height: height * 0.15),
        Center(
          child: Column(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [gold, gold2]),
                  boxShadow: [
                    BoxShadow(
                      color: gold.withOpacity(0.25),
                      blurRadius: 26,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.black,
                  size: 37,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "No matches yet",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.55,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                "When the energy is mutual, it lands here.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
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
      builder: (context, _) {
        final g = _pulseCtrl.value;

        return Stack(
          children: [
            Positioned.fill(child: Container(color: bg)),
            Positioned(
              top: -170,
              left: -120,
              right: -120,
              child: Container(
                height: 390,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      purple.withOpacity(0.16 + g * 0.035),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 150,
              left: -130,
              right: -130,
              child: Container(
                height: 270,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      pink.withOpacity(0.065 + g * 0.025),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -180,
              left: -120,
              right: -120,
              child: Container(
                height: 390,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      gold.withOpacity(0.12 + g * 0.035),
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