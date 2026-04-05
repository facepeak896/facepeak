import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:frontend/features/analysis/screens/app_entry.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔒 LOCK ORIENTATION (portrait only)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 🧼 SYSTEM UI (edge-to-edge, dark)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const FacePeakApp());
}

class FacePeakApp extends StatelessWidget {
  const FacePeakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),

      // ✅ JEDINI ROOT CIJELE APLIKACIJE
      home: AppEntry(),
    );
  }
}