import 'package:flutter/material.dart';

import 'app_state.dart';
import 'welcome_flow.dart';
import 'access_choice_screen.dart';
import 'package:frontend/features/analysis/state/main_screen.dart';

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
                (context as Element).markNeedsBuild();
              },
            );

          case _EntryState.homeFree:
            return const MainScreen(isPremium: false);

          case _EntryState.homePremium:
            return const MainScreen(isPremium: true);
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