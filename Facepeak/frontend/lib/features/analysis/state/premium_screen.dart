import 'package:flutter/material.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF05070B),
      body: Center(
        child: Text(
          "Premium",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}