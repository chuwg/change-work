import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/salary_calculation.dart';
import '../models/salary_settings.dart';
import '../models/shift.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

class SalaryState {
  final SalarySettings settings;
  final SalaryCalculation? calculation;
  final int selectedYear;
  final int selectedMonth;
  final bool isLoading;
  final bool isConfigured;

  const SalaryState({
    this.settings = const SalarySettings(),
    this.calculation,
    required this.selectedYear,
    required this.selectedMonth,
    this.isLoading = false,
    this.isConfigured = false,
  });

  SalaryState copyWith({
    SalarySettings? settings,
    SalaryCalculation? calculation,
    int? selectedYear,
    int? selectedMonth,
    bool? isLoading,
    bool? isConfigured,
  }) {
    return SalaryState(
      settings: settings ?? this.settings,
      calculation: calculation ?? this.calculation,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      isLoading: isLoading ?? this.isLoading,
      isConfigured: isConfigured ?? this.isConfigured,
    );
  }
}

class SalaryNotifier extends StateNotifier<SalaryState> {
  final DatabaseService _db;

  SalaryNotifier(this._db)
      : super(SalaryState(
          selectedYear: DateTime.now().year,
          selectedMonth: DateTime.now().month,
        ));

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(AppConstants.salarySettingsKey);
      if (json != null) {
        final settings = SalarySettings.fromJson(json);
        final configured = settings.payType == AppConstants.payTypeHourly
            ? settings.hourlyRate > 0
            : settings.monthlySalary > 0;
        state = state.copyWith(settings: settings, isConfigured: configured);
      }
    } catch (_) {}
  }

  Future<void> saveSettings(SalarySettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.salarySettingsKey, settings.toJson());
      final configured = settings.payType == AppConstants.payTypeHourly
          ? settings.hourlyRate > 0
          : settings.monthlySalary > 0;
      state = state.copyWith(settings: settings, isConfigured: configured);
      await calculateForMonth(state.selectedYear, state.selectedMonth);
    } catch (_) {}
  }

  Future<void> goToPreviousMonth() async {
    final prev = DateTime(state.selectedYear, state.selectedMonth - 1);
    state = state.copyWith(
      selectedYear: prev.year,
      selectedMonth: prev.month,
    );
    await calculateForMonth(prev.year, prev.month);
  }

  Future<void> goToNextMonth() async {
    final next = DateTime(state.selectedYear, state.selectedMonth + 1);
    state = state.copyWith(
      selectedYear: next.year,
      selectedMonth: next.month,
    );
    await calculateForMonth(next.year, next.month);
  }

  Future<void> calculateForMonth(int year, int month) async {
    if (!state.isConfigured) return;
    state = state.copyWith(isLoading: true);
    try {
      final shifts = await _db.getShiftsForMonth(year, month);
      final calc = _compute(shifts, state.settings, year, month);
      state = state.copyWith(calculation: calc, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  SalaryCalculation _compute(
    List<Shift> shifts,
    SalarySettings settings,
    int year,
    int month,
  ) {
    final workingShifts =
        shifts.where((s) => s.type != AppConstants.shiftOff).toList();

    final Map<String, _ShiftAccum> accum = {
      AppConstants.shiftDay: _ShiftAccum(),
      AppConstants.shiftEvening: _ShiftAccum(),
      AppConstants.shiftNight: _ShiftAccum(),
    };

    double totalWorkHours = 0;
    double totalNightHours = 0;
    double weekendWorkHours = 0;
    int weekendDays = 0;
    int nightShiftCount = 0;

    for (final shift in workingShifts) {
      final times = _resolveShiftTimes(shift);
      final hours = _calcHours(times.start, times.end);
      final nightH = _calcNightHours(times.start, times.end);
      final isWeekend = shift.date.weekday == DateTime.saturday ||
          shift.date.weekday == DateTime.sunday;

      accum[shift.type]?.add(hours, nightH);
      totalWorkHours += hours;
      totalNightHours += nightH;
      if (isWeekend) {
        weekendWorkHours += hours;
        weekendDays++;
      }
      if (shift.type == AppConstants.shiftNight) nightShiftCount++;
    }

    // Effective hourly rate
    double effectiveHourlyRate;
    if (settings.payType == AppConstants.payTypeMonthly) {
      final totalShiftHours =
          workingShifts.length * AppConstants.defaultShiftHours;
      effectiveHourlyRate =
          totalShiftHours > 0 ? settings.monthlySalary / totalShiftHours : 0;
    } else {
      effectiveHourlyRate = settings.hourlyRate;
    }

    // Overtime
    final weeksInMonth = _daysInMonth(year, month) / 7.0;
    final overtimeHours = max(
        0.0,
        totalWorkHours -
            (AppConstants.overtimeThresholdHoursPerWeek * weeksInMonth));

    // Pay components
    final basePay = totalWorkHours * effectiveHourlyRate;
    final nightPremium =
        totalNightHours * effectiveHourlyRate * (settings.nightMultiplier - 1);
    final weekendPremium = weekendWorkHours *
        effectiveHourlyRate *
        (settings.weekendMultiplier - 1);
    final overtimePay = overtimeHours *
        effectiveHourlyRate *
        (settings.overtimeMultiplier - 1);

    // Fixed allowances
    double fixedTotal = 0;
    for (final a in settings.fixedAllowances) {
      fixedTotal += a.perShift ? a.amount * workingShifts.length : a.amount;
    }

    final totalGross =
        basePay + nightPremium + weekendPremium + overtimePay + fixedTotal;

    // Per-type breakdowns
    final breakdowns = accum.entries
        .where((e) => e.value.count > 0)
        .map((e) {
      final a = e.value;
      final regularH = a.totalHours - a.nightHours;
      final bp = a.totalHours * effectiveHourlyRate;
      final np =
          a.nightHours * effectiveHourlyRate * (settings.nightMultiplier - 1);
      return ShiftSalaryBreakdown(
        shiftType: e.key,
        count: a.count,
        totalHours: a.totalHours,
        regularHours: regularH,
        nightHours: a.nightHours,
        basePay: bp,
        nightPremium: np,
        total: bp + np,
      );
    }).toList();

    return SalaryCalculation(
      year: year,
      month: month,
      settings: settings,
      basePay: basePay,
      nightPremium: nightPremium,
      weekendPremium: weekendPremium,
      overtimePay: overtimePay,
      fixedAllowancesTotal: fixedTotal,
      totalGross: totalGross,
      shiftBreakdowns: breakdowns,
      totalWorkHours: totalWorkHours,
      totalNightHours: totalNightHours,
      overtimeHours: overtimeHours,
      workingDays: workingShifts.length,
      weekendDays: weekendDays,
      nightShifts: nightShiftCount,
    );
  }

  _ShiftTimes _resolveShiftTimes(Shift shift) {
    final defaults = AppConstants.defaultShiftTimes[shift.type] ??
        {'start': '09:00', 'end': '18:00'};
    final startStr = shift.startTime ?? defaults['start']!;
    final endStr = shift.endTime ?? defaults['end']!;
    return _ShiftTimes(
      start: _parseHHmm(startStr, shift.date),
      end: _parseHHmm(endStr, shift.date),
    );
  }

  DateTime _parseHHmm(String hhmm, DateTime baseDate) {
    final parts = hhmm.split(':');
    return DateTime(baseDate.year, baseDate.month, baseDate.day,
        int.parse(parts[0]), int.parse(parts[1]));
  }

  double _calcHours(DateTime start, DateTime end) {
    final effectiveEnd =
        end.isAfter(start) ? end : end.add(const Duration(days: 1));
    return effectiveEnd.difference(start).inMinutes / 60.0;
  }

  double _calcNightHours(DateTime start, DateTime end) {
    final effectiveEnd =
        end.isAfter(start) ? end : end.add(const Duration(days: 1));
    final nightStart =
        DateTime(start.year, start.month, start.day, 22, 0);
    final nightEnd =
        DateTime(start.year, start.month, start.day + 1, 6, 0);

    final overlapStart = start.isAfter(nightStart) ? start : nightStart;
    final overlapEnd =
        effectiveEnd.isBefore(nightEnd) ? effectiveEnd : nightEnd;

    if (overlapEnd.isAfter(overlapStart)) {
      return overlapEnd.difference(overlapStart).inMinutes / 60.0;
    }
    return 0.0;
  }

  int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;
}

class _ShiftAccum {
  int count = 0;
  double totalHours = 0;
  double nightHours = 0;
  void add(double h, double n) {
    count++;
    totalHours += h;
    nightHours += n;
  }
}

class _ShiftTimes {
  final DateTime start;
  final DateTime end;
  const _ShiftTimes({required this.start, required this.end});
}

final salaryProvider =
    StateNotifierProvider<SalaryNotifier, SalaryState>((ref) {
  return SalaryNotifier(DatabaseService.instance);
});
