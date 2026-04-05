// 🔥 SOCIAL HOME — FINAL CLEAN (LUXURY MINIMAL COLORS)

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

// SCREENS
import 'search_screen.dart';
import 'analytics_screen.dart';
import 'matches_screen.dart';
import 'edit_profile_screen.dart';
import 'create_post_entry_screen.dart';
import 'profile_views_screen.dart';
import 'settings_screen.dart';


class SocialHomeFreeScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const SocialHomeFreeScreen({
    super.key,
    required this.user,
  });

  @override
  State<SocialHomeFreeScreen> createState() => _SocialHomeFreeScreenState();
}

class _SocialHomeFreeScreenState extends State<SocialHomeFreeScreen>
    with TickerProviderStateMixin {

  late final AnimationController _pulse;
  late final AnimationController _shake;

  Map<String, dynamic> _user = {};
  int _followers = 0;

  // 🎨 COLORS
  static const bg = Color(0xFF0B0E14);

  // GOLD (CTA + glow)
  static const gold1 = Color(0xFFE7C26A);
  static const gold2 = Color(0xFFFFD37A);
  static const gold3 = Color(0xFFFFE3A2);

  // CLEAN COLORS
  static const editColor = Color(0xFF111827);
  static const analyticsColor = Color(0xFF1F2937);
  static const matchesColor = Color(0xFF7C3AED);

  static const purple = Color(0xFF7C3AED);

  @override
  void initState() {
    super.initState();

    _user = {...widget.user};
    _followers = _readInt(_user["followers"]);

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    _shake.dispose();
    super.dispose();
  }

  int _readInt(dynamic v) => v is int ? v : int.tryParse("$v") ?? 0;

  void _triggerShake() {
    if (_shake.isAnimating) return;
    _shake.forward(from: 0);
  }

  double _shakeOffset() {
    final t = _shake.value;
    return math.sin(t * math.pi * 6) * 6 * (1 - t);
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: bg,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Column(
          children: [

            _topBar(),

            const SizedBox(height: 18),

            _avatar(),

            const SizedBox(height: 14),

            _username(),

            const SizedBox(height: 6),

            _bio(),

            const SizedBox(height: 16),

            _stats(),

            const SizedBox(height: 14),

            _actions(),

            const SizedBox(height: 16),

            _infoBox(),

            const Spacer(),

            _ctaUpload(),

          ],
        ),
      ),
    ),
  );
}

  // ================= TOP =================

  Widget _topBar() {
  return Row(
    children: [

      // 🔙 BACK
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),

      const Spacer(),

      // 👁 PROFILE VIEWS
      _topIcon(
        Icons.remove_red_eye_outlined,
        () => _push(const ProfileViewsScreen()),
      ),

      const SizedBox(width: 10),

      // 🔍 SEARCH
      _topIcon(
        Icons.search_rounded,
        () => _push(const SearchScreen()),
      ),

      const SizedBox(width: 10),

      // ❤️ MATCHES
      _topIcon(
        Icons.favorite,
        () => _push(const MatchesScreen()),
        color: purple,
      ),

      const SizedBox(width: 10),

      // ☰ SETTINGS
      _topIcon(
        Icons.menu,
        () => _push(const SettingsScreen()),
      ),
    ],
  );
}
Widget _topIcon(IconData icon, VoidCallback onTap, {Color color = Colors.white}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 20,
        color: color,
      ),
    ),
  );
}

  // ================= AVATAR =================

  Widget _avatar() {
    final hasImage = _user["image"] != null;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _shake]),
      builder: (context, _) {
        final glow = _pulse.value;
        final offsetX = _shakeOffset();

        return Transform.translate(
          offset: Offset(offsetX, 0),
          child: GestureDetector(
            onTap: () {
              if (!hasImage) _triggerShake();
            },
            child: Stack(
              alignment: Alignment.center,
              children: [

                Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: gold2.withOpacity(0.15 + glow * 0.15),
                        blurRadius: 40 + glow * 15,
                      )
                    ],
                  ),
                ),

                ClipOval(
                  child: Stack(
                    children: [

                      Container(
                        width: 210,
                        height: 210,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF0B0E14),
                              Color(0xFF111827),
                            ],
                          ),
                        ),
                        child: hasImage
                            ? Image.file(
                                File(_user["image"]),
                                fit: BoxFit.cover,
                              )
                            : const Center(
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 90,
                                  color: Colors.white38,
                                ),
                              ),
                      ),

                      if (!hasImage)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.55),
                            child: const Center(
                              child: Icon(
                                Icons.lock_rounded,
                                size: 42,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= USER =================

  Widget _username() {
    return Text(
      _user["username"] ?? "User",
      style: const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w900,
        color: Colors.white,
      ),
    );
  }

  Widget _bio() {
    return Text(
      (_user["bio"] != null && _user["bio"].toString().isNotEmpty)
          ? _user["bio"]
          : "No bio yet",
      style: const TextStyle(
        fontSize: 15,
        color: Colors.white70,
      ),
    );
  }

  // ================= STATS =================

  Widget _stats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: purple.withOpacity(0.6)),
        color: Colors.black.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _stat(_readInt(_user["following"]), "Following"),
          _stat(_followers, "Followers"),
          _stat(_readInt(_user["matches"]), "Matches"),
        ],
      ),
    );
  }

  Widget _stat(int v, String l) {
    return Column(
      children: [
        Text(
          "$v",
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          l,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  // ================= ACTIONS =================

  Widget _actions() {
    return Row(
      children: [
        Expanded(child: _btn("Edit", Icons.edit, _openEdit, editColor)),
        const SizedBox(width: 10),
        Expanded(child: _btn("Analytics", Icons.bar_chart, () => _push(const AnalyticsScreen()), analyticsColor)),
        const SizedBox(width: 10),
        Expanded(child: _btn("Matches", Icons.favorite, () => _push(const MatchesScreen()), matchesColor)),
      ],
    );
  }

  Widget _btn(String t, IconData i, VoidCallback f, Color color) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glow = _pulse.value;

        return GestureDetector(
          onTap: f,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2 + glow * 0.2),
                  blurRadius: 20 + glow * 10,
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(i, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  t,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= INFO =================

  Widget _infoBox() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glow = _pulse.value;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: gold1.withOpacity(0.7)),
            color: Colors.black.withOpacity(0.25),
            boxShadow: [
              BoxShadow(
                color: gold1.withOpacity(0.1 + glow * 0.1),
                blurRadius: 20,
              )
            ],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("⭐ Upload → unlock score", style: TextStyle(color: Colors.white)),
              SizedBox(height: 6),
              Text("📈 Higher score = more reach", style: TextStyle(color: Colors.white70)),
              SizedBox(height: 6),
              Text("⚡ Boost matches instantly", style: TextStyle(color: Colors.white70)),
            ],
          ),
        );
      },
    );
  }

  // ================= CTA =================

  Widget _ctaUpload() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glow = _pulse.value;

        return GestureDetector(
          onTap: () => _push(const CreatePostScreen()),
          child: Container(
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(colors: [gold2, gold3]),
              boxShadow: [
                BoxShadow(
                  color: gold2.withOpacity(0.45 + glow * 0.35),
                  blurRadius: 30 + glow * 15,
                )
              ],
            ),
            child: const Center(
              child: Text(
                "GET YOUR PSL SCORE",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ================= NAV =================

  
  Future<void> _push(Widget s) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => s));
  }

  Future<void> _openEdit() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(user: _user),
    ));

    if (updated != null) {
      setState(() => _user = updated);
    }
  }
}