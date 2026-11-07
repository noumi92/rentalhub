import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Phase B (B2): connectivity awareness.
///
/// Wraps `connectivity_plus` and exposes a debounced online/offline
/// stream. The plugin's own stream is already distinct, but a phone
/// flapping between networks (lift, basement, handover between
/// Wi-Fi and mobile) can still emit rapid transitions — the 300 ms
/// debounce coalesces those so the sync trigger (B2/B3) never fires
/// twice for one real reconnect.
///
/// Degrades gracefully: if the plugin is unavailable (emulator
/// without it, a platform error), the service assumes online so
/// nothing blocks — the sync queue still retries on failure.
///
/// The connectivity source is injectable so tests can drive it with
/// a fake stream instead of the platform plugin.
class ConnectivityService {
  final Future<List<ConnectivityResult>> Function() _checkConnectivity;
  final Stream<List<ConnectivityResult>> _changes;
  final Duration _debounce;

  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _debounceTimer;
  bool _isOnline = true;
  bool _started = false;

  ConnectivityService({
    Future<List<ConnectivityResult>> Function()? checkConnectivity,
    Stream<List<ConnectivityResult>>? connectivityChanges,
    Duration debounce = const Duration(milliseconds: 300),
  })  : _checkConnectivity =
            checkConnectivity ?? Connectivity().checkConnectivity,
        _changes =
            connectivityChanges ?? Connectivity().onConnectivityChanged,
        _debounce = debounce;

  /// Last known state. Starts as online: assuming connectivity until
  /// proven otherwise keeps flows unblocked at launch.
  bool get isOnline => _isOnline;

  /// Debounced online/offline transitions (emits only on change).
  Stream<bool> get onlineStream => _controller.stream;

  /// Reads the current state once, then listens for changes.
  /// Safe to call twice — the second call is a no-op.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      _apply(await _checkConnectivity());
    } catch (e) {
      debugPrint('Connectivity check notice: $e');
    }
    try {
      _subscription = _changes.listen(
        _apply,
        onError: (_) {},
      );
    } catch (e) {
      debugPrint('Connectivity listen notice: $e');
    }
  }

  void _apply(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online == _isOnline) {
      // Flapped back before the pending flip fired — cancel it.
      _debounceTimer?.cancel();
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      if (online == _isOnline) return;
      _isOnline = online;
      _controller.add(_isOnline);
    });
  }

  Future<void> dispose() async {
    _debounceTimer?.cancel();
    await _subscription?.cancel();
    await _controller.close();
  }
}
