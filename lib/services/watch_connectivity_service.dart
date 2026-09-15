import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Talks to the Apple Watch app.
///
/// The shared App Group container the widget uses does **not** reach the
/// watch — App Groups are per-device, and the watch is a separate device.
/// Everything that has to cross goes through WatchConnectivity, bridged from
/// native code in `WatchConnectivityBridge.swift`.
class WatchConnectivityService {
  static final WatchConnectivityService instance =
      WatchConnectivityService._internal();
  WatchConnectivityService._internal();

  static const MethodChannel _channel = MethodChannel('com.change.app/watch');

  /// Called with each payload the watch sends (a shift edit, an energy tap).
  Future<void> Function(Map<String, dynamic> payload)? onPayload;

  bool _listening = false;

  /// Start receiving from the watch, and pick up anything that arrived before
  /// Flutter was ready.
  Future<void> start() async {
    if (_listening) return;
    _listening = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method != 'onWatchPayload') return null;
      final payloads = call.arguments;
      if (payloads is! List) return null;
      for (final raw in payloads) {
        if (raw is Map) await _dispatch(Map<String, dynamic>.from(raw));
      }
      return null;
    });

    try {
      final queued = await _channel.invokeMethod<List<dynamic>>('drainInbound');
      for (final raw in queued ?? const []) {
        if (raw is Map) await _dispatch(Map<String, dynamic>.from(raw));
      }
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('[Watch] drain failed: $e');
    } on MissingPluginException {
      // Android or a platform without the bridge.
    }
  }

  Future<void> _dispatch(Map<String, dynamic> payload) async {
    final handler = onPayload;
    if (handler == null) return;
    try {
      await handler(payload);
    } catch (e) {
      if (kDebugMode) debugPrint('[Watch] payload handling failed: $e');
    }
  }

  /// Publish the current schedule snapshot to the watch.
  ///
  /// Uses application context, so only the newest snapshot is kept and it is
  /// delivered whenever the watch next wakes — no queue to drain.
  Future<void> sendSnapshot(Map<String, Object?> data) async {
    try {
      // The bridge forwards these straight into the watch's local cache, so
      // the keys have to match what WidgetDataReader looks for.
      await _channel.invokeMethod<bool>('sendContext', _sanitize(data));
    } on MissingPluginException {
      // Not iOS — nothing to do.
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('[Watch] sendContext failed: $e');
    }
  }

  /// Whether there is a paired watch with the app installed.
  Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('isReachable') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// WatchConnectivity only accepts property-list types.
  Map<String, Object?> _sanitize(Map<String, Object?> data) {
    final out = <String, Object?>{};
    data.forEach((key, value) {
      if (value == null) return;
      if (value is String || value is num || value is bool) {
        out[key] = value;
      } else {
        out[key] = jsonEncode(value);
      }
    });
    return out;
  }
}
