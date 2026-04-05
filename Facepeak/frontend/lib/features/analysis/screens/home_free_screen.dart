import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:frontend/features/analysis/screens/analyze_loading_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'appeal_explanation_screen.dart';
import 'settings_free_screen.dart';
import 'package:flutter/services.dart';
// ✅ KEEP: Free preparation screen (HOME must go here, NOT upload)
import 'appeal_free_preparation_screen.dart';
import 'analyze_appeal_loading_screen.dart';
// ✅ KEEP: PSL flow screen (whatever your PSL free screen is)
import 'psl_free_preparation_screen.dart';
import 'package:frontend/features/analysis/state/elite_tabs_free_screen.dart';

enum AnalysisChoice { psl, appeal }

class HomeFreeScreen extends StatefulWidget {
  final bool appealSuccess;

  const HomeFreeScreen({
    super.key,
    this.appealSuccess = false,
  });

  @override
  State<HomeFreeScreen> createState() => _HomeFreeScreenState();
}

class _HomeFreeScreenState extends State<HomeFreeScreen>
    with TickerProviderStateMixin {
  // =========================================================
  // CONFIG
  // =========================================================
  static const int kLimit = 2;
  static const Duration kCooldown = Duration(hours: 24);

  // =========================================================
  // THEME
  // =========================================================
  static const Color bg = Color(0xFF06070B);
  static const Color card = Color(0xFF11131A);
  static const Color text = Color(0xFFF4F7FF);
  static const Color muted = Color(0xFF9AA3B2);
  static const Color micro = Color(0xFF737D8E);
  static const Color border = Color(0x18FFFFFF);

  static const Color accentPSL = Color(0xFF92A5FF);
  static const Color accentPSLSoft = Color(0xFFC6D2FF);
  static const Color accentAppeal = Color(0xFFFFC85A);
  static const Color accentAppealSoft = Color(0xFFFFE4A3);

  static const double rCard = 26;

  // =========================================================
  // STATE (ONLY HOME KNOWS THIS)
  // =========================================================
  late String guestToken;

  AnalysisChoice? _activeChoice;
  DateTime? _cooldownEndsAt;
  int _used = 0;

  Timer? _ticker;
  bool _bootstrapped = false;

  // =========================================================
  // ANIMATION
  // =========================================================
  late final AnimationController _intro;
  late final AnimationController _ambient;
  late final AnimationController _ringGlow;
  late final Animation<double> _fadeIn;
  late final Animation<double> _slideIn;

  // =========================================================
  // PERSIST KEYS (HOME ONLY)
  // =========================================================
  static const String _kChoice = "home_free.active_choice";
  static const String _kEndsAt = "home_free.cooldown_ends_at";
  static const String _kUsed = "home_free.used";

  // =========================================================
  // LIFECYCLE
  // =========================================================
  @override
  void initState() {
    super.initState();

    print('');
    print('🏠 HOME initState');

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _ringGlow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _fadeIn = CurvedAnimation(
      parent: _intro,
      curve: Curves.easeOutCubic,
    );

    _slideIn = Tween<double>(
      begin: 18,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _intro,
        curve: Curves.easeOutCubic,
      ),
    );

    _intro.forward();

    _initGuestToken();
    _hydrate();
    _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _intro.dispose();
    _ambient.dispose();
    _ringGlow.dispose();
    super.dispose();
  }

  // =========================================================
  // ✅ GUEST TOKEN INIT
  // =========================================================
  Future<void> _initGuestToken() async {
    final prefs = await SharedPreferences.getInstance();

    guestToken =
        prefs.getString("guest_token") ??
        "guest_${DateTime.now().millisecondsSinceEpoch}";

    await prefs.setString("guest_token", guestToken);

    print("🔥 HOME guestToken = $guestToken");
  }

  // =========================================================
  // HYDRATE / SAVE
  // =========================================================
  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();

    final choiceStr = prefs.getString(_kChoice);
    final endsAtStr = prefs.getString(_kEndsAt);
    int used = prefs.getInt(_kUsed) ?? 0;

    AnalysisChoice? choice;
    if (choiceStr == "psl") choice = AnalysisChoice.psl;
    if (choiceStr == "appeal") choice = AnalysisChoice.appeal;

    DateTime? endsAt;
    if (endsAtStr != null) {
      endsAt = DateTime.tryParse(endsAtStr);
    }

    if (endsAt != null && DateTime.now().isAfter(endsAt)) {
      print('⏰ HYDRATE → cooldown expired');
      choice = null;
      endsAt = null;
      used = 0;
    }

    if (widget.appealSuccess == true) {
      print('✅ HYDRATE → APPLY APPEAL SUCCESS');
      used = (used + 1).clamp(0, kLimit);
      await prefs.setInt(_kUsed, used);
    }

    if (!mounted) return;

    setState(() {
      _activeChoice = choice;
      _cooldownEndsAt = endsAt;
      _used = used.clamp(0, kLimit);
      _bootstrapped = true;
    });

    print("💾💾💾 HYDRATE EXECUTED 💾💾💾");
    print("💾 choiceStr = $choiceStr");
    print("💾 parsed choice = $_activeChoice");
    print("💾 endsAtStr = $endsAtStr");
    print("💾 parsed endsAt = $_cooldownEndsAt");
    print("💾 FINAL used = $_used");
    print("💾💾💾💾💾💾💾💾💾💾💾");

    if (_cooldownEndsAt == null) {
      await _clearPersisted();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();

    print('💾 PERSIST → used=$_used, choice=$_activeChoice');

    if (_activeChoice == null || _cooldownEndsAt == null) {
      await _clearPersisted();
      return;
    }

    await prefs.setString(
      _kChoice,
      _activeChoice == AnalysisChoice.psl ? "psl" : "appeal",
    );

    await prefs.setString(
      _kEndsAt,
      _cooldownEndsAt!.toIso8601String(),
    );

    await prefs.setInt(_kUsed, _used);
  }

  Future<void> _clearPersisted() async {
    final prefs = await SharedPreferences.getInstance();

    print("🗑 CLEAR PERSISTED");

    await prefs.remove(_kChoice);
    await prefs.remove(_kEndsAt);
    await prefs.remove(_kUsed);
  }

  // =========================================================
  // TICKER
  // =========================================================
  void _startTicker() {
    _ticker?.cancel();

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_cooldownEndsAt != null &&
          DateTime.now().isAfter(_cooldownEndsAt!)) {
        print('⏰ COOLDOWN EXPIRED → RESET');

        setState(() {
          _cooldownEndsAt = null;
          _activeChoice = null;
          _used = 0;
        });

        unawaited(_clearPersisted());
        timer.cancel();
        return;
      }

      setState(() {});
    });
  }

  // =========================================================
  // DERIVED STATE
  // =========================================================
  bool get _cooldownActive => _cooldownEndsAt != null;
  bool get _hardLocked => _cooldownActive && _used >= kLimit;

  Duration get _remaining {
    if (_cooldownEndsAt == null) return Duration.zero;
    final d = _cooldownEndsAt!.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  // =========================================================
  // VISUAL LOCK LOGIC
  // =========================================================
  bool _isCardVisuallyLocked(AnalysisChoice cardChoice) {
    if (!_cooldownActive) return false;
    if (_hardLocked) return true;
    if (_activeChoice == null) return false;
    return cardChoice != _activeChoice;
  }

  // =========================================================
  // BADGE LOGIC
  // =========================================================
  String? _badgeFor(AnalysisChoice cardChoice) {
    if (cardChoice != AnalysisChoice.appeal) return null;
    return "${_used.clamp(0, kLimit)} / $kLimit";
  }

  // =========================================================
  // ACCENT HELPER
  // =========================================================
  Color _accentFor(AnalysisChoice c) =>
      c == AnalysisChoice.psl ? accentPSL : accentAppeal;

  Color _accentForSoft(AnalysisChoice c) =>
      c == AnalysisChoice.psl ? accentPSLSoft : accentAppealSoft;

  // =========================================================
  // CORE FLOW
  // =========================================================
  Future<void> _onTap(AnalysisChoice choice) async {
    HapticFeedback.lightImpact();

    print('');
    print('👆 TAP → $choice');
    print('STATE BEFORE → used=$_used cooldown=$_cooldownEndsAt');

    if (_used >= kLimit) {
      print('🔒 HARD LOCK → BLOCK');
      return;
    }

    if (!_cooldownActive) {
      final ends = DateTime.now().add(kCooldown);

      setState(() {
        _activeChoice = choice;
        _cooldownEndsAt = ends;
      });

      await _persist();
      print('🕒 COOLDOWN STARTED → $_cooldownEndsAt');
    }

    if (choice == AnalysisChoice.psl) {
      print('➡️ PUSH PSL FLOW');

      final bool? success = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => const PslPreparationScreen(),
        ),
      );

      print('⬅️ RETURNED PSL → success=$success');

      if (success == true && mounted) {
        setState(() {
          _used = (_used + 1).clamp(0, kLimit);
        });

        await _persist();
        print('✅ PSL SUCCESS → used=$_used');
      }

      return;
    }

    print('➡️ PUSH APPEAL PREPARATION');

    final File? imageFile = await Navigator.push<File?>(
      context,
      MaterialPageRoute(
        builder: (_) => AppealFreePreparationScreen(
          guestToken: guestToken,
        ),
      ),
    );

    print('⬅️ RETURNED PREP → file=$imageFile');

    if (imageFile == null || !mounted) {
      print('❌ APPEAL CANCELLED');
      return;
    }

    print('➡️ PUSH APPEAL LOADING');

    final bool? success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AnalyzeAppealLoadingScreen(
          imageFile: imageFile,
          onFinished: (_) {},
          onError: (_) {},
        ),
      ),
    );

    print('⬅️ RETURNED APPEAL LOADING → success=$success');
  }

  // =========================================================
  // TIME FORMAT
  // =========================================================
  String _formatRemaining(Duration d) {
    final totalSeconds = d.inSeconds.clamp(0, 999999999);
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  // =========================================================
  // UI
  // =========================================================
  @override
Widget build(BuildContext context) {
  if (!_bootstrapped) {
    return const Scaffold(
      backgroundColor: bg,
      body: SafeArea(child: SizedBox.expand()),
    );
  }

  return Scaffold(
    backgroundColor: bg,
    body: Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _ambient,
            builder: (context, _) {
              return CustomPaint(
                painter: _AppleStyleBackgroundPainter(
                  t: _ambient.value,
                ),
              );
            },
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.02),
                    Colors.transparent,
                    Colors.black.withOpacity(0.10),
                    Colors.black.withOpacity(0.26),
                  ],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: AnimatedBuilder(
            animation: _intro,
            builder: (context, _) {
              return Opacity(
                opacity: _fadeIn.value,
                child: Transform.translate(
                  offset: Offset(0, _slideIn.value),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TopBar(
                          onSettingsTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsFreeScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 34),
                        const _HeroBlock(),
                        const SizedBox(height: 28),
                        _AnalysisCard(
                          title: "PSL",
                          subtitle: "Structural score",
                          micro: "Bone geometry and proportions",
                          accent: accentPSL,
                          accentSoft: accentPSLSoft,
                          locked: _isCardVisuallyLocked(AnalysisChoice.psl),
                          badge: _badgeFor(AnalysisChoice.psl),
                          icon: Icons.architecture_rounded,
                          onTap: () => _onTap(AnalysisChoice.psl),
                        ),
                        const SizedBox(height: 16),
                        _AnalysisCard(
                          title: "Appeal",
                          subtitle: "Perceived attractiveness",
                          micro: "How your face reads today",
                          accent: accentAppeal,
                          accentSoft: accentAppealSoft,
                          locked:
                              _isCardVisuallyLocked(AnalysisChoice.appeal),
                          badge: _badgeFor(AnalysisChoice.appeal),
                          icon: Icons.visibility_rounded,
                          onTap: () => _onTap(AnalysisChoice.appeal),
                        ),
                        if (_cooldownActive) ...[
                          const SizedBox(height: 36),
                          const _CooldownDivider(),
                          const SizedBox(height: 22),
                          Center(
                            child: _CooldownRing(
                              accent: _activeChoice == null
                                  ? accentPSL
                                  : _accentFor(_activeChoice!),
                              accentSoft: _activeChoice == null
                                  ? accentPSLSoft
                                  : _accentForSoft(_activeChoice!),
                              remaining: _remaining,
                              total: kCooldown,
                              label: "Next choice available in",
                              timeText: _formatRemaining(_remaining),
                              glow: _ringGlow,
                            ),
                          ),
                        ],
                        const SizedBox(height: 26),
                        const _FootNote(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}}

// =========================================================
// TOP BAR
// =========================================================
class _TopBar extends StatelessWidget {
  final VoidCallback onSettingsTap;

  const _TopBar({
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          "FacePeak",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.2,
          ),
        ),
        const Spacer(),
        const _FreeModePill(),
        const SizedBox(width: 10),
        _TopIconButton(
          icon: Icons.settings_rounded,
          onTap: onSettingsTap,
        ),
      ],
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.045),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Icon(
            icon,
            size: 21,
            color: _HomeFreeScreenState.muted,
          ),
        ),
      ),
    );
  }
}

