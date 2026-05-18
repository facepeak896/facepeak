import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

// 🔥 PSL LOADING
import 'psl_loading.dart';

class AnalysisCaptureSimple extends StatefulWidget {
  final Map<String, dynamic> user;

  const AnalysisCaptureSimple({
    super.key,
    required this.user,
  });

  @override
  State<AnalysisCaptureSimple> createState() => _AnalysisCaptureSimpleState();
}

class _AnalysisCaptureSimpleState extends State<AnalysisCaptureSimple> {
  final ImagePicker _cameraPicker = ImagePicker();

  bool _cameraBusy = false;
  bool _navigating = false;
  bool _disposed = false;
  bool _cameraOpenedOnce = false;

  Future<void>? _activeFlow;

  static const bg = Color(0xFF0B0E14);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureCameraFlow();
    });
  }

  Future<void> _finishWithMessage(String message) async {
    if (_disposed || !mounted) return;

    Navigator.of(context).pop(message);
  }

  Future<void> _safePop() async {
    if (_disposed || !mounted) return;

    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    }
  }

  Future<void> _ensureCameraFlow() async {
    if (_disposed) return;
    if (_activeFlow != null) return;

    _activeFlow = _openCameraFlow();

    try {
      await _activeFlow;
    } finally {
      _activeFlow = null;
    }
  }

  Future<void> _openCameraFlow() async {
  if (_disposed || !mounted) return;
  if (_cameraBusy || _navigating || _cameraOpenedOnce) return;

  _cameraBusy = true;
  _cameraOpenedOnce = true;

  try {
    await HapticFeedback.mediumImpact();

    final XFile? file = await _cameraPicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
      maxWidth: 2000,
      preferredCameraDevice: CameraDevice.front,
    );

    if (_disposed || !mounted) return;

    // User cancelled camera
    if (file == null) {
      _cameraBusy = false;
      await _safePop();
      return;
    }

    final imageFile = File(file.path);

    final exists = await imageFile.exists();

    if (!exists) {
      _cameraBusy = false;
      _cameraOpenedOnce = false;

      await _finishWithMessage(
        "Photo could not be loaded. Please try again.",
      );
      return;
    }

    if (_disposed || !mounted || _navigating) return;

    _navigating = true;

    final message = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (_) => AnalyzePslLoadingScreen(
          imageFile: imageFile,
          guestToken: "guest",
          userSnapshot: widget.user,

          onFinished: (_) {},

          onError: (message) {
            if (!mounted) return;
            Navigator.of(context).pop(message);
          },
        ),
      ),
    );

    if (!mounted) return;

    // 🔥 Forward loading error back to CreatePostScreen
    if (message != null && message.trim().isNotEmpty) {
      Navigator.of(context).pop(message);
      return;
    }
  } on PlatformException catch (e) {
    debugPrint("Camera platform error: ${e.code} ${e.message}");

    _cameraOpenedOnce = false;
    _cameraBusy = false;
    _navigating = false;

    await _finishWithMessage(
      "Camera unavailable. Please allow camera access and try again.",
    );
  } catch (e) {
    debugPrint("Camera error: $e");

    _cameraOpenedOnce = false;
    _cameraBusy = false;
    _navigating = false;

    await _finishWithMessage(
      "Something went wrong while opening the camera.",
    );
  }
}

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: bg,
      body: Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
    );
  }
}