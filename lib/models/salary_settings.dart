import 'dart:convert';
import '../utils/constants.dart';

class FixedAllowance {
  final String name;
  final double amount;
  final bool perShift;

  const FixedAllowance({
    required this.name,
    required this.amount,
    this.perShift = false,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'amount': amount,
        'per_shift': perShift,
      };

  factory FixedAllowance.fromMap(Map<String, dynamic> m) => FixedAllowance(
        name: m['name'] as String,
        amount: (m['amount'] as num).toDouble(),
        perShift: m['per_shift'] as bool? ?? false,
      );

  FixedAllowance copyWith({
    String? name,
    double? amount,
    bool? perShift,
  }) {
    return FixedAllowance(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      perShift: perShift ?? this.perShift,
    );
  }
}

/// 야간 수당 방식: 'multiplier' = 배수 방식, 'fixed' = 야간 근무당 고정 금액
const String nightAllowanceMultiplier = 'multiplier';
const String nightAllowanceFixed = 'fixed';

class SalarySettings {
  final String payType;
  final double hourlyRate;
  final double monthlySalary;
  final String nightAllowanceType; // 'multiplier' or 'fixed'
  final double nightMultiplier;
  final double nightFixedAmount;   // 야간 근무 1회당 고정 금액 (fixed 방식)
  final double weekendMultiplier;
  final double overtimeMultiplier;
  final List<FixedAllowance> fixedAllowances;

  const SalarySettings({
    this.payType = AppConstants.payTypeHourly,
    this.hourlyRate = 9860.0,
    this.monthlySalary = 2500000.0,
    this.nightAllowanceType = nightAllowanceMultiplier,
    this.nightMultiplier = AppConstants.defaultNightMultiplier,
    this.nightFixedAmount = 0.0,
    this.weekendMultiplier = AppConstants.defaultWeekendMultiplier,
    this.overtimeMultiplier = AppConstants.defaultOvertimeMultiplier,
    this.fixedAllowances = const [],
  });

  SalarySettings copyWith({
    String? payType,
    double? hourlyRate,
    double? monthlySalary,
    String? nightAllowanceType,
    double? nightMultiplier,
    double? nightFixedAmount,
    double? weekendMultiplier,
    double? overtimeMultiplier,
    List<FixedAllowance>? fixedAllowances,
  }) {
    return SalarySettings(
      payType: payType ?? this.payType,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      nightAllowanceType: nightAllowanceType ?? this.nightAllowanceType,
      nightMultiplier: nightMultiplier ?? this.nightMultiplier,
      nightFixedAmount: nightFixedAmount ?? this.nightFixedAmount,
      weekendMultiplier: weekendMultiplier ?? this.weekendMultiplier,
      overtimeMultiplier: overtimeMultiplier ?? this.overtimeMultiplier,
      fixedAllowances: fixedAllowances ?? this.fixedAllowances,
    );
  }

  Map<String, dynamic> toMap() => {
        'pay_type': payType,
        'hourly_rate': hourlyRate,
        'monthly_salary': monthlySalary,
        'night_allowance_type': nightAllowanceType,
        'night_multiplier': nightMultiplier,
        'night_fixed_amount': nightFixedAmount,
        'weekend_multiplier': weekendMultiplier,
        'overtime_multiplier': overtimeMultiplier,
        'fixed_allowances': fixedAllowances.map((a) => a.toMap()).toList(),
      };

  factory SalarySettings.fromMap(Map<String, dynamic> m) => SalarySettings(
        payType: m['pay_type'] as String? ?? AppConstants.payTypeHourly,
        hourlyRate: (m['hourly_rate'] as num?)?.toDouble() ?? 9860.0,
        monthlySalary: (m['monthly_salary'] as num?)?.toDouble() ?? 2500000.0,
        nightAllowanceType:
            m['night_allowance_type'] as String? ?? nightAllowanceMultiplier,
        nightMultiplier: (m['night_multiplier'] as num?)?.toDouble() ??
            AppConstants.defaultNightMultiplier,
        nightFixedAmount:
            (m['night_fixed_amount'] as num?)?.toDouble() ?? 0.0,
        weekendMultiplier: (m['weekend_multiplier'] as num?)?.toDouble() ??
            AppConstants.defaultWeekendMultiplier,
        overtimeMultiplier: (m['overtime_multiplier'] as num?)?.toDouble() ??
            AppConstants.defaultOvertimeMultiplier,
        fixedAllowances: ((m['fixed_allowances'] as List<dynamic>?) ?? [])
            .map((e) => FixedAllowance.fromMap(e as Map<String, dynamic>))
            .toList(),
      );

  String toJson() => jsonEncode(toMap());

  factory SalarySettings.fromJson(String json) =>
      SalarySettings.fromMap(jsonDecode(json) as Map<String, dynamic>);
}
