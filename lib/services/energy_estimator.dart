import '../models/daily_sleep.dart';
import '../utils/constants.dart';

/// An estimated energy level, with the reason it came out that way.
class EnergyEstimate {
  /// 1 (탈진) – 5 (최고).
  final int level;

  /// The single biggest driver, phrased for the user.
  final String reason;

  /// True when the user recorded this themselves rather than it being derived.
  final bool isRecorded;

  const EnergyEstimate({
    required this.level,
    required this.reason,
    this.isRecorded = false,
  });
}

/// Works out roughly how much energy the user has right now.
///
/// Asking a shift worker to tap a number is asking them to do the analysis the
/// app should be doing. Everything this needs — sleep, steps, heart rate, the
/// shift they are on and where they are in it — is already collected.
///
/// Pure so it can be tested: no provider or clock access.
class EnergyEstimator {
  const EnergyEstimator._();

  /// Sleep carries the most weight; the rest nudge it.
  static const double _sleepWeight = 0.55;
  static const double _circadianWeight = 0.25;
  static const double _debtWeight = 0.12;
  static const double _activityWeight = 0.08;

  static EnergyEstimate estimate({
    required DateTime now,
    DailySleep? todaySleep,
    double recentAverageSleepHours = 0,
    double sleepDebtHours = 0,
    int? todaySteps,
    double? heartRate,
    String? shiftType,
  }) {
    final sleepScore = _sleepScore(todaySleep, recentAverageSleepHours);
    final circadianScore = _circadianScore(now, shiftType);
    final debtScore = _debtScore(sleepDebtHours);
    final activityScore = _activityScore(todaySteps, now);

    // Weighted mean on a 1-5 scale.
    var score = sleepScore * _sleepWeight +
        circadianScore * _circadianWeight +
        debtScore * _debtWeight +
        activityScore * _activityWeight;

    // A clearly elevated heart rate is a strong fatigue/strain signal and
    // overrides a rosy sleep number.
    var strainedHeart = false;
    if (heartRate != null && heartRate > 100) {
      score -= 0.6;
      strainedHeart = true;
    }

    final level = score.round().clamp(1, 5);

    return EnergyEstimate(
      level: level,
      reason: _reason(
        todaySleep: todaySleep,
        sleepScore: sleepScore,
        circadianScore: circadianScore,
        debtHours: sleepDebtHours,
        strainedHeart: strainedHeart,
        steps: todaySteps,
        now: now,
        shiftType: shiftType,
      ),
    );
  }

  /// 1-5 from how much and how well the user slept.
  static double _sleepScore(DailySleep? today, double recentAverage) {
    final hours = today?.totalHours ?? recentAverage;
    if (hours <= 0) return 3; // Nothing known — assume average rather than bad.

    final byHours = hours >= 7.5
        ? 5.0
        : hours >= 6.5
            ? 4.0
            : hours >= 5.5
                ? 3.0
                : hours >= 4.5
                    ? 2.0
                    : 1.0;
    if (today == null) return byHours;
    // Quality shifts by up to a full point around the neutral rating of 3.
    return (byHours + (today.quality - 3) * 0.5).clamp(1, 5);
  }

  /// Where the user is in their own day, not the calendar's.
  ///
  /// A night worker at 04:00 is at the bottom of their circadian dip even on a
  /// full night's sleep; a day worker at 04:00 should be asleep entirely.
  static double _circadianScore(DateTime now, String? shiftType) {
    final hour = now.hour;
    switch (shiftType) {
      case AppConstants.shiftNight:
        // Works 22:00-06:00: the 03:00-06:00 stretch is the hardest part.
        if (hour >= 3 && hour < 7) return 1.0;
        if (hour >= 22 || hour < 3) return 3.0;
        if (hour >= 12 && hour < 18) return 4.5; // post-sleep afternoon
        return 3.0;
      case AppConstants.shiftEvening:
        if (hour >= 20) return 2.5;
        if (hour >= 14 && hour < 20) return 4.0;
        return 3.5;
      case AppConstants.shiftDay:
        if (hour >= 13 && hour < 16) return 3.0; // the usual afternoon dip
        if (hour >= 6 && hour < 13) return 4.5;
        if (hour >= 21) return 2.5;
        return 3.0;
      default:
        if (hour >= 0 && hour < 6) return 2.0;
        if (hour >= 13 && hour < 16) return 3.5;
        if (hour >= 22) return 2.5;
        return 4.0;
    }
  }

  static double _debtScore(double debtHours) {
    if (debtHours <= 0) return 4;
    if (debtHours <= 2) return 4;
    if (debtHours <= 5) return 3;
    if (debtHours <= 8) return 2;
    return 1;
  }

  /// Movement is a mild signal, and only meaningful once the day is underway.
  static double _activityScore(int? steps, DateTime now) {
    if (steps == null) return 3;
    if (now.hour < 11) return 3; // Too early to read anything into it.
    if (steps >= 8000) return 4.5;
    if (steps >= 4000) return 3.5;
    if (steps >= 1500) return 3.0;
    return 2.0;
  }

  /// Pick the one thing most worth telling the user.
  static String _reason({
    required DailySleep? todaySleep,
    required double sleepScore,
    required double circadianScore,
    required double debtHours,
    required bool strainedHeart,
    required int? steps,
    required DateTime now,
    required String? shiftType,
  }) {
    if (strainedHeart) return '심박수가 평소보다 높아요';

    if (todaySleep != null && sleepScore <= 2.5) {
      final hours = todaySleep.totalHours.toStringAsFixed(1);
      return todaySleep.isSplit
          ? '나눠서 $hours시간 주무셨어요'
          : '$hours시간밖에 못 주무셨어요';
    }

    if (circadianScore <= 1.5) {
      if (shiftType == AppConstants.shiftNight) {
        return '야간근무 중 체력이 가장 떨어지는 시간대예요';
      }
      return '몸이 쉬어야 할 시간대예요';
    }

    if (debtHours > 5) {
      return '이번 주 수면 부채가 ${debtHours.toStringAsFixed(1)}시간이에요';
    }

    if (steps != null && steps < 1500 && now.hour >= 15) {
      return '오늘 거의 움직이지 않으셨어요';
    }

    if (todaySleep != null && sleepScore >= 4.5) {
      return '${todaySleep.totalHours.toStringAsFixed(1)}시간 푹 주무셨어요';
    }

    if (steps != null && steps >= 8000) return '활동량이 충분해요';

    return '수면과 활동 기록을 종합했어요';
  }
}