// =========================================================
// HERO
// =========================================================
class _HeroBlock extends StatelessWidget {
  const _HeroBlock();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Analyze your face",
          style: TextStyle(
            color: _HomeFreeScreenState.text,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            height: 1.03,
            letterSpacing: -0.8,
          ),
        ),
        SizedBox(height: 10),
        Text(
          "Select what you want to measure.",
          style: TextStyle(
            color: _HomeFreeScreenState.muted,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

// =========================================================
// FREE MODE PILL
// =========================================================
class _FreeModePill extends StatelessWidget {
  const _FreeModePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_clock_rounded,
            size: 13,
            color: _HomeFreeScreenState.accentPSL,
          ),
          SizedBox(width: 6),
          Text(
            "FREE MODE",
            style: TextStyle(
              color: _HomeFreeScreenState.accentPSL,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// COOLDOWN DIVIDER
// =========================================================
class _CooldownDivider extends StatelessWidget {
  const _CooldownDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.06),
          ),
        ),
        const SizedBox(width: 12),
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hourglass_top_rounded,
              size: 14,
              color: _HomeFreeScreenState.micro,
            ),
            SizedBox(width: 6),
            Text(
              "NEXT ANALYSIS",
              style: TextStyle(
                color: _HomeFreeScreenState.micro,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.06),
          ),
        ),
      ],
    );
  }
}

