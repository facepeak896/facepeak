import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';



import 'package:frontend/features/analysis/screens/home_free_screen.dart';
import 'sign_in_screen.dart';
import 'name_screen.dart';
class AuthScreen extends StatefulWidget {
  final Function(String token) onSuccess;

  const AuthScreen({
    super.key,
    required this.onSuccess,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
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

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _bgShift = CurvedAnimation(
      parent: _bgController,
      curve: Curves.easeInOut,
    );

    _cardScale = Tween<double>(begin: 0.96, end: 1).animate(
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
  if (_loading) return;

  FocusScope.of(context).unfocus();

  final email = emailController.text.trim();
  final password = passwordController.text.trim();

  // ❌ VALIDACIJA
  if (email.isEmpty || password.isEmpty) {
    HapticFeedback.lightImpact();
    setState(() => _error = "Enter email and password");
    return;
  }

  if (!email.contains("@") || !email.contains(".")) {
    HapticFeedback.lightImpact();
    setState(() => _error = "Enter a valid email");
    return;
  }

  if (password.length < 6) {
    HapticFeedback.lightImpact();
    setState(() => _error = "Password must be at least 6 characters");
    return;
  }

  HapticFeedback.selectionClick();

  if (!mounted) return;

  // 🔥 IDE NA NAME SCREEN
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => NameScreen(
        email: email,
        password: password,
        onSuccess: (token) {
          widget.onSuccess(token);

          // 🔥 VRATI SE NA SOCIAL FLOW
          Navigator.of(context).pop();
        },
      ),
    ),
  );
}

  String _mapError(Object e) {
    final raw = e.toString().toUpperCase();

    if (raw.contains("INVALID_CREDENTIALS")) return "Invalid email or password";
    if (raw.contains("EMAIL_NOT_VERIFIED")) return "Verify your email first";
    if (raw.contains("PASSWORD_TOO_SHORT")) return "Password is too short";
    if (raw.contains("SIGNUP_FAILED")) return "Could not create account";
    if (raw.contains("LOGIN_FAILED")) return "Could not sign up";
    return "Something went wrong";
  }

  @override
Widget build(BuildContext context) {
  final keyboard = MediaQuery.of(context).viewInsets.bottom;
  final isKeyboardOpen = keyboard > 0;

  return Scaffold(
    backgroundColor: Colors.white,
    body: Stack(
      children: [
        AnimatedBuilder(
          animation: _bgShift,
          builder: (context, _) {
            final t = _bgShift.value;
            return Stack(
              children: [
                Positioned(
                  top: -140 + (t * 60),
                  left: -80 + (t * 40),
                  child: _GlowBlob(
                    size: 260,
                    color: Colors.black.withOpacity(0.055),
                  ),
                ),
                Positioned(
                  bottom: -120 + (t * 50),
                  right: -60 - (t * 30),
                  child: _GlowBlob(
                    size: 240,
                    color: Colors.grey.withOpacity(0.08),
                  ),
                ),
                Positioned(
                  top: 180 - (t * 30),
                  right: 20 + (t * 20),
                  child: _GlowBlob(
                    size: 140,
                    color: Colors.black.withOpacity(0.035),
                  ),
                ),
              ],
            );
          },
        ),

        SafeArea(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(
              left: 22,
              right: 22,
              top: isKeyboardOpen ? 18 : 40,
              bottom: keyboard > 0 ? 18 : 28,
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
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: 430,
                          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.78),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.05),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 40,
                                offset: const Offset(0, 18),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 52,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              const SizedBox(height: 20),

                              const Text(
                                "Continue",
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1.1,
                                  color: Colors.black,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 10),

                              Text(
                                "Log in or create your account instantly",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.35,
                                  color: Colors.black.withOpacity(0.55),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 26),

                              _AppleInput(
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

                              _AppleInput(
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
                                    setState(() {
                                      _obscure = !_obscure;
                                    });
                                  },
                                  child: Icon(
                                    _obscure
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    size: 20,
                                    color: Colors.black.withOpacity(0.42),
                                  ),
                                ),
                                onSubmitted: (_) => _submit(),
                              ),

                              const SizedBox(height: 14),

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

                              const SizedBox(height: 10),

                              _ContinueButton(
                                loading: _loading,
                                onTap: _loading ? null : _submit,
                              ),

                              const SizedBox(height: 14),

                              Text(
                                "If you don’t have an account, we’ll create one for you.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.35,
                                  color: Colors.black.withOpacity(0.42),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 8),
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

        // ❌ CLOSE
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 10, top: 6),
              child: IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeFreeScreen()),
                    (_) => false,
                  );
                },
                icon: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.72),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black.withOpacity(0.05),
                    ),
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

        // 🔥 SIGN IN FIX
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, top: 14),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SignInScreen(
                        onSuccess: widget.onSuccess, // 🔥 FIX
                      ),
                    ),
                  );
                },
                child: Text(
                  "Sign in",
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.75),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}}

class _AppleInput extends StatelessWidget {
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

  const _AppleInput({
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: focusNode.hasFocus
              ? Colors.black.withOpacity(0.12)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: Colors.black.withOpacity(0.38),
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
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.black.withOpacity(0.33),
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

class _ContinueButton extends StatefulWidget {
  final bool loading;
  final VoidCallback? onTap;

  const _ContinueButton({
    required this.loading,
    required this.onTap,
  });

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null) {
          setState(() => _pressed = true);
        }
      },
      onTapUp: (_) {
        if (widget.onTap != null) {
          setState(() => _pressed = false);
        }
      },
      onTapCancel: () {
        if (widget.onTap != null) {
          setState(() => _pressed = false);
        }
      },
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.mediumImpact();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: widget.loading
                ? const SizedBox(
                    key: ValueKey("loader"),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
              blurRadius: size * 0.55,
              spreadRadius: size * 0.08,
            ),
          ],
        ),
      ),
    );
  }
}