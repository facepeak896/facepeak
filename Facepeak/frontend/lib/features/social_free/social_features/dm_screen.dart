import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DmScreen extends StatefulWidget {
  const DmScreen({super.key});

  @override
  State<DmScreen> createState() => _DmScreenState();
}

class _DmScreenState extends State<DmScreen> {
  static const bg = Color(0xFF0B0E14);
  static const card = Color(0xFF111827);
  static const accent = Color(0xFF7C3AED);

  final List<Map<String, dynamic>> chats = List.generate(12, (i) {
    return {
      "name": "User $i",
      "message": "Last message preview goes here...",
      "time": "12:${i}0",
      "unread": i % 3 == 0,
    };
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            const SizedBox(height: 10),
            _search(),
            const SizedBox(height: 10),
            Expanded(child: _chatList()),
          ],
        ),
      ),
    );
  }

  // ================= TOP =================

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text(
            "Messages",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          _icon(Icons.edit),
        ],
      ),
    );
  }

  Widget _icon(IconData icon) {
    return GestureDetector(
      onTap: () => HapticFeedback.selectionClick(),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  // ================= SEARCH =================

  Widget _search() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const TextField(
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Search",
            hintStyle: TextStyle(color: Colors.white38),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.white38),
          ),
        ),
      ),
    );
  }

  // ================= LIST =================

  Widget _chatList() {
    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, i) {
        final chat = chats[i];

        return GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _avatar(i),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat["name"],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chat["message"],
                        style: TextStyle(
                          color: chat["unread"]
                              ? Colors.white
                              : Colors.white54,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      chat["time"],
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (chat["unread"])
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= AVATAR =================

  Widget _avatar(int i) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7C3AED),
            Color(0xFF9333EA),
          ],
        ),
      ),
      child: Center(
        child: Text(
          "${i + 1}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}