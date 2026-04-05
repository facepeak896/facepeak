// 🔥 PREVIEW SCREEN — SAME AS SOCIAL HOME (PSL VERSION)

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// SCREENS
import 'search_screen.dart';
import 'analytics_screen.dart';
import 'matches_screen.dart';
import 'edit_profile_screen.dart';
import 'profile_views_screen.dart';
import 'settings_screen.dart';
import 'package:frontend/features/analysis/screens/home_free_screen.dart';

class PreviewScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic> psl;

  const PreviewScreen({
    super.key,
    required this.user,
    required this.psl,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen>
    with TickerProviderStateMixin {

  final storage = const FlutterSecureStorage();

  late final AnimationController _pulse;
  late final AnimationController _scoreAnim;

  Map<String, dynamic> _user = {};
  Map<String, dynamic> _psl = {};

  int _followers = 0;
  int _displayScore = 0;

  // 🎨 COLORS (IDENTIČNO)
  static const bg = Color(0xFF0B0E14);
  static const gold1 = Color(0xFFE7C26A);
  static const gold2 = Color(0xFFFFD37A);
  static const gold3 = Color(0xFFFFE3A2);

  static const editColor = Color(0xFF111827);
  static const analyticsColor = Color(0xFF1F2937);
  static const matchesColor = Color(0xFF7C3AED);
  static const purple = Color(0xFF7C3AED);

  @override
  void initState() {
    super.initState();

    _user = {...widget.user};
    _psl = {...widget.psl};

    _followers = _readInt(_user["followers"]);

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scoreAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _runScoreAnim();
  }

  void _runScoreAnim() {
    final target = (_psl["psl_score"] ?? 0).floor();

    _scoreAnim.addListener(() {
      setState(() {
        _displayScore = (target * _scoreAnim.value).floor();
      });
    });

    _scoreAnim.forward();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _scoreAnim.dispose();
    super.dispose();
  }

  int _readInt(dynamic v) => v is int ? v : int.tryParse("$v") ?? 0;

  // ================= RANGE =================

  String _rangeText() {
    double c = _psl["confidence"] ?? 0.5;

    double min;
    double max;

    if (c >= 0.9) {
      min = 0.1;
      max = 0.2;
    } else if (c >= 0.8) {
      min = 0.1;
      max = 0.25;
    } else if (c >= 0.7) {
      min = 0.1;
      max = 0.3;
    } else if (c >= 0.5) {
      min = 0.2;
      max = 0.4;
    } else {
      min = 0.3;
      max = 0.5;
    }

    return "+${min.toStringAsFixed(1)} → +${max.toStringAsFixed(1)} PSL";
  }

  // ================= BACK =================

  Future<bool> _handleExit() async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Are you sure?"),
        content: const Text(
          "You will lose your PSL try for the next 48 hours.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Stay"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Leave"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await storage.write(
        key: "psl_cooldown_until",
        value: DateTime.now()
            .add(const Duration(hours: 48))
            .toIso8601String(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeFreeScreen()),
      );
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleExit,
      child: Scaffold(
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

                _infoBox(), // 🔥 OVDE JE PROMJENA

                const Spacer(),

                _ctaCreate(), // 🔥 PROMJENA

              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= TOP =================

  Widget _topBar() {
    return Row(
      children: [
        _icon(Icons.arrow_back_ios_new, _handleExit),

        const Spacer(),

        _icon(Icons.remove_red_eye_outlined,
            () => _push(const ProfileViewsScreen())),

        const SizedBox(width: 12),

        _icon(Icons.search_rounded,
            () => _push(const SearchScreen())),

        const SizedBox(width: 12),

        _icon(Icons.favorite,
            () => _push(const MatchesScreen()),
            color: purple),

        const SizedBox(width: 12),

        _icon(Icons.menu,
            () => _push(const SettingsScreen())),
      ],
    );
  }

  // ================= AVATAR =================

  Widget _avatar() {
    final hasImage = _user["image"] != null;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glow = _pulse.value;

        return Stack(
          alignment: Alignment.center,
          children: [

            Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gold2.withOpacity(0.2 + glow * 0.2),
                    blurRadius: 40 + glow * 20,
                  )
                ],
              ),
            ),

            ClipOval(
              child: Container(
                width: 210,
                height: 210,
                color: Colors.black,
                child: hasImage
                    ? Image.file(File(_user["image"]), fit: BoxFit.cover)
                    : const Icon(Icons.person, color: Colors.white38, size: 90),
              ),
            ),
          ],
        );
      },
    );
  }

  // ================= USER =================

  Widget _username() {
    final tier = _psl["tier"] ?? "";
    final percentile = _psl["percentile"];

    return Column(
      children: [
        Text(
          _user["username"] ?? "User",
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text("$_displayScore", style: const TextStyle(color: gold2)),
        Text(tier, style: const TextStyle(color: Colors.white70)),
        if (percentile != null)
          Text("Top ${100 - percentile}%",
              style: const TextStyle(color: Colors.white38)),
      ],
    );
  }

  Widget _bio() {
    return Text(
      (_user["bio"] ?? ""),
      style: const TextStyle(color: Colors.white70),
    );
  }

  // ================= STATS =================

  Widget _stats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: purple.withOpacity(0.6)),
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
        Text("$v",
            style: const TextStyle(
                fontSize: 26,
                color: Colors.white,
                fontWeight: FontWeight.w900)),
        Text(l, style: const TextStyle(color: Colors.white54)),
      ],
    );
  }

  // ================= ACTIONS =================

  Widget _actions() {
    return Row(
      children: [
        Expanded(child: _btn("Edit", Icons.edit, () {}, editColor)),
        const SizedBox(width: 10),
        Expanded(child: _btn("Analytics", Icons.bar_chart, () {}, analyticsColor)),
        const SizedBox(width: 10),
        Expanded(child: _btn("Matches", Icons.favorite, () {}, matchesColor)),
      ],
    );
  }

  Widget _btn(String t, IconData i, VoidCallback f, Color color) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(i, color: Colors.white),
          const SizedBox(width: 6),
          Text(t, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  // ================= INFO =================

  Widget _infoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: gold1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("📊 Weekly Potential Range",
              style: TextStyle(color: Colors.white)),
          const SizedBox(height: 6),
          Text(_rangeText(), style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          const Text("🔒 Unlock full strategy",
              style: TextStyle(color: Colors.white)),
          const Text("Get Premium",
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          const Text("Improve lighting & angles",
              style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  // ================= CTA =================

  Widget _ctaCreate() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glow = _pulse.value;

        return GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => HomeFreeScreen(),
              ),
            );
          },
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(colors: [gold2, gold3]),
              boxShadow: [
                BoxShadow(
                  color: gold2.withOpacity(0.4 + glow * 0.3),
                  blurRadius: 30 + glow * 15,
                )
              ],
            ),
            child: const Center(
              child: Text(
                "CREATE PROFILE",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
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

  Widget _icon(IconData i, VoidCallback f, {Color color = Colors.white}) {
    return GestureDetector(
      onTap: f,
      child: Icon(i, color: color),
    );
  }

  Future<void> _push(Widget s) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => s));
  }
}