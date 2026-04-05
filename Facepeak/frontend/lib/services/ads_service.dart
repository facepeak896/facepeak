import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  AdsService._internal();
  static final AdsService instance = AdsService._internal();

  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  bool _isShowing = false;
  static int _failCount = 0;

  static const int _maxFails = 3;
  static const Duration _rewardTimeout = Duration(seconds: 15);

  // ✅ OFFICIAL GOOGLE TEST ID (ANDROID)
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // ===============================
  // 🔑 INIT (CALL ON APP START)
  // ===============================
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await MobileAds.instance.initialize();
    AdsService.instance._loadRewardedAd();
  }

  // ===============================
  // ▶️ LOAD REWARDED AD
  // ===============================
  void _loadRewardedAd() {
    if (_isLoading || _rewardedAd != null) return;
    if (_failCount >= _maxFails) return;

    _isLoading = true;

    RewardedAd.load(
      adUnitId: _testRewardedAdUnitId, // ✅ FIXED
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('[ADS] Rewarded loaded');
          _rewardedAd = ad;
          _isLoading = false;
          _failCount = 0;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('[ADS] Dismissed');
              ad.dispose();
              _rewardedAd = null;
              _isShowing = false;
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('[ADS] Failed to show: $error');
              ad.dispose();
              _rewardedAd = null;
              _isShowing = false;
              _loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('[ADS] Failed to load: $error');
          _rewardedAd = null;
          _isLoading = false;
          _failCount++;
        },
      ),
    );
  }

  // ===============================
  // 🎁 SHOW REWARDED AD
  // ===============================
  Future<bool> showRewardedAd() async {
    if (_rewardedAd == null || _isShowing) {
      debugPrint('[ADS] No ad ready');
      _loadRewardedAd();
      return false;
    }

    _isShowing = true;
    final completer = Completer<bool>();

    try {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint('[ADS] Reward earned');
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
      );
    } catch (e) {
      debugPrint('[ADS] Show exception: $e');
      _isShowing = false;
      if (!completer.isCompleted) completer.complete(false);
    }

    return completer.future.timeout(
      _rewardTimeout,
      onTimeout: () {
        debugPrint('[ADS] Reward timeout');
        _isShowing = false;
        return false;
      },
    );
  }
}