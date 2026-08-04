// lib/core/network/connectivity_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logging/app_logger.dart';

class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier(this._connectivity) : super(true) {
    _init();
  }

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> _init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      state = _hasInternet(results);

      _subscription = _connectivity.onConnectivityChanged.listen((results) {
        final isOnline = _hasInternet(results);
        if (state != isOnline) {
          state = isOnline;
          AppLogger.info(
              'Network connectivity changed: ${isOnline ? "ONLINE" : "OFFLINE"}');
        }
      });
    } catch (e) {
      AppLogger.warning('Error initializing ConnectivityNotifier: $e');
    }
  }

  bool _hasInternet(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none) || results.isEmpty) {
      return false;
    }
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier(Connectivity());
});
