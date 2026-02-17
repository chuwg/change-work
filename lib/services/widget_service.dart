import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../providers/schedule_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class WidgetService {
  static final WidgetService instance = WidgetService._internal();
  WidgetService._internal();

  bool _isInitialized = false;

  static const String _iOSWidgetName = 'ChangeWidget';
  static const String _androidSmallWidget =
      'com.change.app.change.ShiftWidgetSmall';
  static const String _androidMediumWidget =
      'com.change.app.change.ShiftWidgetMedium';

  // Cache keys — schedule
  static const String keyTodayType = 'widget_today_shift_type';
  static const String keyTodayStart = 'widget_today_shift_start';
  static const String keyTodayEnd = 'widget_today_shift_end';
  static const String keyTodayLabel = 'widget_today_shift_label';
  static const String keyDaysUntilOff = 'widget_days_until_off';
  static const String keyWeekShifts = 'widget_week_shifts';
  static const String keyLastUpdated = 'widget_last_updated';

  // Cache keys — energy / sleep (for Watch)
  static const String keyEnergyLatest = 'widget_energy_latest';
  static const String keyEnergyAvg = 'widget_energy_avg';
  static const String keySleepHours = 'widget_sleep_hours';
  static const String keySleepQuality = 'widget_sleep_quality';
  static const String keyWatchEnergyPending = 'watch_energy_pending';

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await HomeWidget.setAppGroupId(AppConstants.appGroupId);
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('[WidgetService] init failed: $e');
    }
  }

  Future<void> updateWidgetData(ScheduleState state) async {
    try {
      await _writeSharedData(state);
      await _triggerWidgetReload();
    } catch (e) {
      if (kDebugMode) debugPrint('[WidgetService] update failed: $e');
    }
  }

  Future<void> _writeSharedData(ScheduleState state) async {
    final today = state.todayShift;
    final shiftType = today?.type ?? 'none';
    final shiftLabel =
        today != null ? AppHelpers.getShiftLabel(today.type) : '미등록';

    final startTime = today?.startTime ?? '';
    final endTime = today?.endTime ?? '';
    final resolvedStart = startTime.isNotEmpty
        ? startTime
        : (AppConstants.defaultShiftTimes[shiftType]?['start'] ?? '');
    final resolvedEnd = endTime.isNotEmpty
        ? endTime
        : (AppConstants.defaultShiftTimes[shiftType]?['end'] ?? '');

    await HomeWidget.saveWidgetData(keyTodayType, shiftType);
    await HomeWidget.saveWidgetData(keyTodayLabel, shiftLabel);
    await HomeWidget.saveWidgetData(keyTodayStart, resolvedStart);
    await HomeWidget.saveWidgetData(keyTodayEnd, resolvedEnd);
    await HomeWidget.saveWidgetData(
        keyDaysUntilOff, state.daysUntilNextOff);
    await HomeWidget.saveWidgetData(
        keyWeekShifts, _buildWeekShiftsJson(state));
    await HomeWidget.saveWidgetData(
        keyLastUpdated, DateTime.now().toIso8601String());
  }

  String _buildWeekShiftsJson(ScheduleState state) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final week = List.generate(7, (i) => today.add(Duration(days: i)));

    final entries = week.map((date) {
      final shift = state.getShiftForDate(date);
      return {
        'date':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'type': shift?.type ?? 'none',
        'label':
            shift != null ? AppHelpers.getShiftLabel(shift.type) : '-',
      };
    }).toList();

    return jsonEncode(entries);
  }

  Future<void> updateEnergyData({
    int? latestLevel,
    double averageEnergy = 0,
  }) async {
    try {
      if (latestLevel != null) {
        await HomeWidget.saveWidgetData(keyEnergyLatest, latestLevel);
      }
      await HomeWidget.saveWidgetData(keyEnergyAvg, averageEnergy);
    } catch (e) {
      if (kDebugMode) debugPrint('[WidgetService] energy update failed: $e');
    }
  }

  Future<void> updateSleepData({
    double sleepHours = 0,
    int sleepQuality = 0,
  }) async {
    try {
      await HomeWidget.saveWidgetData(keySleepHours, sleepHours);
      await HomeWidget.saveWidgetData(keySleepQuality, sleepQuality);
    } catch (e) {
      if (kDebugMode) debugPrint('[WidgetService] sleep update failed: $e');
    }
  }

  Future<List<Map<String, dynamic>>> readWatchEnergyRecords() async {
    try {
      final jsonString =
          await HomeWidget.getWidgetData<String>(keyWatchEnergyPending);
      if (jsonString == null || jsonString.isEmpty) return [];
      final list = jsonDecode(jsonString) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WidgetService] read watch energy failed: $e');
      }
      return [];
    }
  }

  Future<void> clearWatchEnergyRecords() async {
    try {
      await HomeWidget.saveWidgetData(keyWatchEnergyPending, '[]');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WidgetService] clear watch energy failed: $e');
      }
    }
  }

  Future<void> _triggerWidgetReload() async {
    await HomeWidget.updateWidget(
      iOSName: _iOSWidgetName,
      qualifiedAndroidName: _androidSmallWidget,
    );
    await HomeWidget.updateWidget(
      iOSName: _iOSWidgetName,
      qualifiedAndroidName: _androidMediumWidget,
    );
  }
}
