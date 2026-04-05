import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

// ⬇️ IMPORT TVOG PRAVOG LOADINGA
import 'analyze_appeal_loading_screen.dart';

class AppealUploadScreen extends StatefulWidget {
  final String guestToken;

  const AppealUploadScreen({
    super.key,
    required this.guestToken,
  });

  @override
  State<AppealUploadScreen> createState() => _AppealUploadScreenState();
}
class _AppealUploadScreenState extends State<AppealUploadScreen> {
  final ImagePicker _cameraPicker = ImagePicker();

  // ===== THEME =====
  static const Color bgTop = Color(0xFF1A1A24);
  static const Color bgMid = Color(0xFF12121A);
  static const Color bgBottom = Color(0xFF0B0B0F);
  static const Color gold = Color(0xFFF5C518);

  // ------------------------------------------------------------
  // CAMERA
  // ------------------------------------------------------------
  Future<void> _pickFromCamera() async {
    HapticFeedback.lightImpact();

    final XFile? file = await _cameraPicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
      maxWidth: 2000,
    );

    if (file == null) return;

    _goNext(File(file.path));
  }

  // ------------------------------------------------------------
  // GALLERY
  // ------------------------------------------------------------
  Future<void> _pickFromGallery() async {
    HapticFeedback.lightImpact();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) return;

    _goNext(File(result.files.single.path!));
  }

  // ------------------------------------------------------------
  // NAVIGATION → REAL LOADING
  // ------------------------------------------------------------
  void _goNext(File image) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalyzeAppealLoadingScreen(
          imageFile: image,
          onFinished: (appeal) {
            // ovdje ćeš kasnije pushat AppealResultScreen
          },
          onError: (err) {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // UI (NE DIRATI)
  // ------------------------------------------------------------
  @override
Widget build(BuildContext context) {
  final media = MediaQuery.of(context);

  return WillPopScope(
    onWillPop: () async => false, // ⛔ DISABLE BACK
    child: Scaffold(
      backgroundColor: Colors.transparent,
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
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.025,
                  child: ImageFiltered(
                    imageFilter:
                        ImageFilter.blur(sigmaX: 0.6, sigmaY: 0.6),
                    child: Container(color: Colors.white),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                media.padding.top + 32,
                24,
                media.padding.bottom + 32,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'Add a photo',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Take a photo or choose one from your gallery',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xCCFFFFFF),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Use a clear, front-facing photo for best results',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0x99FFFFFF),
                    ),
                  ),
                  const SizedBox(height: 36),

                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                      ),
                      color: Colors.black.withOpacity(0.25),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.face_rounded,
                          size: 72,
                          color: Color(0x55FFFFFF),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'One face • Good lighting • No filters',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0x99FFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  GestureDetector(
                    onTap: _pickFromCamera,
                    child: Container(
                      height: 56,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFF5C518),
                            Color(0xFFE6B800),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '📸 Take photo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0B0B0F),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  GestureDetector(
                    onTap: _pickFromGallery,
                    child: Container(
                      height: 52,
                      width: media.size.width * 0.8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '🖼️ Choose from gallery',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    '🔒 Photos are processed securely and deleted after analysis',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0x99FFFFFF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}}