import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 🔥 IMAGE FLIP
import 'package:image/image.dart' as img;

// 🔥 PSL LOADING
import 'psl_loading.dart';

class AnalysisCaptureSimple extends StatefulWidget {
  const AnalysisCaptureSimple({super.key});

  @override
  State<AnalysisCaptureSimple> createState() =>
      _AnalysisCaptureSimpleState();
}

class _AnalysisCaptureSimpleState extends State<AnalysisCaptureSimple> {

  CameraController? _controller;
  bool _loading = true;
  bool _capturing = false;

  static const bg = Color(0xFF0B0E14);

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();

      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        front,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      _controller = controller;

      if (!mounted) return;

      setState(() => _loading = false);

    } catch (e) {
      print("Camera error: $e");
    }
  }

  // 🔥 FLIP IMAGE (KEY FIX)
  Future<File> _flipImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return file;

      final flipped = img.flipHorizontal(image);

      final newFile = File(file.path);
      await newFile.writeAsBytes(img.encodeJpg(flipped));

      return newFile;
    } catch (e) {
      print("Flip error: $e");
      return file;
    }
  }

  Future<void> _capture() async {
    if (_controller == null || _capturing) return;

    HapticFeedback.mediumImpact();

    setState(() => _capturing = true);

    try {
      final file = await _controller!.takePicture();

      // 🔥 FIX: FLIP BEFORE SENDING
      final fixedFile = await _flipImage(File(file.path));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AnalyzePslLoadingScreen(
            imageFile: fixedFile,
            guestToken: "guest",
            onFinished: (_) {},
            onError: (_) {},
          ),
        ),
      );

    } catch (e) {
      print("Capture error: $e");
      setState(() => _capturing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [

          // 🔥 CAMERA
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          // 🔥 TOP TEXT
          Positioned(
            top: 80,
            left: 20,
            right: 20,
            child: Column(
              children: const [
                Text(
                  "Take a clear photo",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Face forward • Good lighting",
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // 🔥 CAPTURE BUTTON
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _capture,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                  ),
                  child: Center(
                    child: _capturing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
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