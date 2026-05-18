import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class AddPhotoScreen extends StatefulWidget {
  final void Function(File image) onImageSelected;

  // ⬇️ OVDJE
  final String? errorMessage;

  const AddPhotoScreen({
    super.key,
    required this.onImageSelected,

    // ⬇️ I OVDJE
    this.errorMessage,
  });

  @override
  State<AddPhotoScreen> createState() => _AddPhotoScreenState();
}

class _AddPhotoScreenState extends State<AddPhotoScreen>
    with TickerProviderStateMixin {
  final ImagePicker _cameraPicker = ImagePicker();

  bool _picking = false;

  late final AnimationController _pulse;
  late final AnimationController _float;
  late final AnimationController _scan;

  static const Color bgTop = Color(0xFF05040D);
  static const Color bgMid = Color(0xFF0B0718);
  static const Color bgBottom = Color(0xFF04040A);

  static const Color purple = Color(0xFF8B5CFF);
  static const Color purple2 = Color(0xFFC084FC);
  static const Color purple3 = Color(0xFFE9D5FF);
  static const Color gold = Color(0xFFFFD978);

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);

    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);

    _scan = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }
  @override
void didUpdateWidget(covariant AddPhotoScreen oldWidget) {
  super.didUpdateWidget(oldWidget);

  final msg = widget.errorMessage;

  if (msg == null ||
      msg.isEmpty ||
      msg == oldWidget.errorMessage) {
    return;
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  });
}

  @override
  void dispose() {
    _pulse.dispose();
    _float.dispose();
    _scan.dispose();
    super.dispose();
  }

  Future<void> _pickFromCamera() async {
    if (_picking) return;

    setState(() => _picking = true);
    HapticFeedback.lightImpact();

    try {
      final XFile? file = await _cameraPicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 92,
        maxWidth: 2000,
      );

      if (file == null) return;

      widget.onImageSelected(File(file.path));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_picking) return;

    setState(() => _picking = true);
    HapticFeedback.lightImpact();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: false,
      );

      if (result == null || result.files.single.path == null) return;

      widget.onImageSelected(File(result.files.single.path!));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawMedia = MediaQuery.of(context);
    final media = rawMedia.copyWith(
      textScaler: const TextScaler.linear(1.0),
    );

    return MediaQuery(
      data: media,
      child: Scaffold(
        backgroundColor: bgBottom,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [bgTop, bgMid, bgBottom],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: _backgroundFx()),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final h = constraints.maxHeight;
                    final compact = h < 760;
                    final veryCompact = h < 690;

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        24,
                        veryCompact ? 20 : 34,
                        24,
                        24 + rawMedia.padding.bottom,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight -
                              rawMedia.padding.top -
                              rawMedia.padding.bottom -
                              44,
                        ),
                        child: Column(
                          children: [
                            _titleBlock(compact: compact),
                            SizedBox(height: veryCompact ? 24 : 36),
                            _photoChamber(compact: compact),
                            SizedBox(height: veryCompact ? 60 : 120),
                            _primaryButton(),
                            const SizedBox(height: 14),
                            _galleryButton(rawMedia.size.width),
                            const SizedBox(height: 18),
                            _privacyText(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backgroundFx() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _float]),
      builder: (context, _) {
        final p = _pulse.value;
        final f = _float.value;

        return Stack(
          children: [
            Positioned(
              top: -140,
              left: -120,
              right: -120,
              child: Container(
                height: 360,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      purple2.withOpacity(0.16 + p * 0.06),
                      purple.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 230 + (f - 0.5) * 28,
              left: -150,
              right: -150,
              child: Container(
                height: 430,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      purple.withOpacity(0.14 + p * 0.04),
                      gold.withOpacity(0.035),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -130,
              right: -130,
              child: Container(
                height: 360,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      purple2.withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _titleBlock({required bool compact}) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (rect) {
            return const LinearGradient(
              colors: [Colors.white, purple3],
            ).createShader(rect);
          },
          child: Text(
            'Add your photo',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 33 : 38,
              fontWeight: FontWeight.w900,
              height: 1.0,
              letterSpacing: -0.8,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: purple.withOpacity(0.25),
                  blurRadius: 24,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Use a clear front-facing photo for the most accurate result.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact ? 14.5 : 15.5,
            height: 1.35,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.66),
          ),
        ),
      ],
    );
  }

  Widget _photoChamber({required bool compact}) {
    final height = compact ? 210.0 : 238.0;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _float, _scan]),
      builder: (context, _) {
        final p = _pulse.value;
        final f = (_float.value - 0.5) * 5;
        final scanY = 34 + (_scan.value * (height - 68));

        return Transform.translate(
          offset: Offset(0, f),
          child: Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: purple.withOpacity(0.22 + p * 0.16),
                  blurRadius: 42,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.50),
                  blurRadius: 36,
                  offset: const Offset(0, 22),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.055),
                            purple.withOpacity(0.070),
                            Colors.black.withOpacity(0.28),
                          ],
                        ),
                        border: Border.all(
                          color: purple2.withOpacity(0.24),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ScanGridPainter(
                        color: Colors.white.withOpacity(0.035),
                        accent: purple2.withOpacity(0.12),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: scanY - 42,
                    child: Container(
                      height: 84,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            purple.withOpacity(0.05),
                            purple2.withOpacity(0.12),
                            gold.withOpacity(0.06),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 28,
                    right: 28,
                    top: scanY,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.transparent,
                            purple2,
                            purple3,
                            gold,
                            purple3,
                            purple2,
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: purple2.withOpacity(0.58),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.045),
                              border: Border.all(
                                color: purple2.withOpacity(0.22),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: purple.withOpacity(0.25 + p * 0.16),
                                  blurRadius: 28,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.face_retouching_natural_rounded,
                              size: 38,
                              color: purple3,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'One face only',
                            style: TextStyle(
                              fontSize: compact ? 17 : 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white.withOpacity(0.92),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Good lighting • No filters • Neutral angle',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: compact ? 12.5 : 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withOpacity(0.54),
                            ),
                          ),
                        ],
                      ),
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

  Widget _primaryButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _picking ? null : _pickFromCamera,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final p = _pulse.value;

          return Opacity(
            opacity: _picking ? 0.82 : 1,
            child: Container(
              height: 58,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(19),
                gradient: const LinearGradient(
                  colors: [purple3, purple2, purple],
                ),
                boxShadow: [
                  BoxShadow(
                    color: purple2.withOpacity(0.25 + p * 0.20),
                    blurRadius: 34,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: _picking
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.black,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.photo_camera_rounded,
                            color: Colors.black,
                            size: 21,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Take photo',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _galleryButton(double screenWidth) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _picking ? null : _pickFromGallery,
      child: Container(
        height: 54,
        width: math.min(screenWidth * 0.84, 420),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          color: Colors.white.withOpacity(0.035),
          border: Border.all(
            color: purple2.withOpacity(0.22),
          ),
          boxShadow: [
            BoxShadow(
              color: purple.withOpacity(0.08),
              blurRadius: 18,
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Choose from gallery',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: Colors.white.withOpacity(0.88),
            ),
          ),
        ),
      ),
    );
  }

  Widget _privacyText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_rounded,
          size: 15,
          color: gold.withOpacity(0.80),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            'Photos are processed securely and deleted after analysis.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.48),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanGridPainter extends CustomPainter {
  final Color color;
  final Color accent;

  const _ScanGridPainter({
    required this.color,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 0.7;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      p,
    );

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      p,
    );

    final edge = Paint()
      ..color = accent
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(30),
    );

    canvas.drawRRect(r.deflate(0.5), edge);
  }

  @override
  bool shouldRepaint(covariant _ScanGridPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.accent != accent;
  }
}