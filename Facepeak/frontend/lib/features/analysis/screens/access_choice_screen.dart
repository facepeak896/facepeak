import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_state.dart';


class AccessChoiceScreen extends StatelessWidget {
  final VoidCallback onFinish;

  const AccessChoiceScreen({
    super.key,
    required this.onFinish,
  });
  // ===== THEME =====
  static const Color bg = Color(0xFF07090D);
  static const Color card = Color(0xFF0E141D);

  static const Color text = Color(0xFFEAF0FF);
  static const Color muted = Color(0x88C7D2FF);

  static const Color gold = Color(0xFFF5C518);
  static const Color goldSoft = Color(0x22F5C518);
  static const Color goldStroke = Color(0x55F5C518);

  static const double rCard = 22;
  static const double rBtn = 18;

  @override
Widget build(BuildContext context) {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  return Scaffold(
    backgroundColor: bg,
    body: SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BrandHeader(),
              const SizedBox(height: 28),

              Text(
                'Choose your access level',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: text.withOpacity(0.96),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'This choice defines the scope of your analysis.\n'
                'You can change this later in Settings.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: muted,
                ),
              ),

              const SizedBox(height: 32),

              // ===== FREE MODE =====
              _AccessCard(
                title: 'FREE MODE',
                subtitle: 'Core evaluation',
                borderColor: Colors.white.withOpacity(0.14),
                badgeText: 'FREE',
                badgeColor: Colors.white.withOpacity(0.12),
                children: const [
                  _Bullet('AI Face Analysis'),
                  _Bullet('PSL score'),
                  _Bullet('Appeal score'),
                ],
                footer: 'Objective baseline evaluation.\nUpgrade anytime.',
                ctaText: 'Continue with Free Mode',
                ctaColor: Colors.white.withOpacity(0.10),
                ctaTextColor: text,
                onTap: () async {
                  HapticFeedback.lightImpact();

                  await AppState.setAccessMode('free');

                  if (!context.mounted) return;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    onFinish();
                  });
                },
              ),

              const SizedBox(height: 28),

              // ===== PREMIUM MODE =====
              _AccessCard(
                title: 'PREMIUM ACCESS',
                subtitle: 'Full analysis system',
                borderColor: goldStroke,
                badgeText: 'PREMIUM',
                badgeColor: goldSoft,
                badgeTextColor: gold,
                highlight: true,
                children: const [
                  _Bullet('AI Face Analysis (full)'),
                  _Bullet('Face Shape & Hair guidance'),
                  _Bullet('LooksMatch (non-human archetypes)'),
                  _Bullet('Glow-Up Plan (7 / 30 / 90 days)'),
                  _Bullet('Education & Explanation Hub'),
                  _Bullet('Personal coaching insights'),
                ],
                footer:
                    'Designed for users who want\nstructure, clarity, and direction.',
                price: '€6.99 / month\n€49.99 / year — Best value',
                ctaText: 'Unlock Premium Access',
                ctaColor: gold,
                ctaTextColor: Colors.black,
                onTap: () async {
                  HapticFeedback.mediumImpact();

                  await AppState.setAccessMode('premium');

                  if (!context.mounted) return;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    onFinish();
                  });
                },
              ),

              const SizedBox(height: 36),

              Text(
                'No filters. No celebrity comparisons.\n'
                'This system classifies structure.\n'
                'Improvement is optional.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: muted.withOpacity(0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}}
// ======================
// COMPONENTS
// ======================

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: AccessChoiceScreen.gold,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'FACEPEAK',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.6,
            color: AccessChoiceScreen.text.withOpacity(0.75),
          ),
        ),
      ],
    );
  }
}

class _AccessCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final String footer;
  final String ctaText;
  final Color ctaColor;
  final Color ctaTextColor;
  final VoidCallback onTap;

  final String badgeText;
  final Color badgeColor;
  final Color badgeTextColor;
  final Color borderColor;
  final bool highlight;
  final String? price;

  const _AccessCard({
    required this.title,
    required this.subtitle,
    required this.children,
    required this.footer,
    required this.ctaText,
    required this.ctaColor,
    required this.ctaTextColor,
    required this.onTap,
    required this.badgeText,
    required this.badgeColor,
    this.badgeTextColor = AccessChoiceScreen.text,
    required this.borderColor,
    this.highlight = false,
    this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AccessChoiceScreen.card,
        borderRadius: BorderRadius.circular(AccessChoiceScreen.rCard),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AccessChoiceScreen.text.withOpacity(0.95),
                  ),
                ),
                const Spacer(),
                _Badge(
                  text: badgeText,
                  bg: badgeColor,
                  color: badgeTextColor,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AccessChoiceScreen.muted,
              ),
            ),
            const SizedBox(height: 18),
            ...children,
            const SizedBox(height: 18),
            Text(
              footer,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: AccessChoiceScreen.muted.withOpacity(0.9),
              ),
            ),
            if (price != null) ...[
              const SizedBox(height: 14),
              Text(
                price!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AccessChoiceScreen.gold,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ctaColor,
                  foregroundColor: ctaTextColor,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AccessChoiceScreen.rBtn),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  ctaText,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AccessChoiceScreen.gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AccessChoiceScreen.text.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color color;

  const _Badge({
    required this.text,
    required this.bg,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }
}