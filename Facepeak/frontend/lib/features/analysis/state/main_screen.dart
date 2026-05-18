import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/features/analysis/screens/home_free_screen.dart';
import 'package:frontend/features/analysis/screens/home_premium_screen.dart';
import 'package:frontend/features/analysis/screens/app_state.dart';

import 'package:frontend/features/social_free/social_features/dm_screen.dart';
import 'package:frontend/features/social_free/social_features/matches_screen.dart';
import 'package:frontend/features/social_free/social_features/search_screen.dart';

import 'package:frontend/features/social_free/social_features/dm_screen_preview_locked.dart';
import 'package:frontend/features/social_free/social_features/matches_screen_preview_locked.dart';
import 'package:frontend/features/social_free/social_features/search_screen_preview_locked.dart';

import 'package:frontend/features/social_free/social_flow_screen.dart';
import 'package:frontend/features/social_free/social_features/social_chat_socket_service.dart';
import 'package:frontend/features/social_free/services/social_badge_service.dart';

import 'elite_tabs_free_screen.dart';

class MainScreen extends StatefulWidget {
  final bool isPremium;

  const MainScreen({super.key, required this.isPremium});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tabIndex = 0;
  bool _showTabBar = true;
  bool _showSocialBadge = false;

  int _messageBadgeCount = 0;
  int _matchBadgeCount = 0;
  int _followBadgeCount = 0;

  static const String _socialBadgeSeenKey = "social_tab_badge_seen_v1";

