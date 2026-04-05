import 'package:flutter/material.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

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
                "Report / Support",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "If you find a bug or have a question, you can contact us below.",
                style: TextStyle(
                  color: Color(0xFFB9C2D0),
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 30),

              _button(
                icon: Icons.bug_report_outlined,
                text: "Report a bug",
              ),

              const SizedBox(height: 14),

              _button(
                icon: Icons.email_outlined,
                text: "Send support email",
              ),

              const SizedBox(height: 14),

              _button(
                icon: Icons.feedback_outlined,
                text: "Send feedback",
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _button({
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
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

          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),

          const Spacer(),

          const Icon(
            Icons.chevron_right,
            color: Color(0xFF7D8796),
          ),

        ],
      ),
    );
  }
}