// =========================================================
// ANALYSIS CARD
// =========================================================
class _AnalysisCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String micro;
  final Color accent;
  final Color accentSoft;
  final String? badge;
  final bool locked;
  final VoidCallback onTap;
  final IconData icon;

  const _AnalysisCard({
    required this.title,
    required this.subtitle,
    required this.micro,
    required this.accent,
    required this.accentSoft,
    required this.locked,
    required this.onTap,
    required this.icon,
    this.badge,
  });

  @override
  State<_AnalysisCard> createState() => _AnalysisCardState();
}

class _AnalysisCardState extends State<_AnalysisCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  final trailing =
      widget.locked ? Icons.lock_rounded : Icons.chevron_right_rounded;

  return Listener(
    onPointerDown: (_) => _press.forward(),
    onPointerUp: (_) => _press.reverse(),
    onPointerCancel: (_) => _press.reverse(),
    child: AnimatedBuilder(
      animation: _press,
      builder: (context, _) {
        final scale = 1 - (_press.value * 0.014);

        return Transform.scale(
          scale: scale,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(_HomeFreeScreenState.rCard),
              onTap: widget.onTap,
              child: Ink(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(_HomeFreeScreenState.rCard),

                  /// NEW BACKGROUND (više kontrasta)
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _HomeFreeScreenState.card.withOpacity(0.98),
                      _HomeFreeScreenState.card.withOpacity(0.88),
                    ],
                  ),

                  /// JAČI BORDER
                  border: Border.all(
                    color: widget.accent.withOpacity(0.55),
                    width: 1.5,
                  ),

                  /// BRUTALNIJI GLOW
                  boxShadow: [
                    BoxShadow(
                      color: widget.accent.withOpacity(
                        0.35 + (_press.value * 0.45),
                      ),
                      blurRadius: 60,
                      spreadRadius: 4,
                      offset: const Offset(0, 20),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.55),
                      blurRadius: 36,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: widget.accent.withOpacity(0.14),
                        border: Border.all(
                          color: widget.accent.withOpacity(0.30),
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.accentSoft,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Opacity(
                        opacity: widget.locked ? 0.58 : 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    color: _HomeFreeScreenState.text,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                if (widget.locked) ...[
                                  const SizedBox(width: 7),
                                  Icon(
                                    Icons.lock_rounded,
                                    size: 15,
                                    color: Colors.white.withOpacity(0.50),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle,
                              style: TextStyle(
                                color: widget.accent,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.micro,
                              style: TextStyle(
                                color:
                                    _HomeFreeScreenState.micro.withOpacity(0.96),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (widget.badge != null)
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: widget.accent.withOpacity(0.18),
                        ),
                        child: Text(
                          widget.badge!,
                          style: TextStyle(
                            color: widget.accentSoft,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    Icon(
                      trailing,
                      size: 24,
                      color: Colors.white.withOpacity(
                        widget.locked ? 0.52 : 0.92,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}}
// =========================================================
// COOLDOWN RING
// =========================================================
class _CooldownRing extends StatelessWidget {
  final Color accent;
  final Color accentSoft;
  final Duration remaining;
  final Duration total;
  final String label;
  final String timeText;
  final Animation<double> glow;

  const _CooldownRing({
    required this.accent,
    required this.accentSoft,
    required this.remaining,
    required this.total,
    required this.label,
    required this.timeText,
    required this.glow,
  });

  double get _progress {
    final t = total.inSeconds == 0 ? 1 : total.inSeconds;
    final r = remaining.inSeconds.clamp(0, t);
    return r / t;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glow,
      builder: (context, _) {
        final pulse = glow.value;
        return Column(
          children: [
            SizedBox(
              width: 156,
              height: 156,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 156,
                    height: 156,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.06 + pulse * 0.06),
                          blurRadius: 24,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 142,
                    height: 142,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 7,
                      backgroundColor: Colors.white.withOpacity(0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.03),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              timeText,
              style: const TextStyle(
                color: _HomeFreeScreenState.text,
                fontSize: 25,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: _HomeFreeScreenState.micro.withOpacity(0.95),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );
      },
    );
  }
}

// =========================================================
// FOOT
// =========================================================
class _FootNote extends StatelessWidget {
  const _FootNote();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Use a neutral face and clear lighting for the most accurate result.",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _HomeFreeScreenState.micro.withOpacity(0.90),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
      ),
    );
  }
}

// =========================================================
// BACKGROUND
// =========================================================
class _AppleStyleBackgroundPainter extends CustomPainter {
  final double t;

  _AppleStyleBackgroundPainter({
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF06070B),
          Color(0xFF070910),
          Color(0xFF06070B),
        ],
      ).createShader(rect);

    canvas.drawRect(rect, base);

    final dx = math.sin(t * math.pi * 2) * 18;
    final dy = math.cos(t * math.pi * 2) * 12;

    final glowTop = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0x3392A5FF),
          Color(0x1492A5FF),
          Colors.transparent,
        ],
        stops: [0.0, 0.34, 0.82],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.78 + dx, size.height * 0.10 + dy),
          radius: size.width * 0.72,
        ),
      );

    canvas.drawCircle(
      Offset(size.width * 0.78 + dx, size.height * 0.10 + dy),
      size.width * 0.72,
      glowTop,
    );

    final glowBottom = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0x10FFC85A),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.18 - dx * 0.4, size.height * 0.88),
          radius: size.width * 0.55,
        ),
      );

    canvas.drawCircle(
      Offset(size.width * 0.18 - dx * 0.4, size.height * 0.88),
      size.width * 0.55,
      glowBottom,
    );
  }

  @override
  bool shouldRepaint(covariant _AppleStyleBackgroundPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}

// tiny helper to silence analyzer for fire-and-forget futures
void unawaited(Future<void> f) {}