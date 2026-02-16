import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/shift.dart';
import '../models/shift_pattern.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

const _uuid = Uuid();

class ScheduleState {
  final Map<DateTime, Shift> shifts;
  final ShiftPattern? activePattern;
  final DateTime? patternStartDate;
  final bool isLoading;

  const ScheduleState({
    this.shifts = const {},
    this.activePattern,
    this.patternStartDate,
    this.isLoading = false,
  });

  ScheduleState copyWith({
    Map<DateTime, Shift>? shifts,
    ShiftPattern? activePattern,
    DateTime? patternStartDate,
    bool? isLoading,
  }) {
    return ScheduleState(
      shifts: shifts ?? this.shifts,
      activePattern: activePattern ?? this.activePattern,
      patternStartDate: patternStartDate ?? this.patternStartDate,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Shift? getShiftForDate(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return shifts[key];
  }

  String getShiftTypeForDate(DateTime date) {
    return getShiftForDate(date)?.type ?? '';
  }

  Shift? get todayShift => getShiftForDate(DateTime.now());

  Shift? get nextShift {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (int i = 1; i <= 30; i++) {
      final date = today.add(Duration(days: i));
      final shift = getShiftForDate(date);
      if (shift != null && shift.type != AppConstants.shiftOff) {
        return shift;
      }
    }
    return null;
  }

  int get daysUntilNextOff {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (int i = 1; i <= 30; i++) {
      final date = today.add(Duration(days: i));
      final shift = getShiftForDate(date);
      if (shift?.type == AppConstants.shiftOff) return i;
    }
    return -1;
  }
}

class ScheduleNotifier extends StateNotifier<ScheduleState> {
  final DatabaseService _db;

  ScheduleNotifier(this._db) : super(const ScheduleState());

  /// Get shift times for a type, using custom times if set, otherwise defaults.
  static Future<Map<String, String>?> getShiftTimes(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.customShiftTimesKey);
    if (saved != null) {
      final decoded = jsonDecode(saved) as Map<String, dynamic>;
      final typeMap = decoded[type] as Map<String, dynamic>?;
      if (typeMap != null) {
        return Map<String, String>.from(typeMap);
      }
    }
    return AppConstants.defaultShiftTimes[type] != null
        ? Map<String, String>.from(AppConstants.defaultShiftTimes[type]!)
        : null;
  }

  Future<void> loadShiftsForMonth(int year, int month) async {
    state = state.copyWith(isLoading: true);
    final shifts = await _db.getShiftsForMonth(year, month);
    final shiftMap = Map<DateTime, Shift>.from(state.shifts);
    for (final shift in shifts) {
      final key = DateTime(shift.date.year, shift.date.month, shift.date.day);
      shiftMap[key] = shift;
    }
    state = state.copyWith(shifts: shiftMap, isLoading: false);
  }

  Future<void> addShift(DateTime date, String type, {String? note}) async {
    final dateKey = DateTime(date.year, date.month, date.day);
    final times = await getShiftTimes(type);
    final shift = Shift(
      id: _uuid.v4(),
      date: dateKey,
      type: type,
      startTime: times?['start'],
      endTime: times?['end'],
      note: note,
    );
    await _db.insertShift(shift);

    final shiftMap = Map<DateTime, Shift>.from(state.shifts);
    shiftMap[dateKey] = shift;
    state = state.copyWith(shifts: shiftMap);
  }

  Future<void> applyPattern(
    ShiftPattern pattern,
    DateTime startDate,
    int months,
  ) async {
    state = state.copyWith(
      activePattern: pattern,
      patternStartDate: startDate,
      isLoading: true,
    );

    final shifts = <Shift>[];
    final endDate = DateTime(
      startDate.year,
      startDate.month + months,
      startDate.day,
    );
    final totalDays = endDate.difference(startDate).inDays;

    // Load custom times once
    final prefs = await SharedPreferences.getInstance();
    final savedTimes = prefs.getString(AppConstants.customShiftTimesKey);
    final customTimes = savedTimes != null
        ? (jsonDecode(savedTimes) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, Map<String, String>.from(v as Map)))
        : <String, Map<String, String>>{};

    for (int i = 0; i < totalDays; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey = DateTime(date.year, date.month, date.day);
      final patternIndex = i % pattern.pattern.length;
      final type = pattern.pattern[patternIndex];
      final times = customTimes[type] ?? AppConstants.defaultShiftTimes[type];

      shifts.add(Shift(
        id: _uuid.v4(),
        date: dateKey,
        type: type,
        startTime: times?['start'],
        endTime: times?['end'],
      ));
    }

    await _db.insertShifts(shifts);

    final shiftMap = Map<DateTime, Shift>.from(state.shifts);
    for (final shift in shifts) {
      final key = DateTime(shift.date.year, shift.date.month, shift.date.day);
      shiftMap[key] = shift;
    }

    state = state.copyWith(shifts: shiftMap, isLoading: false);

    await _db.setSetting('active_pattern_id', pattern.id);
    await _db.setSetting('pattern_start_date', startDate.toIso8601String());
  }

  Future<void> removeShift(DateTime date) async {
    final dateKey = DateTime(date.year, date.month, date.day);
    final shift = state.shifts[dateKey];
    if (shift != null) {
      await _db.deleteShift(shift.id);
      final shiftMap = Map<DateTime, Shift>.from(state.shifts);
      shiftMap.remove(dateKey);
      state = state.copyWith(shifts: shiftMap);
    }
  }
}

final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, ScheduleState>((ref) {
  return ScheduleNotifier(DatabaseService.instance);
});
