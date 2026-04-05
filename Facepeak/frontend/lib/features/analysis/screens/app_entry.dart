import 'package:flutter/material.dart';

import 'app_state.dart';
import 'welcome_flow.dart';
import 'access_choice_screen.dart';
import 'home_free_screen.dart';
import 'home_premium_screen.dart';

class AppEntry extends StatelessWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_EntryState>(
      future: _resolve(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final state = snapshot.data!;

        switch (state) {
          case _EntryState.welcome:
            return const WelcomeFlow();

          case _EntryState.accessChoice:
            return AccessChoiceScreen(
              onFinish: () {
                // samo trigger rebuild
                (context as Element).markNeedsBuild();
              },
            );

          case _EntryState.homeFree:
            return const HomeFreeScreen();

          case _EntryState.homePremium:
            return const HomePremiumScreen();
        }
      },
    );
  }

  Future<_EntryState> _resolve() async {
    final welcomeDone = await AppState.isWelcomeDone();
    if (!welcomeDone) return _EntryState.welcome;

    final access = await AppState.getAccessMode();
    if (access == null) return _EntryState.accessChoice;

    return access == 'premium'
        ? _EntryState.homePremium
        : _EntryState.homeFree;
  }
}

enum _EntryState {
  welcome,
  accessChoice,
  homeFree,
  homePremium,
}