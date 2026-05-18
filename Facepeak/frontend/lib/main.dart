import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:frontend/features/social_free/social_features/push_token_api.dart';

import 'package:frontend/features/analysis/screens/app_entry.dart';
import 'package:frontend/features/analysis/screens/startup_splash_overlay.dart';

import 'package:frontend/core/network/connectivity_service.dart';
import 'package:frontend/core/network/global_connection_overlay.dart';

import 'package:frontend/services/ads_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp();

  debugPrint("🔥 BACKGROUND PUSH = ${message.data}");
  debugPrint("🔥 BACKGROUND TITLE = ${message.notification?.title}");
  debugPrint("🔥 BACKGROUND BODY = ${message.notification?.body}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("❌ FIREBASE INIT ERROR = $e");
  }

  await ConnectivityService.instance.initialize(
    onRestored: () async {
      debugPrint("🔄 INTERNET BACK — REFRESH APP STATE");

      AdsService.instance.updateConnectivity(
        isOnline: true,
      );

      // TODO:
      // refresh user profile
      // refresh latest score
      // refresh matches
      // refresh messages
      // reconnect sockets
      // retry failed uploads
    },
    onLost: () async {
      debugPrint("📴 OFFLINE MODE ACTIVE");

      AdsService.instance.updateConnectivity(
        isOnline: false,
      );
    },
  );

  await AdsService.initialize(
    adsEnabled: true,
    isOnline: ConnectivityService.instance.isOnline,
  );

  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  _setupFirebaseMessagingHandlers();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const FacePeakApp());

  _registerPushTokenSafe();
}

void _setupFirebaseMessagingHandlers() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint("🔥 FOREGROUND PUSH = ${message.data}");
    debugPrint("🔥 FOREGROUND TITLE = ${message.notification?.title}");
    debugPrint("🔥 FOREGROUND BODY = ${message.notification?.body}");
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint("🔥 PUSH OPENED APP = ${message.data}");
  });

  FirebaseMessaging.instance.getInitialMessage().then((
    RemoteMessage? message,
  ) {
    if (message == null) return;

    debugPrint("🔥 PUSH OPENED FROM TERMINATED = ${message.data}");
  });

  FirebaseMessaging.instance.onTokenRefresh.listen((
    String newToken,
  ) async {
    try {
      debugPrint("🔥 FCM TOKEN REFRESH = $newToken");

      await PushTokenApi.sendToken(
        fcmToken: newToken,
      );
    } catch (e) {
      debugPrint("❌ TOKEN REFRESH ERROR = $e");
    }
  });
}

Future<void> _registerPushTokenSafe() async {
  try {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint(
      "🔥 PUSH PERMISSION STATUS = ${settings.authorizationStatus}",
    );

    final fcmToken = await FirebaseMessaging.instance.getToken();

    debugPrint("🔥 FCM TOKEN = $fcmToken");

    if (fcmToken == null || fcmToken.isEmpty) {
      debugPrint("❌ FCM TOKEN EMPTY");
      return;
    }

    await PushTokenApi.sendToken(
      fcmToken: fcmToken,
    );
  } catch (e) {
    debugPrint("❌ PUSH REGISTER ERROR = $e");
  }
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
      home: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    return const GlobalConnectionOverlay(
      child: Stack(
        children: [
          AppEntry(),
          StartupSplashOverlay(),
        ],
      ),
    );
  }
}