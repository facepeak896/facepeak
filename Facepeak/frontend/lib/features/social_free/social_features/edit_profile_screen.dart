import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  late final TextEditingController nicknameController;
  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<double> _slide;

  bool _saving = false;

  static const Color bg = Color(0xFF02050A);
  static const Color bg2 = Color(0xFF07111A);
  static const Color gold = Color(0xFFFFC34D);
  static const Color gold2 = Color(0xFFFFE7A8);
  static const Color panel = Color(0xCC0B1220);

  @override
  void initState() {
    super.initState();

    nicknameController = TextEditingController(
      text: _safeInitialName(
        widget.user["username"] ?? widget.user["display_name"],
      ),
    );

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);

    _slide = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
    );

    _anim.forward();
  }

  @override
  void dispose() {
    nicknameController.dispose();
    _anim.dispose();
    super.dispose();
  }

  String _safeInitialName(dynamic v) {
    final raw = v?.toString().trim() ?? "";
    final cleaned = raw.replaceAll(RegExp(r'[^a-zA-Z]'), "");

    if (cleaned.isEmpty || cleaned.toLowerCase() == "user") {
      return "";
    }

    return cleaned.length > 8
        ? cleaned.substring(0, 8)
        : cleaned;
  }

  String _formatName(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^a-zA-Z]'), "");

    if (cleaned.isEmpty) return "";

    final cut = cleaned.length > 8
        ? cleaned.substring(0, 8)
        : cleaned;

    return cut[0].toUpperCase() +
        cut.substring(1).toLowerCase();
  }

  bool get _canSave {
    final name = _formatName(nicknameController.text);
    return name.length >= 2 && !_saving;
  }

  Future<void> _save() async {
    if (!_canSave) {
      HapticFeedback.selectionClick();
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() => _saving = true);

    final nickname = _formatName(
      nicknameController.text,
    );

    await Future.delayed(
      const Duration(milliseconds: 450),
    );

    if (!mounted) return;

    Navigator.pop(context, {
      "username": nickname,
      "display_name": nickname,
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bg, bg2, bg],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: _backgroundFx(),
            ),

            SafeArea(
              child: FadeTransition(
                opacity: _fade,
                child: AnimatedBuilder(
                  animation: _slide,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slide.value),
                      child: child,
                    );
                  },
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      bottom + 24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            MediaQuery.of(context).size.height -
                                MediaQuery.of(context)
                                    .padding
                                    .top -
                                MediaQuery.of(context)
                                    .padding
                                    .bottom -
                                24,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.center,
                        children: [
                          _topBar(),

                          const SizedBox(height: 36),

                          _title(),

                          const SizedBox(height: 30),

                          _inputBox(),

                          const SizedBox(height: 14),

                          _rules(),

                          const SizedBox(height: 34),

                          _previewCard(),

                          const SizedBox(height: 28),

                          _saveButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backgroundFx() {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -90,
            right: -90,
            child: Container(
              height: 310,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    gold.withOpacity(0.11),
                    gold.withOpacity(0.025),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 260,
            left: -110,
            right: -110,
            child: Container(
              height: 330,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    gold2.withOpacity(0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 10,
                sigmaY: 10,
              ),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.055),
                  borderRadius:
                      BorderRadius.circular(18),
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

        const Spacer(),

        const Text(
          "Nickname",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),

        const Spacer(),

        const SizedBox(width: 46),
      ],
    );
  }

  Widget _title() {
    return Column(
      children: [
        const Text(
          "Choose your name",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
            height: 1,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          "Shown on your profile.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _inputBox() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 16,
          sigmaY: 16,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            18,
            8,
            18,
            8,
          ),
          decoration: BoxDecoration(
            color: panel,
            borderRadius:
                BorderRadius.circular(26),
            border: Border.all(
              color: gold.withOpacity(0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: gold.withOpacity(0.10),
                blurRadius: 26,
              ),
            ],
          ),
          child: TextField(
            controller: nicknameController,
            maxLength: 8,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.name,
            textCapitalization:
                TextCapitalization.words,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[a-zA-Z]'),
              ),
              LengthLimitingTextInputFormatter(8),
            ],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
            cursorColor: gold2,
            decoration: InputDecoration(
              counterText: "",
              hintText: "Name",
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.22),
                fontWeight: FontWeight.w900,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _rules() {
    return Text(
      "Only letters • max 8",
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white.withOpacity(0.48),
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _previewCard() {
    final name = _formatName(
      nicknameController.text,
    );

    final shown = name.isEmpty
        ? "User"
        : name;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.035),
        border: Border.all(
          color: Colors.white.withOpacity(0.065),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [gold, gold2],
              ),
              boxShadow: [
                BoxShadow(
                  color: gold.withOpacity(0.20),
                  blurRadius: 16,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              shown[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Text(
              shown,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
          ),

          Text(
            "${name.length}/8",
            style: TextStyle(
              color: name.length >= 2
                  ? gold2
                  : Colors.white38,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return GestureDetector(
      onTap: _canSave
          ? _save
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 58,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: _canSave
              ? const LinearGradient(
                  colors: [gold, gold2],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.045),
                  ],
                ),
          boxShadow: _canSave
              ? [
                  BoxShadow(
                    color: gold.withOpacity(0.26),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.black,
                ),
              )
            : Text(
                "Save Name",
                style: TextStyle(
                  color: _canSave
                      ? Colors.black
                      : Colors.white38,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
      ),
    );
  }
}