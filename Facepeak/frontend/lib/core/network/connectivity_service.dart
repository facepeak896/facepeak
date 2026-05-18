import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum NetworkStatus {
  online,
  offline,
  checking,
}

class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final StreamController<NetworkStatus> _statusController =
      StreamController<NetworkStatus>.broadcast();

  Stream<NetworkStatus> get statusStream => _statusController.stream;

  NetworkStatus _currentStatus = NetworkStatus.checking;

  NetworkStatus get currentStatus => _currentStatus;

  bool get isOnline => _currentStatus == NetworkStatus.online;

  bool _isInitialized = false;
  bool _isRefreshing = false;
  Timer? _debounceTimer;

  Future<void> Function()? onInternetRestored;
  Future<void> Function()? onInternetLost;

  Future<void> initialize({
    Future<void> Function()? onRestored,
    Future<void> Function()? onLost,
  }) async {
    if (_isInitialized) return;

    _isInitialized = true;
    onInternetRestored = onRestored;
    onInternetLost = onLost;

    debugPrint("🌐 ConnectivityService initialized");

    await _checkInitialConnection();

    _subscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
      onError: (error) {
        debugPrint("❌ CONNECTIVITY STREAM ERROR = $error");
      },
    );
  }

  Future<void> _checkInitialConnection() async {
    _setStatus(NetworkStatus.checking);

    final results = await _connectivity.checkConnectivity();

    await _evaluateConnection(results);
  }

  void _handleConnectivityChange(
    List<ConnectivityResult> results,
  ) {
    debugPrint("🌐 CONNECTIVITY CHANGED = $results");

    _debounceTimer?.cancel();

    _debounceTimer = Timer(
      const Duration(milliseconds: 700),
      () async {
        await _evaluateConnection(results);
      },
    );
  }

  Future<void> _evaluateConnection(
    List<ConnectivityResult> results,
  ) async {
    final hasNetworkInterface =
        results.isNotEmpty &&
        !results.contains(ConnectivityResult.none);

    if (!hasNetworkInterface) {
      await _goOffline();
      return;
    }

    _setStatus(NetworkStatus.checking);

    final hasRealInternet = await _hasRealInternetAccess();

    if (hasRealInternet) {
      await _goOnline();
    } else {
      await _goOffline();
    }
  }

  Future<bool> _hasRealInternetAccess() async {
    try {
      final response = await http
          .get(
            Uri.parse("https://www.google.com/generate_204"),
          )
          .timeout(
            const Duration(seconds: 3),
          );

      return response.statusCode == 204 ||
          response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ REAL INTERNET CHECK FAILED = $e");
      return false;
    }
  }

  Future<void> _goOnline() async {
    final wasOffline = _currentStatus == NetworkStatus.offline;

    _setStatus(NetworkStatus.online);

    if (wasOffline) {
      debugPrint("✅ INTERNET RESTORED");

      if (_isRefreshing) return;

      _isRefreshing = true;

      try {
        await onInternetRestored?.call();
      } catch (e) {
        debugPrint("❌ INTERNET RESTORE CALLBACK ERROR = $e");
      } finally {
        _isRefreshing = false;
      }
    }
  }

  Future<void> _goOffline() async {
    final wasOnline = _currentStatus == NetworkStatus.online;

    _setStatus(NetworkStatus.offline);

    if (wasOnline) {
      debugPrint("❌ INTERNET LOST");

      try {
        await onInternetLost?.call();
      } catch (e) {
        debugPrint("❌ INTERNET LOST CALLBACK ERROR = $e");
      }
    }
  }

  void _setStatus(NetworkStatus status) {
    if (_currentStatus == status) return;

    _currentStatus = status;

    debugPrint("🌐 NETWORK STATUS = $status");

    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  Future<void> forceRefresh() async {
    debugPrint("🔄 FORCE CONNECTIVITY REFRESH");

    final results = await _connectivity.checkConnectivity();

    await _evaluateConnection(results);
  }

  void dispose() {
    debugPrint("🧹 ConnectivityService disposed");

    _debounceTimer?.cancel();
    _subscription?.cancel();
    _statusController.close();
  }
}