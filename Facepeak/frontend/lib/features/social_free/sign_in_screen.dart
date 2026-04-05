import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'block.dart';
import 'package:frontend/features/analysis/screens/app_state.dart';

class SignInScreen extends StatefulWidget {
  final Function(String token) onSuccess;

  const SignInScreen({
    super.key,
    required this.onSuccess,
  });

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();

  late final AnimationController _bgController;
  late final AnimationController _cardController;
  late final Animation<double> _bgShift;
  late final Animation<double> _cardScale;
  late final Animation<double> _cardOpacity;

  bool _loading = false;
  String? _error;
  bool _obscure = true;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _bgShift = CurvedAnimation(
      parent: _bgController,
      curve: Curves.easeInOut,
    );

    _cardScale = Tween<double>(begin: 0.955, end: 1).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: Curves.easeOutCubic,
      ),
    );

    _cardOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: Curves.easeOut,
      ),
    );

    _cardController.forward();

    emailFocus.addListener(() => setState(() {}));
    passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    _bgController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
  FocusScope.of(context).unfocus();

  final email = emailController.text.trim();
  final password = passwordController.text.trim();

  if (email.isEmpty || password.isEmpty) {
    HapticFeedback.lightImpact();
    setState(() => _error = "Enter email and password");
    return;
  }

  setState(() {
    _loading = true;
    _error = null;
  });

  try {
    HapticFeedback.selectionClick();

    final res = await AuthApi.login(
      email: email,
      password: password,
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

    Navigator.of(context).pop();

  } catch (_) {
    HapticFeedback.lightImpact();
    setState(() => _error = "Invalid email or password");
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboard > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F4),
      body: Stack(
        children: [
          /// BACKGROUND
          AnimatedBuilder(
            animation: _bgShift,
            builder: (context, _) {
              final t = _bgShift.value;
              return Stack(
                children: [
                  Positioned(
                    top: -140 + (t * 70),
                    left: -100 + (t * 35),
                    child: _GlowBlob(
                      size: 300,
                      color: Colors.black.withOpacity(0.06),
                    ),
                  ),
                  Positioned(
                    bottom: -140 + (t * 45),
                    right: -80 - (t * 28),
                    child: _GlowBlob(
                      size: 260,
                      color: Colors.black.withOpacity(0.045),
                    ),
                  ),
                  Positioned(
                    top: 180 - (t * 30),
                    right: 30 + (t * 20),
                    child: _GlowBlob(
                      size: 160,
                      color: Colors.grey.withOpacity(0.08),
                    ),
                  ),
                ],
              );
            },
          ),

          /// CONTENT
          SafeArea(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: isKeyboardOpen ? 18 : 34,
                bottom: keyboard > 0 ? 18 : 30,
              ),
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: FadeTransition(
                    opacity: _cardOpacity,
                    child: ScaleTransition(
                      scale: _cardScale,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            width: 430,
                            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.black.withOpacity(0.06),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.10),
                                  blurRadius: 48,
                                  offset: const Offset(0, 22),
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 50,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),

                                const SizedBox(height: 18),

                                /// GENERIC SIGN IN LOGO
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFF4F4F6),
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.06),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 18,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.black.withOpacity(0.22),
                                            width: 1.6,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.login_rounded,
                                        size: 18,
                                        color: Colors.black.withOpacity(0.78),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 18),

                                const Text(
                                  "Sign in",
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -1.2,
                                    color: Color(0xFF0A0A0A),
                                    height: 1,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  "Access your profile in seconds",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.4,
                                    color: Colors.black.withOpacity(0.66),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F6),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.05),
                                    ),
                                  ),
                                  child: Text(
                                    "1 step away",
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.black.withOpacity(0.58),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                _EliteInput(
                                  controller: emailController,
                                  focusNode: emailFocus,
                                  hint: "Email",
                                  icon: Icons.alternate_email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  onSubmitted: (_) {
                                    passwordFocus.requestFocus();
                                  },
                                ),

                                const SizedBox(height: 14),

                                _EliteInput(
                                  controller: passwordController,
                                  focusNode: passwordFocus,
                                  hint: "Password",
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _obscure,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  suffix: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _obscure = !_obscure);
                                    },
                                    child: Icon(
                                      _obscure
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      size: 20,
                                      color: Colors.black.withOpacity(0.50),
                                    ),
                                  ),
                                  onSubmitted: (_) => _submit(),
                                ),

                                const SizedBox(height: 16),

                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  child: _error == null
                                      ? const SizedBox(height: 18)
                                      : SizedBox(
                                          height: 18,
                                          child: Text(
                                            _error!,
                                            key: ValueKey(_error),
                                            style: const TextStyle(
                                              color: Color(0xFFD93025),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                ),

                                const SizedBox(height: 8),

                                GestureDetector(
                                  onTapDown: (_) {
                                    if (!_loading) {
                                      setState(() => _pressed = true);
                                    }
                                  },
                                  onTapUp: (_) {
                                    if (!_loading) {
                                      setState(() => _pressed = false);
                                    }
                                  },
                                  onTapCancel: () {
                                    if (!_loading) {
                                      setState(() => _pressed = false);
                                    }
                                  },
                                  onTap: _loading ? null : _submit,
                                  child: AnimatedScale(
                                    scale: _pressed ? 0.978 : 1,
                                    duration: const Duration(milliseconds: 120),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      curve: Curves.easeOut,
                                      width: double.infinity,
                                      height: 58,
                                      decoration: BoxDecoration(
                                        color: _loading
                                            ? const Color(0xFF2A2A2A)
                                            : const Color(0xFF0A0A0A),
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.28),
                                            blurRadius: 30,
                                            offset: const Offset(0, 12),
                                          ),
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.10),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 220),
                                        child: _loading
                                            ? const SizedBox(
                                                key: ValueKey("loader"),
                                                width: 22,
                                                height: 22,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.3,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                                ),
                                              )
                                            : const Text(
                                                "Continue",
                                                key: ValueKey("text"),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 14),

                                Text(
                                  "Takes less than 10 seconds",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.35,
                                    color: Colors.black.withOpacity(0.48),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(height: 6),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          /// CLOSE
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 10, top: 8),
                child: IconButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                  },
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.88),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black.withOpacity(0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EliteInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<String>? autofillHints;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  const _EliteInput({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.suffix,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isFocused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFocused
              ? Colors.black.withOpacity(0.16)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: Colors.black.withOpacity(isFocused ? 0.72 : 0.52),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              autofillHints: autofillHints,
              onSubmitted: onSubmitted,
              cursorColor: const Color(0xFF111111),
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111111),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.black.withOpacity(0.45),
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          if (suffix != null) suffix!,
        ],
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
              spreadRadius: size * 0.10,
            ),
          ],
        ),
      ),
    );
  }
}