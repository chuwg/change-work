import 'dart:math' as math;

import '../models/daily_sleep.dart';
import '../models/energy_record.dart';
import '../models/shift.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

enum InsightTone { good, caution, warn }

/// One finding about how the user's shifts and their body line up.
class PatternInsight {
  final String title;
  final String body;
  final InsightTone tone;

  const PatternInsight({
    required this.title,
    required this.body,
    required this.tone,
  });
}

/// Compares the week's sleep and energy *against the shifts that produced it*.
///
/// The old insights were threshold checks on a weekly average — "평균 6.2시간"
/// tells a shift worker nothing they cannot read off the number itself. What
/// they cannot see is that the average hides a 1.4-hour gap between their
/// night-shift days and their day-shift days.
class PatternInsights {
  const PatternInsights._();

  /// A gap smaller than this is noise, not a pattern.
  static const double _meaningfulHours = 0.7;
  static const double _meaningfulEnergy = 0.5;

  static List<PatternInsight> weekly({
    required List<DailySleep> sleepDays,
    required Shift? Function(DateTime date) shiftFor,
    required List<EnergyRecord> energy,
    required double sleepDebt,
  }) {
    final insights = <PatternInsight>[];

    final byShift = sleepByShiftType(sleepDays, shiftFor);
    final shiftGap = _shiftGapInsight(byShift);
    if (shiftGap != null) insights.add(shiftGap);

    final catchUp = _catchUpInsight(byShift);
    if (catchUp != null) insights.add(catchUp);

    final afterNight = _energyAfterNightInsight(energy, shiftFor);
    if (afterNight != null) insights.add(afterNight);

    final consistency = _bedtimeConsistencyInsight(sleepDays);
    if (consistency != null) insights.add(consistency);

    if (sleepDebt > 5) {
      insights.add(PatternInsight(
        title: '수면 부채 ${sleepDebt.toStringAsFixed(1)}시간',
        body: '휴무일 하루로는 다 갚기 어려운 양이에요. '
            '이번 주는 근무 전 짧은 낮잠을 더해보세요.',
        tone: InsightTone.warn,
      ));
    }

    return insights;
  }

  /// Average hours slept on the days the user worked each shift type.
  static Map<String, double> sleepByShiftType(
    List<DailySleep> sleepDays,
    Shift? Function(DateTime date) shiftFor,
  ) {
    final totals = <String, List<double>>{};
    for (final day in sleepDays) {
      final shift = shiftFor(day.date);
      final type = shift?.type ?? AppConstants.shiftOff;
      totals.putIfAbsent(type, () => []).add(day.totalHours);
    }
    return totals.map((type, hours) => MapEntry(
        type, hours.reduce((a, b) => a + b) / hours.length));
  }

  /// The widest gap between two *working* shift types.
  static PatternInsight? _shiftGapInsight(Map<String, double> byShift) {
    final working = Map.of(byShift)..remove(AppConstants.shiftOff);
    if (working.length < 2) return null;

    final sorted = working.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final worst = sorted.first;
    final best = sorted.last;
    final gap = best.value - worst.value;
    if (gap < _meaningfulHours) return null;

    return PatternInsight(
      title: '${AppHelpers.getShiftLabel(worst.key)} 근무일 수면이 가장 짧아요',
      body: '${AppHelpers.getShiftLabel(worst.key)} 근무한 날 평균 '
          '${worst.value.toStringAsFixed(1)}시간으로, '
          '${AppHelpers.getShiftLabel(best.key)} 근무일보다 '
          '${gap.toStringAsFixed(1)}시간 적게 주무셨어요.',
      tone: gap >= 1.5 ? InsightTone.warn : InsightTone.caution,
    );
  }

  /// Sleeping far longer on days off is the classic shift-work catch-up
  /// pattern — worth naming, because it keeps the body clock moving.
  static PatternInsight? _catchUpInsight(Map<String, double> byShift) {
    final off = byShift[AppConstants.shiftOff];
    if (off == null) return null;

    final working = Map.of(byShift)..remove(AppConstants.shiftOff);
    if (working.isEmpty) return null;
    final workAvg =
        working.values.reduce((a, b) => a + b) / working.length;

    final gap = off - workAvg;
    if (gap < 1.5) return null;

    return PatternInsight(
      title: '휴무일에 몰아서 주무세요',
      body: '휴무일 평균 ${off.toStringAsFixed(1)}시간, 근무일 평균 '
          '${workAvg.toStringAsFixed(1)}시간이에요. '
          '${gap.toStringAsFixed(1)}시간 차이는 몸이 시차를 다시 겪는 것과 비슷해요.',
      tone: InsightTone.caution,
    );
  }

  /// Energy recorded the day *after* a night shift, against every other day.
  static PatternInsight? _energyAfterNightInsight(
    List<EnergyRecord> energy,
    Shift? Function(DateTime date) shiftFor,
  ) {
    final afterNight = <int>[];
    final otherDays = <int>[];

    for (final record in energy) {
      final day = DateTime(
          record.timestamp.year, record.timestamp.month, record.timestamp.day);
      final yesterday = day.subtract(const Duration(days: 1));
      final wasNight = shiftFor(yesterday)?.type == AppConstants.shiftNight;
      (wasNight ? afterNight : otherDays).add(record.energyLevel);
    }

    if (afterNight.length < 2 || otherDays.length < 2) return null;

    double mean(List<int> xs) =>
        xs.reduce((a, b) => a + b) / xs.length;
    final drop = mean(otherDays) - mean(afterNight);
    if (drop < _meaningfulEnergy) return null;

    return PatternInsight(
      title: '야간근무 다음 날이 힘드세요',
      body: '야간근무 다음 날 에너지가 평균 ${drop.toStringAsFixed(1)}점 낮아요. '
          '그날은 무리한 일정을 피하고 회복에 쓰는 편이 좋아요.',
      tone: InsightTone.caution,
    );
  }

  /// How much the user's bedtime moves around, in hours.
  static PatternInsight? _bedtimeConsistencyInsight(
      List<DailySleep> sleepDays) {
    if (sleepDays.length < 3) return null;

    // Measure against noon so that a 23:00 and a 01:00 bedtime read as two
    // hours apart rather than twenty-two.
    final offsets = sleepDays.map((d) {
      final bed = d.mainSession.bedTime;
      final minutes = bed.hour * 60 + bed.minute;
      return (minutes > 12 * 60 ? minutes - 24 * 60 : minutes) / 60.0;
    }).toList();

    final mean = offsets.reduce((a, b) => a + b) / offsets.length;
    final variance = offsets
            .map((o) => (o - mean) * (o - mean))
            .reduce((a, b) => a + b) /
        offsets.length;
    final spread = variance <= 0 ? 0.0 : math.sqrt(variance);

    if (spread < 2.0) {
      return PatternInsight(
        title: '취침 시간이 일정해요',
        body: '교대 근무 중에도 잠드는 시간이 ±${spread.toStringAsFixed(1)}시간 안으로 '
            '유지되고 있어요. 지금 리듬을 지키세요.',
        tone: InsightTone.good,
      );
    }
    if (spread >= 3.5) {
      return PatternInsight(
        title: '취침 시간이 많이 흔들려요',
        body: '잠드는 시간이 ±${spread.toStringAsFixed(1)}시간까지 벌어져요. '
            '근무가 바뀌어도 기상 시간만은 비슷하게 맞추면 회복이 빨라집니다.',
        tone: InsightTone.warn,
      );
    }
    return null;
  }
}
