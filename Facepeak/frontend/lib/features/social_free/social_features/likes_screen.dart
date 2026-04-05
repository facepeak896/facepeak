import 'package:flutter/material.dart';

class LikesScreen extends StatelessWidget {
  const LikesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Likes"),
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (_, i) => ListTile(
          leading: const CircleAvatar(),
          title: Text("User $i liked your profile"),
        ),
      ),
    );
  }
}