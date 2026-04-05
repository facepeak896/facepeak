import 'package:flutter/material.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Matches")),
      body: ListView.builder(
        itemCount: 8,
        itemBuilder: (_, i) => ListTile(
          leading: const CircleAvatar(),
          title: Text("Match $i"),
          subtitle: const Text("You matched"),
        ),
      ),
    );
  }
}