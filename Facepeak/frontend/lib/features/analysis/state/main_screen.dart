import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// FREE
import 'package:frontend/features/analysis/screens/home_free_screen.dart';
import 'package:frontend/features/analysis/screens/home_premium_screen.dart';
import 'package:frontend/features/analysis/screens/app_state.dart';

// SHARED
import 'package:frontend/features/social_free/social_features/dm_screen.dart';
import 'package:frontend/features/social_free/social_features/matches_screen.dart';
import 'package:frontend/features/social_free/social_flow_screen.dart';

// TAB BAR
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

  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    4,
    (_) => GlobalKey<NavigatorState>(),
  );

  late final List<NavigatorObserver> _observers;

  String _socialSessionMarker = 'guest';

  @override
  void initState() {
    super.initState();

    _observers = List.generate(
      4,
      (_) => _TabRouteObserver(
        onChanged: _updateTabBarVisibility,
      ),
    );

    _initSocialSessionMarker();
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

      // 🔥 reset ONLY social tab navigator when account/session changes
      _navigatorKeys[3] = GlobalKey<NavigatorState>();
    });
  }

  Widget _buildRootScreen(int index) {
    switch (index) {
      case 0:
        return widget.isPremium
            ? const HomePremiumScreen()
            : const HomeFreeScreen();

      case 1:
        return const DmScreen();

      case 2:
        return const MatchesScreen();

      case 3:
        return KeyedSubtree(
          key: ValueKey(_socialSessionMarker),
          child: const SocialFlow(),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Future<bool> _onWillPop() async {
    final currentNavigator = _navigatorKeys[_tabIndex].currentState!;

    if (currentNavigator.canPop()) {
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
    // 🔥 whenever entering social tab, sync with CURRENT account/session
    if (i == 3) {
      await _refreshSocialSessionMarker();
    }

    if (i == _tabIndex) {
      final nav = _navigatorKeys[i].currentState;
      if (nav != null) {
        nav.popUntil((route) => route.isFirst);
      }

      HapticFeedback.selectionClick();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateTabBarVisibility();
      });
    } else {
      HapticFeedback.mediumImpact();
      setState(() => _tabIndex = i);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateTabBarVisibility();
      });
    }
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
          children: List.generate(4, (i) {
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
                onTabChange: (i) {
                  _handleTabChange(i);
                },
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