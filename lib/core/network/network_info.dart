import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Answers "is there any point sending this request?".
///
/// Checking first turns a 30-second timeout into an instant, honest "you're
/// offline" — the difference between an app that feels broken and one that
/// feels responsive. It is a hint, not a guarantee: a connected Wi-Fi network
/// with no route to the internet still reports connected, so the timeout and
/// error paths remain the real safety net.
abstract interface class NetworkInfo {
  Future<bool> get isConnected;

  /// Emits on every connectivity transition. Used to auto-retry a failed
  /// screen the moment the device comes back online.
  Stream<bool> get onConnectivityChanged;
}

class ConnectivityNetworkInfo implements NetworkInfo {
  ConnectivityNetworkInfo(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    final List<ConnectivityResult> results = await _connectivity
        .checkConnectivity();
    return _hasConnection(results);
  }

  @override
  Stream<bool> get onConnectivityChanged => _connectivity.onConnectivityChanged
      .map(_hasConnection)
      .distinct();

  /// The plugin reports a *list* since a device can be on Wi-Fi and mobile at
  /// once. `none` is reported alone, so "any entry that is not none" is the
  /// correct reading.
  static bool _hasConnection(List<ConnectivityResult> results) {
    return results.any(
      (ConnectivityResult result) => result != ConnectivityResult.none,
    );
  }
}
