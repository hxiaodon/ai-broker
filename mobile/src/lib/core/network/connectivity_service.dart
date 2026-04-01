import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_service.g.dart';

/// Wraps [Connectivity] and exposes current network status as a stream.
class ConnectivityService {
  ConnectivityService(this._connectivity);

  final Connectivity _connectivity;

  Stream<bool> get isConnectedStream => _connectivity.onConnectivityChanged
      .map((results) => results.any(_isOnline));

  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.any(_isOnline);
  }

  bool _isOnline(ConnectivityResult result) =>
      result != ConnectivityResult.none;
}

@Riverpod(keepAlive: true)
ConnectivityService connectivityService(Ref ref) {
  return ConnectivityService(Connectivity());
}
