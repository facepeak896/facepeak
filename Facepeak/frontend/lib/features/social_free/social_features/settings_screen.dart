import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:frontend/features/analysis/screens/app_state.dart';
import 'package:frontend/features/social_free/social_features/social_api.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color bg = Color(0xFF02050A);
  static const Color panel = Color(0xD00A101B);
  static const Color gold = Color(0xFFFFC34D);
  static const Color gold2 = Color(0xFFFFE7A8);
  static const Color purple = Color(0xFF7C3AED);
  static const Color red = Color(0xFFFF4D67);
  static const Color red2 = Color(0xFFFF7A8B);
  static const Color cyan = Color(0xFF8FD8FF);
  static const Color purple2 = Color(0xFFA855F7);

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _deleting = false;

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF111827),
      ),
    );
  }

  Future<void> _deleteAccountForever() async {
    if (_deleting) return;

    HapticFeedback.heavyImpact();

    setState(() => _deleting = true);

    try {
      final token = await AppState.getToken();

      if (token == null || token.isEmpty) {
        throw Exception("NO_TOKEN");
      }

      final res = await http.delete(
        Uri.parse("${SocialApi.baseUrl}/api/v1/account/me"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception("DELETE_ACCOUNT_FAILED_${res.statusCode}");
      }

      await _storage.deleteAll();

      try {
        await GoogleSignIn().signOut();
      } catch (_) {}

      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}

      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);

      _toast("Account permanently deleted");
    } catch (e) {
      debugPrint("❌ DELETE ACCOUNT ERROR = $e");

      if (!mounted) return;

      _toast("Could not delete account. Please try again.");
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  void _openDeleteConfirm() {
    HapticFeedback.heavyImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.78),
      isScrollControlled: true,
      builder: (_) {
        final bottom = MediaQuery.of(context).padding.bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(36),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                decoration: BoxDecoration(
                  color: const Color(0xF0060A12),
                  border: Border(
                    top: BorderSide(
                      color: red.withOpacity(0.28),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: red.withOpacity(0.18),
                      blurRadius: 44,
                      offset: const Offset(0, -18),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _handle(),
                      const SizedBox(height: 22),

                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: red.withOpacity(0.13),
                          border: Border.all(
                            color: red.withOpacity(0.26),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: red.withOpacity(0.20),
                              blurRadius: 34,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.delete_forever_rounded,
                          color: red,
                          size: 38,
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        "Delete forever?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 29,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.9,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "This permanently deletes your profile, messages, matches, followers, push tokens and social history.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.58),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          height: 1.28,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: _sheetButton(
                              text: "Cancel",
                              filled: false,
                              onTap: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _sheetButton(
                              text: "Delete",
                              filled: true,
                              danger: true,
                              onTap: () {
                                Navigator.pop(context);
                                _deleteAccountForever();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _handle() {
    return Container(
      width: 44,
      height: 5,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.18),
      ),
    );
  }

  static Widget _sheetButton({
    required String text,
    required bool filled,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: filled
              ? LinearGradient(
                  colors: danger ? [red, red2] : [gold, gold2],
                )
              : null,
          color: filled ? null : Colors.white.withOpacity(0.065),
          border: Border.all(
            color: filled ? Colors.transparent : Colors.white.withOpacity(0.10),
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: filled ? Colors.black : Colors.white.withOpacity(0.86),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          Positioned.fill(child: _background()),

          SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 28 + bottom),
              physics: const BouncingScrollPhysics(),
              children: [
                _top(context),
                const SizedBox(height: 26),
                _warningCard(),
                const SizedBox(height: 22),
                _deleteButton(),
              ],
            ),
          ),

          if (_deleting)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.72),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: red,
                    strokeWidth: 2.6,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _top(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.055),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            "Settings",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _warningCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(
              color: red.withOpacity(0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: red.withOpacity(0.10),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: red.withOpacity(0.13),
                  border: Border.all(
                    color: red.withOpacity(0.22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: red.withOpacity(0.18),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: red,
                  size: 38,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                "One account only",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.85,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "You can only use one account on this device or Google login. Deleting your account removes your data permanently.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.58),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  height: 1.32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deleteButton() {
    return GestureDetector(
      onTap: _deleting ? null : _openDeleteConfirm,
      child: AnimatedOpacity(
        opacity: _deleting ? 0.55 : 1,
        duration: const Duration(milliseconds: 180),
        child: Container(
          height: 64,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [red, red2],
            ),
            boxShadow: [
              BoxShadow(
                color: red.withOpacity(0.30),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete_forever_rounded,
                color: Colors.black,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                "DELETE ACCOUNT PERMANENTLY",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _background() {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: bg),
        ),
        Positioned(
          top: -170,
          left: -110,
          right: -110,
          child: Container(
            height: 430,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  red.withOpacity(0.16),
                  purple.withOpacity(0.065),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -190,
          left: -130,
          right: -130,
          child: Container(
            height: 450,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  gold.withOpacity(0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 260,
          right: -130,
          child: Container(
            width: 270,
            height: 270,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  cyan.withOpacity(0.055),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}