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

class SalarySettings {
  final String payType;
  final double hourlyRate;
  final double monthlySalary;
  final double nightMultiplier;
  final double weekendMultiplier;
  final double overtimeMultiplier;
  final List<FixedAllowance> fixedAllowances;

  const SalarySettings({
    this.payType = AppConstants.payTypeHourly,
    this.hourlyRate = 9860.0,
    this.monthlySalary = 2500000.0,
    this.nightMultiplier = AppConstants.defaultNightMultiplier,
    this.weekendMultiplier = AppConstants.defaultWeekendMultiplier,
    this.overtimeMultiplier = AppConstants.defaultOvertimeMultiplier,
    this.fixedAllowances = const [],
  });

  SalarySettings copyWith({
    String? payType,
    double? hourlyRate,
    double? monthlySalary,
    double? nightMultiplier,
    double? weekendMultiplier,
    double? overtimeMultiplier,
    List<FixedAllowance>? fixedAllowances,
  }) {
    return SalarySettings(
      payType: payType ?? this.payType,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      nightMultiplier: nightMultiplier ?? this.nightMultiplier,
      weekendMultiplier: weekendMultiplier ?? this.weekendMultiplier,
      overtimeMultiplier: overtimeMultiplier ?? this.overtimeMultiplier,
      fixedAllowances: fixedAllowances ?? this.fixedAllowances,
    );
  }

  Map<String, dynamic> toMap() => {
        'pay_type': payType,
        'hourly_rate': hourlyRate,
        'monthly_salary': monthlySalary,
        'night_multiplier': nightMultiplier,
        'weekend_multiplier': weekendMultiplier,
        'overtime_multiplier': overtimeMultiplier,
        'fixed_allowances':
            fixedAllowances.map((a) => a.toMap()).toList(),
      };

  factory SalarySettings.fromMap(Map<String, dynamic> m) => SalarySettings(
        payType: m['pay_type'] as String? ?? AppConstants.payTypeHourly,
        hourlyRate: (m['hourly_rate'] as num?)?.toDouble() ?? 9860.0,
        monthlySalary:
            (m['monthly_salary'] as num?)?.toDouble() ?? 2500000.0,
        nightMultiplier:
            (m['night_multiplier'] as num?)?.toDouble() ??
                AppConstants.defaultNightMultiplier,
        weekendMultiplier:
            (m['weekend_multiplier'] as num?)?.toDouble() ??
                AppConstants.defaultWeekendMultiplier,
        overtimeMultiplier:
            (m['overtime_multiplier'] as num?)?.toDouble() ??
                AppConstants.defaultOvertimeMultiplier,
        fixedAllowances:
            ((m['fixed_allowances'] as List<dynamic>?) ?? [])
                .map((e) =>
                    FixedAllowance.fromMap(e as Map<String, dynamic>))
                .toList(),
      );

  String toJson() => jsonEncode(toMap());

  factory SalarySettings.fromJson(String json) =>
      SalarySettings.fromMap(jsonDecode(json) as Map<String, dynamic>);
}
