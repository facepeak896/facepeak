import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// SCREENS
import 'package:frontend/features/analysis/screens/home_free_screen.dart';
import 'package:frontend/features/social_free/social_features/dm_screen.dart';
import 'package:frontend/features/social_free/social_features/matches_screen.dart';
import 'package:frontend/features/social_free/social_flow_screen.dart';

// TAB BAR
import 'elite_tabs_free_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tabIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    // 🔥 INIT ONCE (NO REBUILD / NO RESET)
    _screens = [
      const HomeFreeScreen(),
      const DmScreen(),
      const MatchesScreen(),
      const SocialFlow(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: _screens,
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomTabBar(
          currentIndex: _tabIndex,
          onTabChange: (i) {
            if (i == _tabIndex) {
              HapticFeedback.selectionClick();
            } else {
              HapticFeedback.mediumImpact();
            }

            setState(() => _tabIndex = i);
          },
        ),
      ),
    );
  }
}