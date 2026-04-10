import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to monitor internet connection status.
class ConnectivityService {
  // Singleton instance
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  /// Stream of [ConnectivityResult] to listen for connection changes.
  ///
  /// In connectivity_plus v6.0.0+, onConnectivityChanged returns List<ConnectivityResult>.
  Stream<ConnectivityResult> get connectivityStream =>
      _connectivity.onConnectivityChanged.map((results) => results.first);

  /// Checks the current connectivity status.
  static Future<ConnectivityResult> checkStatus() async {
    final List<ConnectivityResult> results = await Connectivity()
        .checkConnectivity();
    return results.first;
  }

  /// Helper to check if there is an active internet connection (Wifi or Mobile).
  static Future<bool> isConnected() async {
    final result = await checkStatus();
    return result != ConnectivityResult.none;
  }
}