  StreamSubscription<Map<String, dynamic>>? _socialSocketSub;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    5,
    (_) => GlobalKey<NavigatorState>(),
  );

  late final List<NavigatorObserver> _observers;

  String _socialSessionMarker = 'guest';

  @override
  void initState() {
    super.initState();

    _observers = List.generate(
      5,
      (_) => _TabRouteObserver(
        onChanged: _updateTabBarVisibility,
      ),
    );

    _initSocialSessionMarker();
    _initSocialBadge();
    _initGlobalSocialBadges();
    _refreshBadges();
  }

  @override
  void dispose() {
    _socialSocketSub?.cancel();
    super.dispose();
  }

  int _incBadge(int current) {
    if (current >= 99) return 99;
    return current + 1;
  }

  void _clearBadgeForTab(int index) {
    setState(() {
      if (index == 1) _messageBadgeCount = 0;
      if (index == 3) _matchBadgeCount = 0;
      if (index == 4) _followBadgeCount = 0;

      if (index == 1 || index == 2 || index == 3 || index == 4) {
        _showSocialBadge = false;
      }
    });
  }

  Future<void> _refreshBadges() async {
    try {
      final badges = await SocialBadgeService.getBadges();

      if (!mounted) return;

      setState(() {
        _messageBadgeCount =
            ((badges["dm_unread"] ?? 0) as num).toInt() +
                ((badges["message_requests"] ?? 0) as num).toInt();

        _matchBadgeCount = ((badges["match_requests"] ?? 0) as num).toInt();

        _followBadgeCount = ((badges["follow_events"] ?? 0) as num).toInt();
      });
    } catch (e) {
      debugPrint("❌ MAIN refresh badges failed: $e");
    }
  }

  void _applyBackendBadges(Map<String, dynamic> badges) {
    if (!mounted) return;

    setState(() {
      _messageBadgeCount =
          ((badges["dm_unread"] ?? 0) as num).toInt() +
              ((badges["message_requests"] ?? 0) as num).toInt();

      _matchBadgeCount = ((badges["match_requests"] ?? 0) as num).toInt();

      _followBadgeCount = ((badges["follow_events"] ?? 0) as num).toInt();
    });
  }

  Future<void> _initGlobalSocialBadges() async {
    try {
      await SocialChatSocketService.instance.connect();

      _socialSocketSub =
          SocialChatSocketService.instance.events.listen((event) {
        if (!mounted) return;

        final type = event["type"]?.toString() ?? "";

        final rawBadges = event["badges"];
        if (rawBadges is Map) {
          _applyBackendBadges(Map<String, dynamic>.from(rawBadges));
          return;
        }

        if (type == "badge_update" || type == "social_state_update") {
          _refreshBadges();
          return;
        }

        if (type == "new_message" ||
            type == "receive_message" ||
            type == "message_received" ||
            type == "dm_received" ||
            type == "message_request") {
          if (_tabIndex != 1) {
            setState(() {
              _messageBadgeCount = _incBadge(_messageBadgeCount);
            });
            HapticFeedback.lightImpact();
          }
          return;
        }

        if (type == "new_match" ||
            type == "match_created" ||
            type == "match_received" ||
            type == "new_like" ||
            type == "like_received" ||
            type == "request_received") {
          if (_tabIndex != 3) {
            setState(() {
              _matchBadgeCount = _incBadge(_matchBadgeCount);
            });
            HapticFeedback.mediumImpact();
          }
          return;
        }

        if (type == "new_follow" ||
            type == "follow_created" ||
            type == "follow_request" ||
            type == "new_follower" ||
            type == "profile_notification") {
          if (_tabIndex != 4) {
            setState(() {
              _followBadgeCount = _incBadge(_followBadgeCount);
            });
            HapticFeedback.mediumImpact();
          }
          return;
        }
      });
    } catch (e) {
      debugPrint("❌ MAIN badge socket failed: $e");
    }
  }

  Future<void> _initSocialBadge() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_socialBadgeSeenKey) ?? false;
    final isLive = await AppState.isSocialLive();

    if (!mounted) return;

    setState(() {
      _showSocialBadge = !seen && !isLive;
    });
  }

  Future<void> _markSocialBadgeSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_socialBadgeSeenKey, true);

    if (!mounted) return;

    setState(() {
      _showSocialBadge = false;
    });
  }

  Future<void> _initSocialSessionMarker() async {
    await _refreshSocialSessionMarker(force: true);
  }

  Future<void> _refreshSocialSessionMarker({bool force = false}) async {
    final token = await AppState.getToken();
    final nextMarker =
        (token == null || token.isEmpty) ? 'guest' : 'session_$token';

    if (!mounted) return;

    if (!force && nextMarker == _socialSessionMarker) return;

    setState(() {
      _socialSessionMarker = nextMarker;
      _navigatorKeys[4] = GlobalKey<NavigatorState>();
    });
  }

  Widget _socialGate({
    required String debugName,
    required Widget live,
    required Widget locked,
  }) {
    return FutureBuilder<bool>(
      future: AppState.isSocialLive(),
      builder: (context, snapshot) {
        final isLive = snapshot.data == true;

        debugPrint("❌❌❌ MAIN $debugName isLive = $isLive");

        return isLive ? live : locked;
      },
    );
  }

  Widget _buildRootScreen(int index) {
    switch (index) {
      case 0:
        return widget.isPremium
            ? const HomePremiumScreen()
            : const HomeFreeScreen();

      case 1:
        return _socialGate(
          debugName: "DM",
          live: const DmScreen(),
          locked: const DmScreenPreviewLocked(),
        );

      case 2:
        return _socialGate(
          debugName: "SEARCH",
          live: const SearchScreen(),
          locked: const SearchScreenPreviewLocked(),
        );

      case 3:
        return _socialGate(
          debugName: "MATCHES",
          live: const MatchesScreen(),
          locked: const MatchesScreenPreviewLocked(),
        );

      case 4:
        return KeyedSubtree(
          key: ValueKey(_socialSessionMarker),
          child: const SocialFlow(),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Future<bool> _onWillPop() async {
    final currentNavigator = _navigatorKeys[_tabIndex].currentState;

    if (currentNavigator != null && currentNavigator.canPop()) {
      currentNavigator.pop();
      return false;
    }

    if (_tabIndex != 0) {
      setState(() => _tabIndex = 0);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateTabBarVisibility();
      });

      return false;
    }

    return true;
  }

  Future<void> _handleTabChange(int i) async {
    _clearBadgeForTab(i);

    if (i == _tabIndex) {
      final nav = _navigatorKeys[i].currentState;

      if (nav != null) {
        nav.popUntil((route) => route.isFirst);
      }

      HapticFeedback.selectionClick();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateTabBarVisibility();
      });

      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _tabIndex = i;
    });

    if (i == 1 || i == 2 || i == 3 || i == 4) {
      _markSocialBadgeSeen();

      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        _refreshBadges();
      });
    }

    if (i == 4) {
      _refreshSocialSessionMarker();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTabBarVisibility();
    });
  }

  void _updateTabBarVisibility() {
    final nav = _navigatorKeys[_tabIndex].currentState;
    if (nav == null) return;

    final nextShowTabBar = !nav.canPop();

    if (_showTabBar == nextShowTabBar) return;

    setState(() {
      _showTabBar = nextShowTabBar;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        extendBody: true,
        backgroundColor: const Color(0xFF05070D),
        body: Stack(
          children: List.generate(5, (i) {
            return Offstage(
              offstage: _tabIndex != i,
              child: Navigator(
                key: _navigatorKeys[i],
                observers: [_observers[i]],
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (_) => _buildRootScreen(i),
                  );
                },
              ),
            );
          }),
        ),
        bottomNavigationBar: _showTabBar
            ? BottomTabBarElite(
                currentIndex: _tabIndex,
                showSocialBadge: _showSocialBadge,
                onSocialBadgeSeen: _markSocialBadgeSeen,
                messageBadgeCount: _messageBadgeCount,
                matchBadgeCount: _matchBadgeCount,
                followBadgeCount: _followBadgeCount,
                onMessageBadgeSeen: () {
                  if (!mounted) return;
                  _clearBadgeForTab(1);
                },
                onMatchBadgeSeen: () {
                  if (!mounted) return;
                  _clearBadgeForTab(3);
                },
                onFollowBadgeSeen: () {
                  if (!mounted) return;
                  _clearBadgeForTab(4);
                },
                onTabChange: _handleTabChange,
              )
            : null,
      ),
    );
  }
}

class _TabRouteObserver extends NavigatorObserver {
  final VoidCallback onChanged;

  _TabRouteObserver({required this.onChanged});

  @override
  void didPush(Route route, Route? previousRoute) {
    onChanged();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    onChanged();
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    onChanged();
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    onChanged();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}