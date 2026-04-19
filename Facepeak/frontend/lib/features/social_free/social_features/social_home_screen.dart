// 🔥 SOCIAL HOME — LOCKED FREE STATE (PRE-PSL)

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
  final Future<void> Function()? onRequireAuth;

  const SocialHomeFreeScreen({
    super.key,
    required this.user,
    this.onRequireAuth,
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
  String _readString(dynamic v) => v?.toString() ?? "";

  void _triggerShake() {
    if (_shake.isAnimating) return;
    _shake.forward(from: 0);
  }

  double _shakeOffset() {
    final t = _shake.value;
    return math.sin(t * math.pi * 6) * 6 * (1 - t);
  }

  bool get _hasImage {
    final image = _readString(_user["image"]).trim();
    return image.isNotEmpty;
  }

  String get _username {
    final username = _readString(_user["username"]).trim();
    return username.isEmpty ? "User" : username;
  }

  String get _bio {
    final bio = _readString(_user["bio"]).trim();
    return bio.isEmpty ? "No bio yet" : bio;
  }

  void _lockedTapFeedback() {
    _triggerShake();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF151922),
        content: const Text(
          "Unlock after your PSL score",
          style: TextStyle(color: Colors.white),
        ),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, bottomInset + 18),
          child: Column(
            children: [
              _topBar(),
              const SizedBox(height: 10),
              _avatar(),
              const SizedBox(height: 10),
              _usernameWidget(),
              const SizedBox(height: 4),
              _bioWidget(),
              const SizedBox(height: 12),
              _lockedStats(),
              const SizedBox(height: 12),
              _lockedActions(),
              const SizedBox(height: 12),
              _infoBox(),
              const SizedBox(height: 10),
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
      _topIconLocked(
        Icons.remove_red_eye_outlined,
        color: Colors.white,
      ),
      const SizedBox(width: 10),
      _topIconLocked(
        Icons.search_rounded,
        color: Colors.white,
      ),
      const SizedBox(width: 10),
      _topIconLocked(
        Icons.favorite,
        color: purple,
      ),
      const SizedBox(width: 10),
      _topIconLocked(
        Icons.menu,
        color: Colors.white,
      ),
    ],
  );
}

  Widget _topIcon(IconData icon, VoidCallback onTap,
      {Color color = Colors.white}) {
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

  Widget _topIconLocked(IconData icon, {Color color = Colors.white}) {
    return GestureDetector(
      onTap: _lockedTapFeedback,
      child: Opacity(
        opacity: 0.42,
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
      ),
    );
  }

  // ================= AVATAR =================

  Widget _avatar() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _shake]),
      builder: (context, _) {
        final glow = _pulse.value;
        final offsetX = _shakeOffset();

        return Transform.translate(
          offset: Offset(offsetX, 0),
          child: GestureDetector(
            onTap: _lockedTapFeedback,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 188,
                  height: 188,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: gold2.withOpacity(0.14 + glow * 0.14),
                        blurRadius: 34 + glow * 14,
                      ),
                    ],
                  ),
                ),
                ClipOval(
                  child: Stack(
                    children: [
                      Container(
                        width: 188,
                        height: 188,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF0B0E14),
                              Color(0xFF111827),
                            ],
                          ),
                        ),
                        child: _hasImage
                            ? Image.file(
                                File(_user["image"]),
                                fit: BoxFit.cover,
                              )
                            : const Center(
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 82,
                                  color: Colors.white38,
                                ),
                              ),
                      ),
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.52),
                          child: const Center(
                            child: Icon(
                              Icons.lock_rounded,
                              size: 40,
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

  Widget _usernameWidget() {
    return Text(
      _username,
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        height: 1.0,
      ),
    );
  }

  Widget _bioWidget() {
    return Text(
      _bio,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.white70,
        height: 1.0,
      ),
    );
  }

  // ================= LOCKED STATS =================

  Widget _lockedStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: purple.withOpacity(0.6)),
        color: Colors.black.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          _LockedStat(label: "Following"),
          _LockedStat(label: "Followers"),
          _LockedStat(label: "Matches"),
        ],
      ),
    );
  }

  // ================= ACTIONS =================

  Widget _lockedActions() {
    return Row(
      children: [
        Expanded(
          child: _btnLocked("Edit", Icons.edit, editColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _btnLocked("Analytics", Icons.bar_chart, analyticsColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _btnLocked("Matches", Icons.favorite, matchesColor),
        ),
      ],
    );
  }

  Widget _btnLocked(String t, IconData i, Color color) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glow = _pulse.value;

        return GestureDetector(
          onTap: _lockedTapFeedback,
          child: Opacity(
            opacity: 0.82,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.16 + glow * 0.14),
                    blurRadius: 16 + glow * 8,
                  ),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: gold1.withOpacity(0.72)),
            color: Colors.black.withOpacity(0.25),
            boxShadow: [
              BoxShadow(
                color: gold1.withOpacity(0.08 + glow * 0.08),
                blurRadius: 18,
              ),
            ],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                icon: Icons.lock_outline_rounded,
                text: "Your profile is hidden",
                color: Colors.white,
              ),
              SizedBox(height: 6),
              _InfoRow(
                icon: Icons.remove_red_eye_outlined,
                text: "Become visible to others",
                color: Colors.white70,
              ),
              SizedBox(height: 6),
              _InfoRow(
                icon: Icons.favorite,
                text: "Unlock search & matches",
                color: Colors.white70,
              ),
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

        return Column(
          children: [
            GestureDetector(
              onTap: () => _push(
                CreatePostScreen(
                  user: _user,
                ),
              ),
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(colors: [gold2, gold3]),
                  boxShadow: [
                    BoxShadow(
                      color: gold2.withOpacity(0.44 + glow * 0.32),
                      blurRadius: 28 + glow * 14,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    "UNLOCK YOUR PROFILE IN 10 SECONDS",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              "Required to use search, matches & visibility",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white60,
              ),
            ),
          ],
        );
      },
    );
  }

  // ================= NAV =================

  Future<void> _push(Widget s) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => s),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _user = {
          ..._user,
          ...result,
        };

        _followers = _readInt(_user["followers"]);
      });
    }
  }

  Future<void> _openEdit() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(user: _user)),
    );

    if (updated != null) {
      setState(() => _user = updated);
    }
  }
}

class _LockedStat extends StatelessWidget {
  final String label;

  const _LockedStat({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          size: 22,
          color: Colors.white70,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}