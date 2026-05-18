import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum RewardedAdStatus {
  idle,
  loading,
  ready,
  showing,
  failed,
  disabled,
}

class AdsService {
  AdsService._internal();

  static final AdsService instance = AdsService._internal();

  RewardedAd? _rewardedAd;

  bool _initialized = false;
  bool _isLoading = false;
  bool _isShowing = false;
  bool _adsEnabled = true;
  bool _isOnline = true;

  int _failCount = 0;
  int _loadAttempt = 0;

  Timer? _retryTimer;

  static const int _maxConsecutiveFails = 8;
  static const Duration _rewardTimeout = Duration(seconds: 20);
  static const Duration _minRetryDelay = Duration(seconds: 2);
  static const Duration _maxRetryDelay = Duration(minutes: 2);

  // ✅ TEST ID — zamijeni production ID-em kasnije
  static const String _rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  final StreamController<RewardedAdStatus> _statusController =
      StreamController<RewardedAdStatus>.broadcast();

  Stream<RewardedAdStatus> get statusStream => _statusController.stream;

  RewardedAdStatus _status = RewardedAdStatus.idle;

  RewardedAdStatus get status => _status;

  bool get isReady => _rewardedAd != null && !_isShowing;
  bool get isShowing => _isShowing;
  bool get adsEnabled => _adsEnabled;
  bool get isOnline => _isOnline;

  // ===============================
  // 🔑 INIT
  // ===============================

  static Future<void> initialize({
    bool adsEnabled = true,
    bool isOnline = true,
  }) async {
    await instance._initialize(
      adsEnabled: adsEnabled,
      isOnline: isOnline,
    );
  }

  Future<void> _initialize({
    required bool adsEnabled,
    required bool isOnline,
  }) async {
    if (_initialized) {
      debugPrint('[ADS] Already initialized');
      return;
    }

    WidgetsFlutterBinding.ensureInitialized();

    _initialized = true;
    _adsEnabled = adsEnabled;
    _isOnline = isOnline;

    if (!_adsEnabled) {
      _setStatus(RewardedAdStatus.disabled);
      return;
    }

    try {
      await MobileAds.instance.initialize();

      debugPrint('[ADS] MobileAds initialized');

      if (_isOnline) {
        loadRewardedAd(force: true);
      } else {
        debugPrint('[ADS] Init skipped load because offline');
      }
    } catch (e) {
      debugPrint('[ADS] MobileAds init error: $e');
      _setStatus(RewardedAdStatus.failed);
      _scheduleRetry();
    }
  }

  // ===============================
  // 🌐 CONNECTIVITY HOOK
  // ===============================

  void updateConnectivity({
    required bool isOnline,
  }) {
    final wasOffline = !_isOnline;
    _isOnline = isOnline;

    debugPrint('[ADS] Connectivity online=$_isOnline');

    if (!_isOnline) {
      _retryTimer?.cancel();
      _retryTimer = null;
      return;
    }

    if (wasOffline) {
      debugPrint('[ADS] Internet restored');

      _failCount = 0;
      _loadAttempt = 0;

      if (_initialized &&
          _adsEnabled &&
          !_isLoading &&
          !_isShowing &&
          _rewardedAd == null) {
        loadRewardedAd(force: true);
      }
    }
  }

  // ===============================
  // 🧯 ADS KILL SWITCH
  // ===============================

  void setAdsEnabled(bool enabled) {
    if (_adsEnabled == enabled) return;

    _adsEnabled = enabled;

    if (!enabled) {
      debugPrint('[ADS] Disabled by app config');

      _retryTimer?.cancel();
      _retryTimer = null;

      _disposeRewardedAd();

      _setStatus(RewardedAdStatus.disabled);
      return;
    }

    debugPrint('[ADS] Enabled by app config');

    if (_initialized && _isOnline) {
      loadRewardedAd(force: true);
    }
  }

  // ===============================
  // ▶️ LOAD REWARDED AD
  // ===============================

