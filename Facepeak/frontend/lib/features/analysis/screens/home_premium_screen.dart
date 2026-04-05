// home_premium_screen.dart
import 'package:flutter/material.dart';

class HomePremiumScreen extends StatelessWidget {
  const HomePremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'HOME – PREMIUM',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.amber,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Full access unlocked',
              style: TextStyle(
                fontSize: 14,
                color: Color(0x99FFFFFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}