import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'appeal_free_rewarded_gate_screen.dart';

class AppealFreePreparationScreen extends StatelessWidget {
  final String guestToken;

  const AppealFreePreparationScreen({
    super.key,
    required this.guestToken,
  });

  // ===== THEME =====
  static const Color bg = Color(0xFF07090D);
  static const Color card = Color(0xFF0E141D);

  static const Color text = Color(0xFFEAF0FF);
  static const Color muted = Color(0x88C7D2FF);

  static const Color gold = Color(0xFFF5C518);
  static const Color goldSoft = Color(0x22F5C518);

  static const double rCard = 22;
  static const double rBtn = 18;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== HEADER =====
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: gold,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'APPEAL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.4,
                      color: text.withOpacity(0.75),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // ===== TITLE =====
              Text(
                'This is how\nyou look right now.',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  color: text,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'Not your potential.\n'
                'Not your structure.\n'
                'Just your current presence.',
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: muted,
                ),
              ),

              const SizedBox(height: 36),

              // ===== CORE CARD =====
              Container(
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(rCard),
                  border: Border.all(color: gold.withOpacity(0.35)),
                ),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _Point(
                      title: 'Appeal reacts',
                      subtitle: 'Lighting · grooming · expression · vibe',
                    ),
                    SizedBox(height: 14),
                    _Point(
                      title: 'One photo = one moment',
                      subtitle: 'Good day or bad day — both count',
                    ),
                    SizedBox(height: 14),
                    _Point(
                      title: 'This can change fast',
                      subtitle: 'Unlike structure, appeal is flexible',
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ===== EGO CHECK =====
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: goldSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'If this score surprises you — that’s normal.\n'
                  'Appeal measures perception, not worth.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                    color: gold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ===== CTA (NO LOGIC) =====
              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppealFreeRewardedGateScreen(
                          guestToken: guestToken,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(rBtn),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================
// COMPONENT
// ======================
class _Point extends StatelessWidget {
  final String title;
  final String subtitle;

  const _Point({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppealFreePreparationScreen.gold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppealFreePreparationScreen.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: AppealFreePreparationScreen.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}