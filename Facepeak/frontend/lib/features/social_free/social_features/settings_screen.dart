import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            _item(Icons.person, "Edit Profile"),
            _item(Icons.lock, "Privacy"),
            _item(Icons.notifications, "Notifications"),
            _item(Icons.help_outline, "Help"),
            _item(Icons.logout, "Logout", red: true),

          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String text, {bool red = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: red ? Colors.red : Colors.black),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: red ? Colors.red : Colors.black,
            ),
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
}