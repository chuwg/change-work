import 'dart:io';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/sleep_record.dart';
import 'database_service.dart';

class HealthDataService {
  static final HealthDataService instance = HealthDataService._internal();
  HealthDataService._internal();

  final Health _health = Health();
  bool _isAuthorized = false;

  static const _authCacheKey = 'health_auth_granted';

  bool get isAuthorized => _isAuthorized;

  static const _sleepTypes = [
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_AWAKE,
  ];

  static const _activityTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
  ];

  static const _bodyTypes = [
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
  ];

  List<HealthDataType> get _allTypes =>
      [..._sleepTypes, ..._activityTypes, ..._bodyTypes];

  /// Request authorization to read health data.
  Future<bool> requestAuthorization() async {
    try {
      final permissions = _allTypes.map((_) => HealthDataAccess.READ).toList();
      _isAuthorized = await _health.requestAuthorization(
        _allTypes,
        permissions: permissions,
      );
      // Persist auth result so it survives app restarts
      if (_isAuthorized) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_authCacheKey, true);
      }
      return _isAuthorized;
    } catch (e) {
      _isAuthorized = false;
      return false;
    }
  }

  /// Check if we already have authorization.
  /// On iOS, hasPermissions always returns null due to Apple privacy,
  /// so we rely on cached flag from SharedPreferences.
  Future<bool> hasAuthorization() async {
    if (_isAuthorized) return true;
    try {
      // Check persisted cache first
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getBool(_authCacheKey) ?? false;
      if (cached) {
        _isAuthorized = true;
        return true;
      }
      final result = await _health.hasPermissions(_allTypes);
      if (result == true) {
        _isAuthorized = true;
        await prefs.setBool(_authCacheKey, true);
        return true;
      }
      // On iOS, result is always null
      if (Platform.isIOS) return _isAuthorized;
      return false;
    } catch (_) {
      return _isAuthorized;
    }
  }

  /// Fetch sleep data for a given date range.
  Future<List<HealthDataPoint>> fetchSleepData(
    DateTime start,
    DateTime end,
  ) async {
    if (!_isAuthorized) return [];
    try {
      final data = await _health.getHealthDataFromTypes(
        types: _sleepTypes,
        startTime: start,
        endTime: end,
      );
      return _health.removeDuplicates(data);
    } catch (_) {
      return [];
    }
  }

  /// Fetch step count for a given date range.
  Future<int> fetchStepsData(DateTime start, DateTime end) async {
    if (!_isAuthorized) return 0;
    try {
      final steps = await _health.getTotalStepsInInterval(start, end);
      return steps ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Fetch heart rate data for a given date range.
  Future<List<HealthDataPoint>> fetchHeartRateData(
    DateTime start,
    DateTime end,
  ) async {
    if (!_isAuthorized) return [];
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: start,
        endTime: end,
      );
      return _health.removeDuplicates(data);
    } catch (_) {
      return [];
    }
  }

  /// Get the latest heart rate value.
  Future<double?> fetchLatestHeartRate() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(hours: 24));
    final data = await fetchHeartRateData(start, now);
    if (data.isEmpty) return null;

    data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
    final value = data.first.value;
    if (value is NumericHealthValue) {
      return value.numericValue.toDouble();
    }
    return null;
  }

  /// Get the latest weight value (kg).
  Future<double?> fetchLatestWeight() async {
    if (!_isAuthorized) return null;
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 90));
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WEIGHT],
        startTime: start,
        endTime: now,
      );
      if (data.isEmpty) return null;
      data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final value = data.first.value;
      if (value is NumericHealthValue) {
        return value.numericValue.toDouble();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get the latest height value (cm).
  Future<double?> fetchLatestHeight() async {
    if (!_isAuthorized) return null;
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 365));
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEIGHT],
        startTime: start,
        endTime: now,
      );
      if (data.isEmpty) return null;
      data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final value = data.first.value;
      if (value is NumericHealthValue) {
        final meters = value.numericValue.toDouble();
        return meters > 3 ? meters : meters * 100;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Sync sleep data from HealthKit/Health Connect to local DB.
  /// Returns the number of new records synced.
  Future<int> syncSleepToLocal({int daysBack = 30}) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: daysBack));

    final sleepData = await fetchSleepData(start, now);
    if (sleepData.isEmpty) return 0;

    // Separate session-level points from stage points
    final sessionPoints = sleepData.where((p) =>
        p.type == HealthDataType.SLEEP_SESSION ||
        p.type == HealthDataType.SLEEP_ASLEEP ||
        p.type == HealthDataType.SLEEP_IN_BED).toList();

    final stagePoints = sleepData.where((p) =>
        p.type == HealthDataType.SLEEP_DEEP ||
        p.type == HealthDataType.SLEEP_LIGHT ||
        p.type == HealthDataType.SLEEP_REM ||
        p.type == HealthDataType.SLEEP_AWAKE).toList();

    // Build consolidated sessions from session-level points
    // Merge overlapping/adjacent sessions
    final sessions = <_SleepSession>[];
    final anchors = sessionPoints.isNotEmpty ? sessionPoints : sleepData;

    for (final point in anchors) {
      final bedTime = point.dateFrom;
      final wakeTime = point.dateTo;
      // Skip very short points (< 30 min) — likely noise
      if (wakeTime.difference(bedTime).inMinutes < 30) continue;

      // Try to merge with existing sessions (within 1-hour gap)
      bool merged = false;
      for (final session in sessions) {
        if (_sessionsOverlap(session, bedTime, wakeTime)) {
          session.expand(bedTime, wakeTime);
          merged = true;
          break;
        }
      }
      if (!merged) {
        sessions.add(_SleepSession(bedTime: bedTime, wakeTime: wakeTime));
      }
    }

    final db = DatabaseService.instance;
    final source = Platform.isIOS ? 'healthkit' : 'health_connect';
    int synced = 0;

    for (final session in sessions) {
      final durationHours =
          session.wakeTime.difference(session.bedTime).inMinutes / 60.0;
      if (durationHours < 0.5) continue;

      // Use wakeTime's date as the record date
      // (e.g., slept 22:00 Feb 1 → woke 06:00 Feb 2 → date = Feb 2)
      final date = DateTime(
        session.wakeTime.year,
        session.wakeTime.month,
        session.wakeTime.day,
      );

      // If a record already exists for this date, update only if it was manual
      // (HealthKit data is more accurate than manual input)
      final existing = await db.getSleepRecordForDate(date);
      if (existing != null) {
        // Already synced from health source — skip
        if (existing.source == 'healthkit' ||
            existing.source == 'health_connect') continue;
        // Manual entry exists — overwrite with more accurate health data
        await db.deleteSleepRecord(existing.id);
      }

      final shift = await db.getShiftForDate(date);
      final shiftType = shift?.type;

      // Calculate quality: prefer stage-based, fall back to hours-based
      final quality =
          _qualityFromStages(stagePoints, session.bedTime, session.wakeTime) ??
              _estimateQuality(durationHours, shiftType: shiftType);

      final record = SleepRecord(
        id: const Uuid().v4(),
        date: date,
        bedTime: session.bedTime,
        wakeTime: session.wakeTime,
        quality: quality,
        shiftType: shiftType,
        source: source,
      );

      await db.insertSleepRecord(record);
      synced++;
    }

    return synced;
  }

  /// Calculate sleep quality (1–5) from actual Apple Watch sleep stages.
  /// Returns null if there's not enough stage data.
  int? _qualityFromStages(
    List<HealthDataPoint> stagePoints,
    DateTime bedTime,
    DateTime wakeTime,
  ) {
    double deepMin = 0, remMin = 0, lightMin = 0, awakeMin = 0;
    final window = const Duration(minutes: 30);

    for (final p in stagePoints) {
      // Only include points that overlap this session window
      if (p.dateTo.isBefore(bedTime.subtract(window))) continue;
      if (p.dateFrom.isAfter(wakeTime.add(window))) continue;

      final duration = p.dateTo.difference(p.dateFrom).inMinutes.toDouble();
      switch (p.type) {
        case HealthDataType.SLEEP_DEEP:
          deepMin += duration;
          break;
        case HealthDataType.SLEEP_REM:
          remMin += duration;
          break;
        case HealthDataType.SLEEP_LIGHT:
          lightMin += duration;
          break;
        case HealthDataType.SLEEP_AWAKE:
          awakeMin += duration;
          break;
        default:
          break;
      }
    }

    final total = deepMin + remMin + lightMin + awakeMin;
    if (total < 30) return null; // Not enough stage data

    // Weighted score: deep=5, rem=4, light=3, awake=1
    final score = (deepMin * 5 + remMin * 4 + lightMin * 3 + awakeMin * 1) / total;
    return score.round().clamp(1, 5);
  }

  /// Check if a new time window overlaps or is adjacent to an existing session.
  bool _sessionsOverlap(
    _SleepSession session,
    DateTime bedTime,
    DateTime wakeTime,
  ) {
    const gap = Duration(hours: 1);
    return bedTime.isBefore(session.wakeTime.add(gap)) &&
        wakeTime.isAfter(session.bedTime.subtract(gap));
  }

  int _estimateQuality(double hours, {String? shiftType}) {
    if (shiftType == 'night' || shiftType == 'evening') {
      if (hours >= 7.0) return 5;
      if (hours >= 6.0) return 4;
      if (hours >= 5.0) return 3;
      if (hours >= 4.0) return 2;
      return 1;
    }
    if (hours >= 7.5) return 5;
    if (hours >= 6.5) return 4;
    if (hours >= 5.5) return 3;
    if (hours >= 4.0) return 2;
    return 1;
  }
}

class _SleepSession {
  DateTime bedTime;
  DateTime wakeTime;

  _SleepSession({required this.bedTime, required this.wakeTime});

  void expand(DateTime newBed, DateTime newWake) {
    if (newBed.isBefore(bedTime)) bedTime = newBed;
    if (newWake.isAfter(wakeTime)) wakeTime = newWake;
  }
}
