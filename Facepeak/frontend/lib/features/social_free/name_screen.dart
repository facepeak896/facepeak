import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'block.dart';
import 'package:frontend/features/analysis/screens/app_state.dart';

class NameScreen extends StatefulWidget {
  final String email;
  final String password;
  final Function(String token) onSuccess;

  const NameScreen({
    super.key,
    required this.email,
    required this.password,
    required this.onSuccess,
  });

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final usernameController = TextEditingController();
  final bioController = TextEditingController();

  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (_loading) return;

    FocusScope.of(context).unfocus();

    final username = usernameController.text.trim();

    if (username.isEmpty) {
      HapticFeedback.lightImpact();
      setState(() => _error = "Enter username");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      HapticFeedback.selectionClick();

      final res = await AuthApi.signup(
        email: widget.email,
        username: username,
        password: widget.password,
      );

      final token = res["access_token"];

      if (token == null || token.toString().isEmpty) {
        throw Exception("NO_TOKEN");
      }

      await AppState.setToken(token.toString());

      HapticFeedback.mediumImpact();

      if (!mounted) return;

      // 🔥 KLJUČNO
      widget.onSuccess(token.toString());

      // 🔥 SAMO POP — NIŠTA DRUGO
      Navigator.pop(context);

    } catch (e) {
      HapticFeedback.lightImpact();
      setState(() => _error = "Something went wrong");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E11),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -60,
            child: _GlowBlob(
              size: 300,
              color: const Color(0xFF7B61FF).withOpacity(0.35),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -60,
            child: _GlowBlob(
              size: 280,
              color: const Color(0xFF9F7CFF).withOpacity(0.25),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Choose your username",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "This will be your identity",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 40),

                  _Input(
                    controller: usernameController,
                    hint: "Username",
                    isPrimary: true,
                  ),

                  const SizedBox(height: 14),

                  _Input(
                    controller: bioController,
                    hint: "Bio (optional)",
                  ),

                  const SizedBox(height: 20),

                  if (_error != null)
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: _loading ? null : _submit,
                    child: Container(
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF7B61FF),
                            Color(0xFF9F7CFF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: _loading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              "Create profile",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isPrimary;

  const _Input({
    required this.controller,
    required this.hint,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isPrimary ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrimary
              ? const Color(0xFF7B61FF)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
          color: Colors.white,
          fontSize: isPrimary ? 18 : 15,
          fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.4),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBlob({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: size * 0.6,
              spreadRadius: size * 0.2,
            ),
          ],
        ),
      ),
    );
  }
}