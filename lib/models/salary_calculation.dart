import 'salary_settings.dart';

class ShiftSalaryBreakdown {
  final String shiftType;
  final int count;
  final double totalHours;
  final double regularHours;
  final double nightHours;
  final double basePay;
  final double nightPremium;
  final double total;

  const ShiftSalaryBreakdown({
    required this.shiftType,
    required this.count,
    required this.totalHours,
    required this.regularHours,
    required this.nightHours,
    required this.basePay,
    required this.nightPremium,
    required this.total,
  });
}

class SalaryCalculation {
  final int year;
  final int month;
  final SalarySettings settings;
  final double basePay;
  final double nightPremium;
  final double weekendPremium;
  final double overtimePay;
  final double fixedAllowancesTotal;
  final double totalGross;
  final List<ShiftSalaryBreakdown> shiftBreakdowns;
  final double totalWorkHours;
  final double totalNightHours;
  final double overtimeHours;
  final int workingDays;
  final int weekendDays;
  final int nightShifts;

  const SalaryCalculation({
    required this.year,
    required this.month,
    required this.settings,
    required this.basePay,
    required this.nightPremium,
    required this.weekendPremium,
    required this.overtimePay,
    required this.fixedAllowancesTotal,
    required this.totalGross,
    required this.shiftBreakdowns,
    required this.totalWorkHours,
    required this.totalNightHours,
    required this.overtimeHours,
    required this.workingDays,
    required this.weekendDays,
    required this.nightShifts,
  });

  double get totalAllowances =>
      nightPremium + weekendPremium + overtimePay + fixedAllowancesTotal;
}
