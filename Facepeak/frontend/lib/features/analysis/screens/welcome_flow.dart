import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'landing_screen.dart';
import 'add_photo_screen.dart';
import 'analyze_loading_screen.dart';
import 'psl_result_screen.dart';
import 'app_entry.dart';
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

  void _next() {
    setState(() => _step++);
  }

  void _setImage(File img) {
    _image = img;
    _next();
  }

  void _setPsl(Map<String, dynamic> psl) {
    _psl = psl;
    _next();
  }

  Future<void> _finishWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_done', true);
  }

  @override
  Widget build(BuildContext context) {
    return _FlowScaffold(
      child: _buildStep(),
    );
  }

  Widget _buildStep() {
  switch (_step) {
    case 0:
      return LandingScreen(onContinue: _next);

    case 1:
      return AddPhotoScreen(onImageSelected: _setImage);

    case 2:
      return AnalyzeLoadingScreen(
        imageFile: _image!,
        onFinished: _setPsl,
        onError: (type) {
          if (!mounted) return;

          // ❌ Face not detected → nazad na upload
          if (type == "face" || type == "generic") {
            setState(() {
              _step = 1;
              _image = null;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Face could not be detected. Please try again.",
                ),
                backgroundColor: Colors.redAccent,
              ),
            );
          }

          // 🚫 Forbidden → nazad na PSL Result (cached)
          else if (type == "forbidden") {
            setState(() {
              _step = 3;
            });
          }
        },
      );

    case 3:
      return PSLResultScreen(
        psl: _psl!,
        imageFile: _image!,
        onContinue: _next,
      );

    case 4:
      return PslExplanationScreen(onContinue: _next);

    case 5:
      return AccessChoiceScreen(
        onFinish: () async {
          await _finishWelcome();
          if (!mounted) return;

          // ⬇️ KLJUČNA STVAR: izlaz iz WelcomeFlowa
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => AppEntry()),
            (_) => false,
          );
        },
      );

    default:
      return const SizedBox.shrink();
  }
}}
///
/// 🔒 FLOW SCAFFOLD
/// - gasi BACK
/// - nema strelice
/// - nema crasha
///
class _FlowScaffold extends StatelessWidget {
  final Widget child;

  const _FlowScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: null, // ⬅️ OVO uklanja gornji prazan prostor
        body: SafeArea(
          top: false, // ⬅️ sprječava Android ghost padding
          child: child,
        ),
      ),
    );
  }
}