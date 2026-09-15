import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/health_data_service.dart';
import '../services/database_service.dart';
import '../services/widget_service.dart';
import '../providers/sleep_provider.dart';
import '../providers/energy_provider.dart';
import '../providers/schedule_provider.dart';
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

  /// Sentinel so `copyWith` can tell "leave as is" apart from "set to null".
  /// Without it a failed HealthKit read silently kept the previous reading.
  static const Object _unset = Object();

  HealthSyncState copyWith({
    bool? isAuthorized,
    bool? isSyncing,
    bool? syncEnabled,
    DateTime? lastSyncAt,
    Object? todaySteps = _unset,
    Object? lastHeartRate = _unset,
    bool clearLastSync = false,
  }) {
    return HealthSyncState(
      isAuthorized: isAuthorized ?? this.isAuthorized,
      isSyncing: isSyncing ?? this.isSyncing,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      lastSyncAt: clearLastSync ? null : (lastSyncAt ?? this.lastSyncAt),
      todaySteps:
          identical(todaySteps, _unset) ? this.todaySteps : todaySteps as int?,
      lastHeartRate: identical(lastHeartRate, _unset)
          ? this.lastHeartRate
          : lastHeartRate as double?,
    );
  }
}

class HealthSyncNotifier extends StateNotifier<HealthSyncState> {
  final Ref ref;
  final HealthDataService _healthService = HealthDataService.instance;

  /// Completes once the persisted settings have been read. Anything that
  /// branches on [HealthSyncState.syncEnabled] must await this first — it is
  /// false until SharedPreferences comes back, and a caller that checked too
  /// early would skip the sync entirely and never retry.
  late final Future<void> _settingsLoaded;

  HealthSyncNotifier(this.ref) : super(const HealthSyncState()) {
    _settingsLoaded = _loadSettings();
    // Kick the first sync off without blocking construction.
    _settingsLoaded.then((_) {
      if (state.syncEnabled) autoSync();
    });
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

      // Sync weight/height to user profile if available
      await _syncBodyMeasurements();

      // Import anything the watch queued while it was on its own
      await _importWatchEnergyRecords();
      await _importWatchShiftChanges();

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

  /// Sync weight/height from HealthKit to user profile.
  Future<void> _syncBodyMeasurements() async {
    try {
      final weight = await _healthService.fetchLatestWeight();
      final height = await _healthService.fetchLatestHeight();

      if (weight == null && height == null) return;

      final db = DatabaseService.instance;
      final profile = await db.getUserProfile();

      if (profile != null) {
        final updated = profile.copyWith(
          weightKg: weight ?? profile.weightKg,
          heightCm: height ?? profile.heightCm,
        );
        await db.saveUserProfile(updated);
      } else {
        // Create a minimal profile with body measurements
        final newProfile = UserProfile(
          weightKg: weight,
          heightCm: height,
        );
        await db.saveUserProfile(newProfile);
      }
    } catch (_) {
      // Silently fail - body measurements are optional
    }
  }

  /// Import energy records written by Apple Watch app.
  Future<void> _importWatchEnergyRecords() async {
    try {
      final records = await WidgetService.instance.readWatchEnergyRecords();
      if (records.isEmpty) return;

      final schedule = ref.read(scheduleProvider);

      for (final record in records) {
        final level = record['energy_level'] as int?;
        final timestampStr = record['timestamp'] as String?;
        if (level == null || timestampStr == null) continue;

        final timestamp = DateTime.tryParse(timestampStr);
        if (timestamp == null) continue;

        // The timestamp used to be parsed and then thrown away, so a level
        // tapped at 03:00 was filed at whatever time the phone happened to
        // sync — which also put it on the wrong day and the wrong shift.
        final shiftType = schedule.getShiftTypeForDate(timestamp);

        await ref.read(energyProvider.notifier).addEnergyRecord(
              energyLevel: level,
              shiftType: shiftType.isEmpty ? null : shiftType,
              source: 'watch',
              timestamp: timestamp,
            );
      }

      // Clear pending records after import
      await WidgetService.instance.clearWatchEnergyRecords();
    } catch (_) {}
  }

  /// Apply shift changes made on the watch.
  ///
  /// The watch can only queue them — it has no database — so the phone is what
  /// actually writes the shift and reschedules notifications for it.
  Future<void> _importWatchShiftChanges() async {
    try {
      final changes = await WidgetService.instance.readWatchShiftChanges();
      if (changes.isEmpty) return;

      for (final change in changes) {
        final dateStr = change['date'] as String?;
        final type = change['type'] as String?;
        if (dateStr == null || type == null) continue;

        final date = DateTime.tryParse(dateStr);
        if (date == null) continue;
        if (!AppConstants.shiftTypes.contains(type)) continue;

        // addShift writes the shift, refreshes the widget and reschedules the
        // notifications that depend on it.
        await ref.read(scheduleProvider.notifier).addShift(date, type);
      }

      await WidgetService.instance.clearWatchShiftChanges();
    } catch (_) {}
  }

  /// Auto sync on app start (when sync is enabled).
  /// Also picks up any data synced by iOS background delivery.
  ///
  /// [minInterval] skips the HealthKit round-trip when the last sync is more
  /// recent than that. Callers triggered by navigation pass a short window so
  /// flipping between tabs doesn't re-read HealthKit every time; an explicit
  /// pull-to-refresh passes nothing and always syncs.
  Future<void> autoSync({Duration? minInterval}) async {
    await _settingsLoaded;
    if (!state.syncEnabled) return;

    // Always drain the watch queues even if a full sync isn't needed
    await _importWatchEnergyRecords();
    await _importWatchShiftChanges();

    final last = state.lastSyncAt;
    if (minInterval != null &&
        last != null &&
        DateTime.now().difference(last) < minInterval) {
      return;
    }

    await syncNow();
  }
}

final healthSyncProvider =
    StateNotifierProvider<HealthSyncNotifier, HealthSyncState>((ref) {
  return HealthSyncNotifier(ref);
});
