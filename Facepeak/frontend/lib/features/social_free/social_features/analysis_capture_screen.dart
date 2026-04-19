import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

// 🔥 PSL LOADING
import 'psl_loading.dart';

class AnalysisCaptureSimple extends StatefulWidget {
  final Map<String, dynamic> user; // 🔥 DODAJ

  const AnalysisCaptureSimple({
    super.key,
    required this.user, // 🔥 DODAJ
  });

  @override
  State<AnalysisCaptureSimple> createState() =>
      _AnalysisCaptureSimpleState();
}

class _AnalysisCaptureSimpleState extends State<AnalysisCaptureSimple> {
  final ImagePicker _cameraPicker = ImagePicker();

  bool _loading = true;
  bool _capturing = false;
  bool _navigating = false;
  bool _disposed = false;
  bool _openedCamera = false;

  static const bg = Color(0xFF0B0E14);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openCamera();
    });
  }

  Future<void> _openCamera() async {
  if (_disposed || !mounted) return;
  if (_openedCamera || _capturing || _navigating) return;

  _openedCamera = true;
  _capturing = true;

  if (mounted) {
    setState(() {
      _loading = true;
    });
  }

  try {
    HapticFeedback.mediumImpact();

    final XFile? file = await _cameraPicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
      maxWidth: 2000,
    );

    if (_disposed || !mounted) return;

    if (file == null) {
      _capturing = false;
      _loading = false;
      _openedCamera = false;

      if (mounted) {
        setState(() {});
      }

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    final imageFile = File(file.path);

    if (!imageFile.existsSync()) {
      _capturing = false;
      _loading = false;
      _openedCamera = false;

      if (mounted) {
        setState(() {});
      }
      return;
    }

    if (_disposed || !mounted) return;
    if (_navigating) return;

    _navigating = true;

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AnalyzePslLoadingScreen(
          imageFile: imageFile,
          guestToken: "guest",
          userSnapshot: widget.user, // 🔥 NOVO
          onFinished: (_) {},
          onError: (_) {},
        ),
      ),
    );
  } catch (e) {
    debugPrint("Camera error: $e");

    if (_disposed || !mounted) return;

    setState(() {
      _loading = false;
      _capturing = false;
      _openedCamera = false;
      _navigating = false;
    });
  }
}

  Future<void> _retryOpenCamera() async {
    if (_disposed || _capturing || _navigating) return;

    _openedCamera = false;
    await _openCamera();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Widget _buildLoading() {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildError() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Camera unavailable",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Please allow camera access and try again.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _retryOpenCamera,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    "Retry",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildLoading();
    }

    return _buildError();
  }
}