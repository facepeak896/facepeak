import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color bg = Color(0xFF05070B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "Profile",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              _card(
                icon: Icons.person_outline,
                title: "Account",
                subtitle: "User information",
              ),

              const SizedBox(height: 14),

              _card(
                icon: Icons.settings_outlined,
                title: "Settings",
                subtitle: "App preferences",
              ),

              const SizedBox(height: 14),

              _card(
                icon: Icons.workspace_premium_outlined,
                title: "Premium",
                subtitle: "Unlock advanced analysis",
              ),

              const SizedBox(height: 14),

              _card(
                icon: Icons.info_outline,
                title: "About FacePeak",
                subtitle: "Version & info",
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        children: [

          Icon(icon, color: const Color(0xFFE7C26A)),

          const SizedBox(width: 14),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF7D8796),
                  fontSize: 13,
                ),
              ),

            ],
          ),

          const Spacer(),

          const Icon(
            Icons.chevron_right,
            color: Color(0xFF7D8796),
          ),

        ],
      ),
    );
  }}