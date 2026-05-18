import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:frontend/features/analysis/screens/home_free_screen.dart';

import 'free_result_card.dart';
import 'premium_preview_card.dart';

class PSLResultScreen extends StatefulWidget {
  final Map<String, dynamic> psl;
  final File imageFile;

  const PSLResultScreen({
    super.key,
    required this.psl,
    required this.imageFile,
  });

  @override
  State<PSLResultScreen> createState() => _PSLResultScreenState();
}

class _PSLResultScreenState extends State<PSLResultScreen> {
  static const Color bg = Color(0xFF05070D);

  final PageController _pageController = PageController(viewportFraction: 0.92);
  final GlobalKey _freeCardKey = GlobalKey();

  int _page = 0;

  void _goHome() {
    HapticFeedback.selectionClick();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const HomeFreeScreen(),
      ),
      (route) => false,
    );
  }

  double _readDouble(dynamic v, double fallback) {
    if (v is num) return v.toDouble();

    if (v is String) {
      final cleaned = v
          .toLowerCase()
          .replaceAll('%', '')
          .replaceAll('top', '')
          .replaceAll('bottom', '')
          .replaceAll(',', '.')
          .trim();

      return double.tryParse(cleaned) ?? fallback;
    }

    return fallback;
  }

  double _cardHeight(double screenHeight) {
    if (screenHeight < 640) return 500;
    if (screenHeight < 700) return 520;
    if (screenHeight < 760) return 540;
    return 555;
  }

  ViralResultUiData _buildUiData() {
    final double score = _readDouble(
      widget.psl['psl_score'] ?? widget.psl['display_score'],
      4,
    );

    final double confidence = _readDouble(
      widget.psl['confidence'],
      0.82,
    ).clamp(0.0, 1.0).toDouble();

    final String tier = _tierFromBackend(widget.psl['tier']);
    final int tierNumber = _tierNumberFromLabel(tier);

    final double graphPercentile = _graphPercentileFromBackend(
      tierNumber: tierNumber,
      confidence: confidence,
    );

    return ViralResultUiData(
      imageFile: widget.imageFile,
      score: score,
      tierLabel: tier,
      populationLabel: _populationLabelFromTier(tierNumber),
      confidenceLabel: _confidenceLabel(confidence),
      percentile: graphPercentile,
      confidence: confidence,
    );
  }

  String _tierFromBackend(dynamic raw) {
    if (raw is int) return _tierFromBackendTier(raw);
    if (raw is num) return _tierFromBackendTier(raw.toInt());

    final s = raw.toString().toLowerCase().trim();

    if (s.contains('elite')) return 'ELITE';

    if (s.contains('chadlite') ||
        s.contains('chad lite') ||
        s.contains('chad-lite')) {
      return 'CHADLITE';
    }

    if (s == 'chad' || s.startsWith('chad') || s.contains(' chad')) {
      return 'CHAD';
    }

    if (s.contains('high tier') ||
        s.contains('high-tier') ||
        s == 'high' ||
        s == 'htn') {
      return 'HTN';
    }

    if (s.contains('above average') ||
        s.contains('above-average') ||
        s.contains('mid tier') ||
        s.contains('mid-tier') ||
        s == 'mtn') {
      return 'MTN';
    }

    if (s.contains('average') ||
        s.contains('lower tier') ||
        s.contains('lower-tier') ||
        s == 'ltn') {
      return 'LTN';
    }

    if (s.contains('sub-5') || s.contains('sub 5')) return 'SUB-5';

    if (s.contains('sub-3') || s.contains('sub 3') || s.contains('needs')) {
      return 'SUB-3';
    }

    return 'LTN';
  }

  String _tierFromBackendTier(int tier) {
    switch (tier.clamp(1, 8)) {
      case 1:
        return 'SUB-3';
      case 2:
        return 'SUB-5';
      case 3:
        return 'LTN';
      case 4:
        return 'MTN';
      case 5:
        return 'HTN';
      case 6:
        return 'CHADLITE';
      case 7:
        return 'CHAD';
      case 8:
        return 'ELITE';
      default:
        return 'LTN';
    }
  }

  int _tierNumberFromLabel(String tier) {
    switch (tier.toUpperCase()) {
      case 'SUB-3':
        return 1;
      case 'SUB-5':
        return 2;
      case 'LTN':
        return 3;
      case 'MTN':
        return 4;
      case 'HTN':
        return 5;
      case 'CHADLITE':
        return 6;
      case 'CHAD':
        return 7;
      case 'ELITE':
        return 8;
      default:
        return 3;
    }
  }

  double _rawScoreForTier(int tierNumber) {
    return _readDouble(
      widget.psl['raw_expected'] ??
          widget.psl['rawExpected'] ??
          widget.psl['stable_score_float'] ??
          widget.psl['stableScoreFloat'] ??
          widget.psl['score_float'] ??
          widget.psl['scoreFloat'] ??
          widget.psl['raw_score'] ??
          widget.psl['rawScore'] ??
          widget.psl['psl_score'] ??
          widget.psl['display_score'],
      tierNumber.toDouble(),
    );
  }

  double _graphPercentileFromBackend({
    required int tierNumber,
    required double confidence,
  }) {
    final double rawScore = _rawScoreForTier(tierNumber);

    final ranges = <int, List<double>>{
      1: [3.0, 7.5],
      2: [10.0, 17.5],
      3: [21.0, 36.0],
      4: [39.0, 52.0],
      5: [55.0, 67.0],
      6: [70.0, 79.0],
      7: [83.0, 91.0],
      8: [95.0, 98.5],
    };

    final range = ranges[tierNumber.clamp(1, 8)] ?? ranges[3]!;
    final start = range[0];
    final end = range[1];

    final double local = (rawScore - tierNumber).clamp(0.0, 0.999).toDouble();

    final double confidencePull =
        (1.0 - confidence.clamp(0.0, 1.0).toDouble()) * 0.14;

    final double adjustedLocal =
        (local * (1.0 - confidencePull)) + (0.5 * confidencePull);

    return (start + ((end - start) * adjustedLocal))
        .clamp(0.0, 100.0)
        .toDouble();
  }

  String _populationLabelFromTier(int tier) {
    switch (tier.clamp(1, 8)) {
      case 1:
        return 'bottom-end population range';
      case 2:
        return 'below most of the crowd';
      case 3:
        return 'average population range';
      case 4:
        return 'noticeable mid-range';
      case 5:
        return 'clearly above average';
      case 6:
        return 'ahead of most people';
      case 7:
        return 'rare standout range';
      case 8:
        return 'almost nobody lands here';
      default:
        return 'average population range';
    }
  }

  String _confidenceLabel(double c) {
    if (c >= 0.88) return 'Locked';
    if (c >= 0.76) return 'Strong';
    if (c >= 0.62) return 'Stable';
    return 'Soft';
  }

  Future<File?> _captureFreeCard() async {
    try {
      final boundary = _freeCardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 4);

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) return null;

      final dir = await getTemporaryDirectory();

      final file = File(
        '${dir.path}/facepeak_result_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      await file.writeAsBytes(
        byteData.buffer.asUint8List(),
      );

      return file;
    } catch (_) {
      return null;
    }
  }

  Future<void> _shareFreeCard() async {
    HapticFeedback.mediumImpact();

    if (_page != 0) return;

    final file = await _captureFreeCard();

    if (file == null) return;

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'My FacePeak result 🔥',
    );
  }

  Future<void> _saveFreeCard() async {
    HapticFeedback.mediumImpact();

    if (_page != 0) return;

    final file = await _captureFreeCard();

    if (file == null) return;

    await Gal.putImage(file.path);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Saved to gallery.'),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _buildUiData();
    final bool canExport = _page == 0;

    return WillPopScope(
      onWillPop: () async {
        _goHome();
        return false;
      },
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                        child: Row(
                          children: [
                            _CircleAction(
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap: _goHome,
                            ),
                            const Spacer(),
                            AnimatedOpacity(
                              opacity: canExport ? 1 : 0,
                              duration: const Duration(milliseconds: 180),
                              child: IgnorePointer(
                                ignoring: !canExport,
                                child: Row(
                                  children: [
                                    _CircleAction(
                                      icon: Icons.download_rounded,
                                      onTap: _saveFreeCard,
                                    ),
                                    const SizedBox(width: 10),
                                    _CircleAction(
                                      icon: Icons.ios_share_rounded,
                                      onTap: _shareFreeCard,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: _cardHeight(
                          MediaQuery.of(context).size.height,
                        ),
                        child: PageView(
                          controller: _pageController,
                          physics: const BouncingScrollPhysics(),
                          onPageChanged: (i) {
                            HapticFeedback.selectionClick();
                            setState(() => _page = i);
                          },
                          children: [
                            Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: RepaintBoundary(
                                  key: _freeCardKey,
                                  child: FreeResultCard(data: data),
                                ),
                              ),
                            ),
                            Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: PremiumPreviewCard(data: data),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _LuxuryPageDots(page: _page),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleAction({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.06),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 19,
        ),
      ),
    );
  }
}

class _LuxuryPageDots extends StatelessWidget {
  final int page;

  const _LuxuryPageDots({
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.035),
        border: Border.all(
          color: Colors.white.withOpacity(0.055),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MinimalDot(active: page == 0),
          const SizedBox(width: 8),
          _MinimalDot(active: page == 1),
        ],
      ),
    );
  }
}

class _MinimalDot extends StatelessWidget {
  final bool active;

  const _MinimalDot({
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? Colors.white.withOpacity(0.95)
            : Colors.white.withOpacity(0.22),
        boxShadow: active
            ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.40),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
    );
  }
}