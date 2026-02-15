import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/health_data_service.dart';
import '../providers/sleep_provider.dart';
import '../utils/constants.dart';

class HealthSyncState {
  final bool isAuthorized;
  final bool isSyncing;
  final bool syncEnabled;
  final DateTime? lastSyncAt;
  final int? todaySteps;
  final double? lastHeartRate;

  const HealthSyncState({
    this.isAuthorized = false,
    this.isSyncing = false,
    this.syncEnabled = false,
    this.lastSyncAt,
    this.todaySteps,
    this.lastHeartRate,
  });

  HealthSyncState copyWith({
    bool? isAuthorized,
    bool? isSyncing,
    bool? syncEnabled,
    DateTime? lastSyncAt,
    int? todaySteps,
    double? lastHeartRate,
    bool clearLastSync = false,
  }) {
    return HealthSyncState(
      isAuthorized: isAuthorized ?? this.isAuthorized,
      isSyncing: isSyncing ?? this.isSyncing,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      lastSyncAt: clearLastSync ? null : (lastSyncAt ?? this.lastSyncAt),
      todaySteps: todaySteps ?? this.todaySteps,
      lastHeartRate: lastHeartRate ?? this.lastHeartRate,
    );
  }
}

class HealthSyncNotifier extends StateNotifier<HealthSyncState> {
  final Ref ref;
  final HealthDataService _healthService = HealthDataService.instance;

  HealthSyncNotifier(this.ref) : super(const HealthSyncState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(AppConstants.healthSyncEnabledKey) ?? false;
    final lastSyncStr = prefs.getString(AppConstants.lastHealthSyncKey);
    final lastSync =
        lastSyncStr != null ? DateTime.tryParse(lastSyncStr) : null;

    state = state.copyWith(
      syncEnabled: enabled,
      lastSyncAt: lastSync,
    );

    if (enabled) {
      await autoSync();
    }
  }

  /// Toggle health data sync ON/OFF.
  /// Returns false if authorization was denied.
  Future<bool> toggleSync(bool enabled) async {
    if (enabled) {
      // Request authorization first
      final authorized = await _healthService.requestAuthorization();
      if (!authorized) return false;

      state = state.copyWith(syncEnabled: true, isAuthorized: true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.healthSyncEnabledKey, true);

      await syncNow();
    } else {
      state = state.copyWith(
        syncEnabled: false,
        todaySteps: null,
        lastHeartRate: null,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.healthSyncEnabledKey, false);
    }
    return true;
  }

  /// Manual sync trigger.
  Future<void> syncNow() async {
    if (state.isSyncing) return;

    state = state.copyWith(isSyncing: true);

    try {
      // Check authorization
      final hasAuth = await _healthService.hasAuthorization();
      if (!hasAuth) {
        final authorized = await _healthService.requestAuthorization();
        if (!authorized) {
          state = state.copyWith(isSyncing: false, isAuthorized: false);
          return;
        }
      }
      state = state.copyWith(isAuthorized: true);

      // Sync sleep data
      await _healthService.syncSleepToLocal();

      // Fetch today's steps
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final steps = await _healthService.fetchStepsData(todayStart, now);

      // Fetch latest heart rate
      final heartRate = await _healthService.fetchLatestHeartRate();

      // Save last sync time
      final syncTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.lastHealthSyncKey,
        syncTime.toIso8601String(),
      );

      state = state.copyWith(
        isSyncing: false,
        lastSyncAt: syncTime,
        todaySteps: steps,
        lastHeartRate: heartRate,
      );

      // Reload sleep records in sleep provider
      ref.read(sleepProvider.notifier).loadRecords();
    } catch (_) {
      state = state.copyWith(isSyncing: false);
    }
  }

  /// Auto sync on app start (when sync is enabled).
  Future<void> autoSync() async {
    if (!state.syncEnabled) return;
    await syncNow();
  }
}

final healthSyncProvider =
    StateNotifierProvider<HealthSyncNotifier, HealthSyncState>((ref) {
  return HealthSyncNotifier(ref);
});
