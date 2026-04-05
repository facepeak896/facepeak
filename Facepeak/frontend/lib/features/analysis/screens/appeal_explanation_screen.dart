import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_free_screen.dart';

class AppealExplanationScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const AppealExplanationScreen({
    super.key,
    required this.onContinue,
  });

  // ===== THEME =====
  static const Color bg = Color(0xFF0B0B0F);
  static const Color panel = Color(0xFF101018);

  static const Color gold = Color(0xFFF5C518);
  static const Color textHi = Color(0xFFFFFFFF);
  static const Color textMid = Color(0xCCFFFFFF);
  static const Color textDim = Color(0x99FFFFFF);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 🚫 disable back
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [
              // =====================
              // HEADER
              // =====================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Column(
                  children: const [
                    Text(
                      'Understanding Appeal',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: textHi,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Short explanation before you continue',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textDim,
                      ),
                    ),
                  ],
                ),
              ),

              // =====================
              // CONTENT
              // =====================
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _card(
                        title: 'What Appeal measures',
                        body:
                            'Appeal measures first visual impact.\n\n'
                            'It estimates how noticeable you are at first glance '
                            'in real life — before people analyze details.',
                        icon: Icons.visibility_rounded,
                      ),

                      const SizedBox(height: 14),

                      _card(
                        title: 'Important to understand',
                        body:
                            'Appeal is NOT overall attractiveness.\n\n'
                            'Some faces attract attention because they are '
                            'distinctive, expressive, or visually strong — '
                            'even if they are not classically “beautiful”.',
                        icon: Icons.info_outline_rounded,
                      ),

                      const SizedBox(height: 14),

                      _card(
                        title: 'Why results can surprise you',
                        body:
                            '• A less attractive person can score high\n'
                            '• A very attractive person can score average\n\n'
                            'Appeal is about attention, not beauty.',
                        icon: Icons.flash_on_rounded,
                      ),

                      const SizedBox(height: 14),

                      _card(
                        title: 'Photo matters a lot',
                        body:
                            'Appeal is sensitive to the photo.\n\n'
                            'For best results:\n'
                            '• Front-facing photo\n'
                            '• Neutral expression\n'
                            '• Good lighting\n\n'
                            'Bad angles or lighting can lower the score.',
                        icon: Icons.camera_alt_rounded,
                      ),

                      const SizedBox(height: 18),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: panel,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: const Text(
                          'Appeal measures attention — not your value.\n'
                          'It says nothing about you as a person.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: textDim,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // =====================
              // CONTINUE BUTTON
              // =====================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();

                      debugPrint(
                        '✅ EXPLANATION → PUSH HOME (appealSuccess=true)',
                      );

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HomeFreeScreen(
                            appealSuccess: true, // ⬅️ SIGNAL HOME-u
                          ),
                        ),
                        (_) => false,
                      );
                    },
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
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

  // =====================
  // CARD WIDGET
  // =====================
  Widget _card({
    required String title,
    required String body,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: gold, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: textHi,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: textMid,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}