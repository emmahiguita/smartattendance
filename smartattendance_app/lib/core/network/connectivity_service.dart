// lib/core/network/connectivity_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logging/app_logger.dart';

/// Inicia en false (conservador: asume offline hasta confirmar).
/// _init() corrige el estado tras la primera verificación asíncrona,
/// evitando que el banner muestre "Online" falsamente al arrancar.
class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier(this._connectivity) : super(false) {
    _init();
  }

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _disposed = false;

  Future<void> _init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      // El proveedor puede destruirse mientras la consulta del plugin espera.
      // Evita crear una suscripción tardía sobre un notifier ya liberado.
      if (_disposed) return;
      state = _hasInternet(results);

      _subscription = _connectivity.onConnectivityChanged.listen((results) {
        // Ignora eventos que ya estaban en cola al cancelar la suscripción.
        if (_disposed) return;
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
    // Marca primero el cierre para bloquear callbacks durante la cancelación.
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier(Connectivity());
});
