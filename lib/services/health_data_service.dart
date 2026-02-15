import 'dart:io';
import 'package:health/health.dart';
import 'package:uuid/uuid.dart';
import '../models/sleep_record.dart';
import 'database_service.dart';

class HealthDataService {
  static final HealthDataService instance = HealthDataService._internal();
  HealthDataService._internal();

  final Health _health = Health();
  bool _isAuthorized = false;

  bool get isAuthorized => _isAuthorized;

  static const _sleepTypes = [
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.SLEEP_SESSION,
  ];

  static const _activityTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
  ];

  List<HealthDataType> get _allTypes => [..._sleepTypes, ..._activityTypes];

  /// Request authorization to read health data.
  Future<bool> requestAuthorization() async {
    try {
      final permissions = _allTypes.map((_) => HealthDataAccess.READ).toList();
      _isAuthorized = await _health.requestAuthorization(
        _allTypes,
        permissions: permissions,
      );
      return _isAuthorized;
    } catch (e) {
      _isAuthorized = false;
      return false;
    }
  }

  /// Check if we already have authorization.
  Future<bool> hasAuthorization() async {
    try {
      _isAuthorized = await _health.hasPermissions(_allTypes) ?? false;
      return _isAuthorized;
    } catch (_) {
      return false;
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

  /// Sync sleep data from HealthKit/Health Connect to local DB.
  /// Returns the number of new records synced.
  Future<int> syncSleepToLocal({int daysBack = 7}) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: daysBack));
    final end = now;

    final sleepData = await fetchSleepData(start, end);
    if (sleepData.isEmpty) return 0;

    // Group sleep data points into sessions by date
    final sessionsByDate = <String, _SleepSession>{};
    for (final point in sleepData) {
      final dateKey = _dateKey(point.dateFrom);
      final existing = sessionsByDate[dateKey];

      if (existing == null) {
        sessionsByDate[dateKey] = _SleepSession(
          bedTime: point.dateFrom,
          wakeTime: point.dateTo,
        );
      } else {
        // Expand the session window
        sessionsByDate[dateKey] = _SleepSession(
          bedTime: point.dateFrom.isBefore(existing.bedTime)
              ? point.dateFrom
              : existing.bedTime,
          wakeTime: point.dateTo.isAfter(existing.wakeTime)
              ? point.dateTo
              : existing.wakeTime,
        );
      }
    }

    final db = DatabaseService.instance;
    final source = Platform.isIOS ? 'healthkit' : 'health_connect';
    int synced = 0;

    for (final entry in sessionsByDate.entries) {
      final session = entry.value;
      final date = DateTime.parse(entry.key);

      // Check for existing record on this date to avoid duplicates
      final existing = await db.getSleepRecordForDate(date);
      if (existing != null) continue;

      final durationHours =
          session.wakeTime.difference(session.bedTime).inMinutes / 60.0;

      // Look up shift type for quality estimation
      final shift = await db.getShiftForDate(date);
      final shiftType = shift?.type;
      final quality = _estimateQuality(durationHours, shiftType: shiftType);

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

  String _dateKey(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day).toIso8601String().split('T')[0];
  }

  int _estimateQuality(double hours, {String? shiftType}) {
    // Night/evening shift workers have shorter sleep; adjust thresholds
    if (shiftType == 'night' || shiftType == 'evening') {
      if (hours >= 7.0) return 5;
      if (hours >= 6.0) return 4;
      if (hours >= 5.0) return 3;
      if (hours >= 4.0) return 2;
      return 1;
    }
    // Standard thresholds for day shift / off days
    if (hours >= 7.5) return 5;
    if (hours >= 6.5) return 4;
    if (hours >= 5.5) return 3;
    if (hours >= 4.0) return 2;
    return 1;
  }
}

class _SleepSession {
  final DateTime bedTime;
  final DateTime wakeTime;

  _SleepSession({required this.bedTime, required this.wakeTime});
}
