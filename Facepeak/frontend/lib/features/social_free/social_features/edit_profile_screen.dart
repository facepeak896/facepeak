import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:image_picker/image_picker.dart'; // 🔥 kasnije uključi

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {

  late TextEditingController usernameController;
  late TextEditingController bioController;

  File? _image;

  late AnimationController _animController;
  late Animation<double> _fade;
  late Animation<double> _scale;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    usernameController =
        TextEditingController(text: widget.user["username"]);
    bioController =
        TextEditingController(text: widget.user["bio"]);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fade = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _scale = Tween(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    usernameController.dispose();
    bioController.dispose();
    _animController.dispose();
    super.dispose();
  }

  /// 🔥 IMAGE PICK (UI READY)
  Future<void> _pickImage() async {
    HapticFeedback.selectionClick();

    // final picker = ImagePicker();
    // final picked = await picker.pickImage(source: ImageSource.gallery);

    // if (picked != null) {
    //   setState(() {
    //     _image = File(picked.path);
    //   });
    // }

    /// TEMP DEMO
    setState(() {
      _image = File("fake");
    });
  }

  /// 🔥 SAVE
  Future<void> _save() async {
    HapticFeedback.mediumImpact();

    setState(() => _saving = true);

    await Future.delayed(const Duration(milliseconds: 900));

    // 🔥 TU IDE BACKEND KASNIJE

    if (!mounted) return;

    Navigator.pop(context, {
      "username": usernameController.text.trim(),
      "bio": bioController.text.trim(),
      "image": _image,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: SafeArea(
            child: Column(
              children: [

                /// ================= TOP BAR =================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [

                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),

                      const Spacer(),

                      const Text(
                        "Edit Profile",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const Spacer(),

                      GestureDetector(
                        onTap: _saving ? null : _save,
                        child: Text(
                          "Save",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _saving
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// ================= PROFILE IMAGE =================
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [

                      /// IMAGE
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.black,
                        backgroundImage:
                            _image != null ? null : null,
                        child: _image == null
                            ? const Icon(Icons.person, size: 40, color: Colors.white)
                            : null,
                      ),

                      /// BADGE (CAMERA)
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                /// ================= INPUTS =================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [

                      /// USERNAME
                      _input(
                        controller: usernameController,
                        label: "Username",
                      ),

                      const SizedBox(height: 16),

                      /// BIO
                      _input(
                        controller: bioController,
                        label: "Bio",
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// ================= INFO =================
                const Text(
                  "Your username must be unique",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                ),

                const Spacer(),

                /// ================= CTA =================
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: GestureDetector(
                    onTap: _saving ? null : _save,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 56,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      alignment: Alignment.center,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Save Changes",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ================= INPUT =================
  Widget _input({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
        ),
      ),
    );
  }
}