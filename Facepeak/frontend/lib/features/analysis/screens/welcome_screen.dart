import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ SVI SU U ISTOM FOLDERU
import 'landing_screen.dart';
import 'add_photo_screen.dart';
import 'analyze_loading_screen.dart';
import 'psl_result_screen.dart';
import 'psl_explanation_screen.dart';
import 'access_choice_screen.dart';

class WelcomeFlow extends StatefulWidget {
  const WelcomeFlow({super.key});

  @override
  State<WelcomeFlow> createState() => _WelcomeFlowState();
}

class _WelcomeFlowState extends State<WelcomeFlow> {
  int _step = 0;
  File? _image;
  Map<String, dynamic>? _psl;

  Future<void> _finishWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_done', true);
  }

  void _next() => setState(() => _step++);
  void _setImage(File img) {
    _image = img;
    _next();
  }

  void _setPsl(Map<String, dynamic> psl) {
    _psl = psl;
    _next();
  }

  @override
Widget build(BuildContext context) {
  switch (_step) {
    case 0:
      return LandingScreen(
        onContinue: _next,
      );

    case 1:
      return AddPhotoScreen(
        onImageSelected: _setImage,
      );

    case 2:
      return AnalyzeLoadingScreen(
        imageFile: _image!,
        onFinished: _setPsl,

        // 🔥 KLJUČNO — DODANO
        onError: (err) {
          // možeš kasnije fancy handling
          // za sad fallback nazad na upload
          setState(() {
            _step = 1;
          });
        },
      );

    case 3:
      return PSLResultScreen(
        psl: _psl!,
        imageFile: _image!,
        onContinue: _next,
      );

    case 4:
      return PslExplanationScreen(
        onContinue: _next,
      );

    case 5:
      return AccessChoiceScreen(
        onFinish: () async {
          await _finishWelcome();
          setState(() {});
        },
      );

    default:
      return const SizedBox.shrink();
  }
}}