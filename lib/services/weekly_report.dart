import '../models/daily_sleep.dart';
import '../models/energy_record.dart';

/// The numbers behind the weekly report.
///
/// Everything here counts **days**, not records. Sleep is stored one row per
/// session and shift workers routinely sleep twice a day, so a per-record
/// figure silently treats a 90-minute nap as another whole day — which made
/// the sleep debt target 14 hours for a day the user actually slept 7.5.
class WeeklyStats {
  /// The week's sleep, one entry per day that has any.
  final List<DailySleep> sleepDays;

  /// Mean of each day's total sleep.
  final double avgSleepHours;

  /// Mean of each day's (duration-weighted) quality.
  final double avgSleepQuality;

  final double avgEnergy;

  /// Hours short of [targetHoursPerDay] across the days that have data.
  /// Never negative: sleeping extra does not bank credit against a bad night.
  final double sleepDebt;

  final DailySleep? bestSleepDay;
  final DailySleep? worstSleepDay;

  static const double targetHoursPerDay = 7.0;

  const WeeklyStats({
    required this.sleepDays,
    required this.avgSleepHours,
    required this.avgSleepQuality,
    required this.avgEnergy,
    required this.sleepDebt,
    required this.bestSleepDay,
    required this.worstSleepDay,
  });

  factory WeeklyStats.from({
    required List<DailySleep> sleepDays,
    required List<EnergyRecord> energy,
  }) {
    if (sleepDays.isEmpty) {
      return WeeklyStats(
        sleepDays: const [],
        avgSleepHours: 0,
        avgSleepQuality: 0,
        avgEnergy: _mean(energy.map((e) => e.energyLevel.toDouble())),
        sleepDebt: 0,
        bestSleepDay: null,
        worstSleepDay: null,
      );
    }

    final totals = sleepDays.map((d) => d.totalHours).toList();
    final slept = totals.fold<double>(0, (sum, h) => sum + h);
    final target = targetHoursPerDay * sleepDays.length;

    final ranked = [...sleepDays]
      ..sort((a, b) => b.totalHours.compareTo(a.totalHours));

    return WeeklyStats(
      sleepDays: sleepDays,
      avgSleepHours: slept / sleepDays.length,
      avgSleepQuality: _mean(sleepDays.map((d) => d.quality.toDouble())),
      avgEnergy: _mean(energy.map((e) => e.energyLevel.toDouble())),
      sleepDebt: (target - slept).clamp(0.0, double.infinity),
      bestSleepDay: ranked.first,
      worstSleepDay: ranked.last,
    );
  }

  /// Total sleep on [date], or 0 when that day has no record.
  double hoursOn(DateTime date) {
    for (final day in sleepDays) {
      if (day.date.year == date.year &&
          day.date.month == date.month &&
          day.date.day == date.day) {
        return day.totalHours;
      }
    }
    return 0;
  }

  String get grade {
    double score = 0;

    if (avgSleepHours >= 7) {
      score += 40;
    } else if (avgSleepHours >= 6) {
      score += 25;
    } else if (avgSleepHours > 0) {
      score += 10;
    }

    if (avgEnergy >= 3.5) {
      score += 35;
    } else if (avgEnergy >= 2.5) {
      score += 20;
    } else if (avgEnergy > 0) {
      score += 10;
    }

    if (sleepDebt <= 2) {
      score += 25;
    } else if (sleepDebt <= 5) {
      score += 15;
    } else {
      score += 5;
    }

    if (score >= 85) return 'A+';
    if (score >= 75) return 'A';
    if (score >= 60) return 'B+';
    if (score >= 45) return 'B';
    if (score >= 30) return 'C';
    return 'D';
  }

  static double _mean(Iterable<double> values) {
    final list = values.toList();
    if (list.isEmpty) return 0;
    return list.fold<double>(0, (sum, v) => sum + v) / list.length;
  }
}
