import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_free_screen.dart';
import 'psl_free_rewarded_gate_screen.dart';

class HomeFreeScreen extends StatefulWidget {
  const HomeFreeScreen({super.key});

  @override
  State<HomeFreeScreen> createState() => _HomeFreeScreenState();
}

class _HomeFreeScreenState extends State<HomeFreeScreen>
    with TickerProviderStateMixin {
  static const Color bg = Color(0xFF03030A);
  static const Color bg2 = Color(0xFF080513);
  static const Color ink = Color(0xFFF8F7FF);
  static const Color muted = Color(0xFF9A96AD);

  static const Color violet = Color(0xFF7C3DFF);
  static const Color violet2 = Color(0xFFA987FF);
  static const Color violet3 = Color(0xFFE7DAFF);
  static const Color gold = Color(0xFFFFD88A);

  static const String _kLocked = "home_free_locked";
  static const String _kCooldownUntil = "home_free_cooldown_until";
  static const String _kUsed = "home_free_used";
  static const String _kLimit = "home_free_limit";

  late final AnimationController _intro;
  late final AnimationController _ambient;
  late final AnimationController _scan;
  late final AnimationController _orbit;
  late final AnimationController _pulse;

  late final Animation<double> _fade;
  late final Animation<double> _slide;

  Timer? _ticker;

  bool _bootstrapped = false;
  bool _locked = false;
  int _used = 0;
  int _limit = 1;
  DateTime? _cooldownUntil;

  Duration get _remaining {
    if (_cooldownUntil == null) return Duration.zero;
    final d = _cooldownUntil!.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  bool get _isLocked => _locked && _remaining > Duration.zero;

  @override
  void initState() {
    super.initState();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );

    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _scan = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7800),
    )..repeat();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _fade = CurvedAnimation(
      parent: _intro,
      curve: Curves.easeOutCubic,
    );

    _slide = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(
        parent: _intro,
        curve: Curves.easeOutCubic,
      ),
    );

    _intro.forward();
    _hydrate();
    _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _intro.dispose();
    _ambient.dispose();
    _scan.dispose();
    _orbit.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();

    final locked = prefs.getBool(_kLocked) ?? false;
    final used = prefs.getInt(_kUsed) ?? 0;
    final limit = prefs.getInt(_kLimit) ?? 1;
    final rawUntil = prefs.getString(_kCooldownUntil);

    DateTime? until;
    if (rawUntil != null && rawUntil.isNotEmpty) {
      until = DateTime.tryParse(rawUntil)?.toLocal();
    }

    if (until != null && DateTime.now().isAfter(until)) {
      await _clearLock();

      if (!mounted) return;

      setState(() {
        _locked = false;
        _used = 0;
        _limit = 1;
        _cooldownUntil = null;
        _bootstrapped = true;
      });
      return;
    }

    if (!mounted) return;

    setState(() {
      _locked = locked;
      _used = used;
      _limit = limit <= 0 ? 1 : limit;
      _cooldownUntil = until;
      _bootstrapped = true;
    });
  }

  Future<void> _clearLock() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_kLocked);
    await prefs.remove(_kCooldownUntil);
    await prefs.remove(_kUsed);
    await prefs.remove(_kLimit);
  }

  void _startTicker() {
    _ticker?.cancel();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;

      if (_cooldownUntil != null && DateTime.now().isAfter(_cooldownUntil!)) {
        await _clearLock();

        if (!mounted) return;

        setState(() {
          _locked = false;
          _used = 0;
          _limit = 1;
          _cooldownUntil = null;
        });
        return;
      }

      if (_isLocked) setState(() {});
    });
  }

  String _formatRemaining(Duration d) {
    final total = d.inSeconds.clamp(0, 99999999);
    final h = (total ~/ 3600).toString().padLeft(2, '0');
    final m = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  double _cooldownProgress() {
    const total = 24 * 60 * 60;
    final remaining = _remaining.inSeconds.clamp(0, total);
    return remaining / total;
  }

  void _openSettings() {
    HapticFeedback.selectionClick();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsFreeScreen()),
    );
  }

  void _openPslFlow() {
    if (_isLocked) {
      HapticFeedback.mediumImpact();
      return;
    }

    HapticFeedback.lightImpact();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PslEliteGateScreen()),
    ).then((_) {
      if (mounted) _hydrate();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_bootstrapped) {
      return const Scaffold(
        backgroundColor: bg,
        body: SizedBox.expand(),
      );
    }

    final media = MediaQuery.of(context);
    final h = media.size.height;
    final compact = h < 720;
    final heroSize = math.min(media.size.width * 0.78, compact ? 270.0 : 320.0);

    return MediaQuery(
      data: media.copyWith(textScaler: const TextScaler.linear(1.0)),
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ambient,
                builder: (_, __) {
                  return CustomPaint(
                    painter: _BackgroundPainter(t: _ambient.value),
                  );
                },
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fade,
                child: AnimatedBuilder(
                  animation: _slide,
                  builder: (_, child) {
                    return Transform.translate(
                      offset: Offset(0, _slide.value),
                      child: child,
                    );
                  },
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      22,
                      compact ? 14 : 18,
                      22,
                      28 + media.padding.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _topBar(),
                        SizedBox(height: compact ? 26 : 34),
                        _HeroChamber(
                          size: heroSize,
                          locked: _isLocked,
                          scan: _scan,
                          orbit: _orbit,
                          pulse: _pulse,
                        ),
                        SizedBox(height: compact ? 28 : 34),
                        _headline(),
                        const SizedBox(height: 18),
                        _ScanActionCard(
                          locked: _isLocked,
                          used: _isLocked ? _used.clamp(1, _limit) : 0,
                          limit: _limit,
                          pulse: _pulse,
                          onTap: _openPslFlow,
                        ),
                        if (_isLocked) ...[
                          const SizedBox(height: 22),
                          _CooldownStrip(
                            progress: _cooldownProgress(),
                            timeText: _formatRemaining(_remaining),
                            pulse: _pulse,
                          ),
                        ],
                        const SizedBox(height: 18),
                        _footer(),
                      ],
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

  Widget _topBar() {
    return Row(
      children: [
        const Text(
          "FacePeak",
          style: TextStyle(
            color: ink,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.25,
          ),
        ),
        const Spacer(),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withOpacity(0.055),
                border: Border.all(
                  color: Colors.white.withOpacity(0.075),
                ),
              ),
              child: const Text(
                "FREE",
                style: TextStyle(
                  color: violet3,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.9,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _openSettings,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.055),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.075),
                  ),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: muted,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _headline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "PSL Scan",
          style: TextStyle(
            color: ink,
            fontSize: 40,
            fontWeight: FontWeight.w900,
            height: 0.98,
            letterSpacing: -1.25,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLocked ? "Result saved" : "Structural analysis ready",
          style: TextStyle(
            color: Colors.white.withOpacity(0.52),
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }

  Widget _footer() {
    return Center(
      child: Text(
        "Clear face • neutral angle • no filters",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: muted.withOpacity(0.76),
          fontSize: 12,
          height: 1.3,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

class _HeroChamber extends StatelessWidget {
  final double size;
  final bool locked;
  final Animation<double> scan;
  final Animation<double> orbit;
  final Animation<double> pulse;

  const _HeroChamber({
    required this.size,
    required this.locked,
    required this.scan,
    required this.orbit,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([scan, orbit, pulse]),
        builder: (_, __) {
          final p = pulse.value;
          final scanY = size * (0.24 + scan.value * 0.52);

          return SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: size * 0.92,
                  height: size * 0.92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _HomeFreeScreenState.violet.withOpacity(
                          locked ? 0.10 : 0.22 + p * 0.08,
                        ),
                        blurRadius: 90,
                        spreadRadius: 8,
                      ),
                      BoxShadow(
                        color: _HomeFreeScreenState.gold.withOpacity(0.055),
                        blurRadius: 110,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                RotationTransition(
                  turns: orbit,
                  child: CustomPaint(
                    size: Size(size * 0.86, size * 0.86),
                    painter: _OrbitPainter(
                      color: _HomeFreeScreenState.violet2.withOpacity(0.62),
                      bright: _HomeFreeScreenState.violet3.withOpacity(0.95),
                    ),
                  ),
                ),
                RotationTransition(
                  turns: Tween<double>(begin: 1, end: 0).animate(orbit),
                  child: CustomPaint(
                    size: Size(size * 0.68, size * 0.68),
                    painter: _InnerOrbitPainter(
                      color: _HomeFreeScreenState.gold.withOpacity(0.34),
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(size * 0.155),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      width: size * 0.63,
                      height: size * 0.63,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(size * 0.155),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.105),
                            _HomeFreeScreenState.violet.withOpacity(0.075),
                            Colors.black.withOpacity(0.18),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.105),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.38),
                            blurRadius: 34,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _ChamberGridPainter(
                                color: Colors.white.withOpacity(0.045),
                                accent: _HomeFreeScreenState.violet3
                                    .withOpacity(0.13),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: scanY * 0.63 - 36,
                            child: Container(
                              height: 72,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    _HomeFreeScreenState.violet2
                                        .withOpacity(0.035),
                                    _HomeFreeScreenState.violet3
                                        .withOpacity(0.125),
                                    _HomeFreeScreenState.gold
                                        .withOpacity(0.055),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 22,
                            right: 22,
                            top: scanY * 0.63,
                            child: Container(
                              height: 2.4,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    _HomeFreeScreenState.violet2,
                                    _HomeFreeScreenState.violet3,
                                    _HomeFreeScreenState.gold,
                                    _HomeFreeScreenState.violet3,
                                    Colors.transparent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _HomeFreeScreenState.violet2
                                        .withOpacity(0.55),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: Icon(
                                locked
                                    ? Icons.lock_rounded
                                    : Icons.face_retouching_natural_rounded,
                                key: ValueKey(locked),
                                color: _HomeFreeScreenState.violet3,
                                size: size * 0.17,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: size * 0.06,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.black.withOpacity(0.34),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Text(
                      locked ? "LOCKED" : "READY",
                      style: const TextStyle(
                        color: _HomeFreeScreenState.violet3,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.25,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ScanActionCard extends StatefulWidget {
  final bool locked;
  final int used;
  final int limit;
  final Animation<double> pulse;
  final VoidCallback onTap;

  const _ScanActionCard({
    required this.locked,
    required this.used,
    required this.limit,
    required this.pulse,
    required this.onTap,
  });

  @override
  State<_ScanActionCard> createState() => _ScanActionCardState();
}

class _ScanActionCardState extends State<_ScanActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
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
    return Listener(
      onPointerDown: (_) {
        if (!widget.locked) _press.forward();
      },
      onPointerUp: (_) => _press.reverse(),
      onPointerCancel: (_) => _press.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([widget.pulse, _press]),
        builder: (_, __) {
          final p = widget.pulse.value;
          final scale = 1 - (_press.value * 0.018);

          return IgnorePointer(
            ignoring: widget.locked,
            child: Transform.scale(
              scale: scale,
              child: GestureDetector(
                onTap: widget.onTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(
                              widget.locked ? 0.045 : 0.075,
                            ),
                            _HomeFreeScreenState.violet.withOpacity(
                              widget.locked ? 0.025 : 0.08,
                            ),
                            Colors.black.withOpacity(0.18),
                          ],
                        ),
                        border: Border.all(
                          color: widget.locked
                              ? Colors.white.withOpacity(0.075)
                              : _HomeFreeScreenState.violet2
                                  .withOpacity(0.32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _HomeFreeScreenState.violet.withOpacity(
                              widget.locked ? 0.07 : 0.18 + p * 0.08,
                            ),
                            blurRadius: widget.locked ? 24 : 48,
                            spreadRadius: widget.locked ? 0 : 1,
                            offset: const Offset(0, 18),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.38),
                            blurRadius: 26,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Opacity(
                        opacity: widget.locked ? 0.60 : 1,
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _HomeFreeScreenState.violet3,
                                    _HomeFreeScreenState.violet2,
                                  ],
                                ),
                              ),
                              child: Icon(
                                widget.locked
                                    ? Icons.lock_rounded
                                    : Icons.arrow_outward_rounded,
                                color: Colors.black,
                                size: 25,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.locked ? "Scan locked" : "Scan photo",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _HomeFreeScreenState.ink,
                                      fontSize: 19.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.35,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.locked
                                        ? "Free result saved"
                                        : "PSL • percentile • tier",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _HomeFreeScreenState.muted
                                          .withOpacity(0.9),
                                      fontSize: 12.8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: Colors.black.withOpacity(0.22),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                              child: Text(
                                widget.locked
                                    ? "${widget.used}/${widget.limit}"
                                    : "0/${widget.limit}",
                                style: const TextStyle(
                                  color: _HomeFreeScreenState.violet3,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CooldownStrip extends StatelessWidget {
  final double progress;
  final String timeText;
  final Animation<double> pulse;

  const _CooldownStrip({
    required this.progress,
    required this.timeText,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        final p = pulse.value;

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white.withOpacity(0.045),
                border: Border.all(
                  color: Colors.white.withOpacity(0.07),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _HomeFreeScreenState.violet.withOpacity(
                      0.08 + p * 0.04,
                    ),
                    blurRadius: 28,
                  ),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4.2,
                      backgroundColor: Colors.white.withOpacity(0.07),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        _HomeFreeScreenState.violet2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Next scan",
                          style: TextStyle(
                            color: _HomeFreeScreenState.ink,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "Unlock timer active",
                          style: TextStyle(
                            color: _HomeFreeScreenState.muted.withOpacity(0.85),
                            fontSize: 12.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    timeText,
                    style: const TextStyle(
                      color: _HomeFreeScreenState.violet3,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
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
}

class _BackgroundPainter extends CustomPainter {
  final double t;

  _BackgroundPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _HomeFreeScreenState.bg,
            _HomeFreeScreenState.bg2,
            _HomeFreeScreenState.bg,
          ],
        ).createShader(rect),
    );

    final dx = math.sin(t * math.pi * 2) * 28;
    final dy = math.cos(t * math.pi * 2) * 18;

    final c1 = Offset(size.width * 0.74 + dx, size.height * 0.14 + dy);
    final c2 = Offset(size.width * 0.20 - dx * 0.35, size.height * 0.82);

    canvas.drawCircle(
      c1,
      size.width * 0.72,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _HomeFreeScreenState.violet.withOpacity(0.18),
            _HomeFreeScreenState.violet.withOpacity(0.048),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: c1, radius: size.width * 0.72)),
    );

    canvas.drawCircle(
      c2,
      size.width * 0.58,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _HomeFreeScreenState.gold.withOpacity(0.070),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: c2, radius: size.width * 0.58)),
    );
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}

class _OrbitPainter extends CustomPainter {
  final Color color;
  final Color bright;

  const _OrbitPainter({
    required this.color,
    required this.bright,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final soft = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round;

    final strong = Paint()
      ..color = bright
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect.deflate(8), -math.pi / 2.3, math.pi * 0.30, false, strong);
    canvas.drawArc(rect.deflate(16), math.pi * 0.18, math.pi * 0.23, false, soft);
    canvas.drawArc(rect.deflate(18), math.pi * 1.08, math.pi * 0.28, false, soft);
    canvas.drawArc(rect.deflate(28), math.pi * 0.72, math.pi * 0.16, false, strong);
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.bright != bright;
  }
}

class _InnerOrbitPainter extends CustomPainter {
  final Color color;

  const _InnerOrbitPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect.deflate(10), math.pi * 0.10, math.pi * 0.18, false, p);
    canvas.drawArc(rect.deflate(18), math.pi * 0.92, math.pi * 0.16, false, p);
  }

  @override
  bool shouldRepaint(covariant _InnerOrbitPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _ChamberGridPainter extends CustomPainter {
  final Color color;
  final Color accent;

  const _ChamberGridPainter({
    required this.color,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final thin = Paint()
      ..color = color
      ..strokeWidth = 0.75;

    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), thin);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), thin);

    final thirds = Paint()
      ..color = color.withOpacity(0.55)
      ..strokeWidth = 0.55;

    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), thirds);
    canvas.drawLine(Offset((size.width / 3) * 2, 0), Offset((size.width / 3) * 2, size.height), thirds);

    final corner = Paint()
      ..color = accent
      ..strokeWidth = 1.05
      ..strokeCap = StrokeCap.round;

    const l = 18.0;

    canvas.drawLine(Offset(0, 0), const Offset(l, 0), corner);
    canvas.drawLine(Offset(0, 0), const Offset(0, l), corner);

    canvas.drawLine(Offset(size.width, 0), Offset(size.width - l, 0), corner);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, l), corner);

    canvas.drawLine(Offset(0, size.height), Offset(l, size.height), corner);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - l), corner);

    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - l, size.height),
      corner,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - l),
      corner,
    );
  }

  @override
  bool shouldRepaint(covariant _ChamberGridPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.accent != accent;
  }
}