  void loadRewardedAd({
    bool force = false,
  }) {
    if (!_initialized) {
      debugPrint('[ADS] Load blocked: not initialized');
      return;
    }

    if (!_adsEnabled) {
      debugPrint('[ADS] Load blocked: ads disabled');
      return;
    }

    if (!_isOnline) {
      debugPrint('[ADS] Load blocked: offline');
      return;
    }

    if (_isLoading) {
      debugPrint('[ADS] Load blocked: already loading');
      return;
    }

    if (_isShowing) {
      debugPrint('[ADS] Load blocked: ad showing');
      return;
    }

    if (_rewardedAd != null && !force) {
      debugPrint('[ADS] Load blocked: ad already ready');
      return;
    }

    if (_failCount >= _maxConsecutiveFails && !force) {
      debugPrint('[ADS] Load blocked: max fails reached');
      _setStatus(RewardedAdStatus.failed);
      return;
    }

    _retryTimer?.cancel();
    _retryTimer = null;

    if (force && _rewardedAd != null) {
      _disposeRewardedAd();
    }

    _isLoading = true;
    _loadAttempt++;

    _setStatus(RewardedAdStatus.loading);

    debugPrint('[ADS] Loading rewarded ad. attempt=$_loadAttempt');

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('[ADS] Rewarded loaded');

          _rewardedAd?.dispose();
          _rewardedAd = ad;

          _isLoading = false;
          _failCount = 0;
          _loadAttempt = 0;

          _attachFullScreenCallbacks(ad);

          _setStatus(RewardedAdStatus.ready);
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('[ADS] Failed to load: $error');

          _rewardedAd = null;
          _isLoading = false;
          _failCount++;

          _setStatus(RewardedAdStatus.failed);

          _scheduleRetry();
        },
      ),
    );
  }

  void _attachFullScreenCallbacks(RewardedAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('[ADS] Showed fullscreen');

        _isShowing = true;
        _setStatus(RewardedAdStatus.showing);
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[ADS] Dismissed');

        try {
          ad.dispose();
        } catch (_) {}

        if (identical(_rewardedAd, ad)) {
          _rewardedAd = null;
        }

        _isShowing = false;

        _setStatus(RewardedAdStatus.idle);

        if (_adsEnabled && _isOnline) {
          loadRewardedAd();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[ADS] Failed to show: $error');

        try {
          ad.dispose();
        } catch (_) {}

        if (identical(_rewardedAd, ad)) {
          _rewardedAd = null;
        }

        _isShowing = false;
        _failCount++;

        _setStatus(RewardedAdStatus.failed);

        _scheduleRetry();
      },
    );
  }

  // ===============================
  // 🎁 SHOW REWARDED AD
  // ===============================

  Future<bool> showRewardedAd() async {
    if (!_initialized) {
      debugPrint('[ADS] Show blocked: not initialized');
      return false;
    }

    if (!_adsEnabled) {
      debugPrint('[ADS] Show blocked: ads disabled');
      return false;
    }

    if (!_isOnline) {
      debugPrint('[ADS] Show blocked: offline');
      return false;
    }

    if (_isShowing) {
      debugPrint('[ADS] Show blocked: already showing');
      return false;
    }

    final ad = _rewardedAd;

    if (ad == null) {
      debugPrint('[ADS] Show blocked: no ad ready');

      loadRewardedAd();

      return false;
    }

    _isShowing = true;
    _rewardedAd = null;

    _setStatus(RewardedAdStatus.showing);

    final completer = Completer<bool>();

    try {
      ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint(
            '[ADS] Reward earned: amount=${reward.amount}, type=${reward.type}',
          );

          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
      );
    } catch (e) {
      debugPrint('[ADS] Show exception: $e');

      _isShowing = false;

      try {
        ad.dispose();
      } catch (_) {}

      _setStatus(RewardedAdStatus.failed);

      _scheduleRetry();

      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }

    final rewarded = await completer.future.timeout(
      _rewardTimeout,
      onTimeout: () {
        debugPrint('[ADS] Reward timeout');
        return false;
      },
    );

    return rewarded;
  }

  // ===============================
  // 🔁 RETRY / BACKOFF
  // ===============================

  void _scheduleRetry() {
    if (!_initialized) return;
    if (!_adsEnabled) return;
    if (!_isOnline) return;
    if (_isLoading) return;
    if (_isShowing) return;
    if (_rewardedAd != null) return;

    if (_failCount >= _maxConsecutiveFails) {
      debugPrint('[ADS] Retry stopped. failCount=$_failCount');
      return;
    }

    final delay = _calculateBackoffDelay();

    debugPrint('[ADS] Retry scheduled in ${delay.inSeconds}s');

    _retryTimer?.cancel();

    _retryTimer = Timer(delay, () {
      loadRewardedAd(force: true);
    });
  }

  Duration _calculateBackoffDelay() {
    final exponent = min(_failCount, 6);

    final seconds = _minRetryDelay.inSeconds * pow(2, exponent).toInt();

    final cappedSeconds = min(
      seconds,
      _maxRetryDelay.inSeconds,
    );

    final jitterMs = Random().nextInt(1500);

    return Duration(
      seconds: cappedSeconds,
      milliseconds: jitterMs,
    );
  }

  // ===============================
  // 🔄 MANUAL RECOVERY
  // ===============================

  void forceReload() {
    debugPrint('[ADS] Force reload');

    _failCount = 0;
    _loadAttempt = 0;

    if (!_initialized || !_adsEnabled || !_isOnline) return;

    loadRewardedAd(force: true);
  }

  // ===============================
  // 🧹 CLEANUP
  // ===============================

  void _disposeRewardedAd() {
    try {
      _rewardedAd?.dispose();
    } catch (_) {}

    _rewardedAd = null;
    _isLoading = false;
    _isShowing = false;
  }

  void dispose() {
    debugPrint('[ADS] Disposed');

    _retryTimer?.cancel();
    _retryTimer = null;

    _disposeRewardedAd();

    if (!_statusController.isClosed) {
      _statusController.close();
    }
  }

  // ===============================
  // INTERNAL STATUS
  // ===============================

  void _setStatus(RewardedAdStatus status) {
    if (_status == status) return;

    _status = status;

    debugPrint('[ADS] Status = $status');

    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }
}