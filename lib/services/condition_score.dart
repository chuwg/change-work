import '../models/daily_sleep.dart';

/// The 0-100 figure at the top of the condition tab.
///
/// Pure on purpose: it used to be a private method inside the screen, which
/// made the headline number of the whole tab untestable.
///
/// Each factor only counts when there is data for it, and the result is
/// normalised by the weights that actually applied — so a day with sleep data
/// but no energy entry is still scored on a 0-100 scale rather than being
/// capped at 40.
class ConditionScore {
  const ConditionScore._();

  static const double sleepWeight = 0.40;
  static const double energyWeight = 0.35;
  static const double activityWeight = 0.25;

  /// Returned when nothing at all has been recorded — a neutral "no idea"
  /// rather than a zero the user would read as "terrible".
  static const int unknown = 50;

  static int compute({
    DailySleep? todaySleep,
    double averageSleepHours = 0,
    double todayEnergy = 0,
    int? todaySteps,
  }) {
    double score = 0;
    double totalWeight = 0;

    final sleepScore = _sleepScore(todaySleep, averageSleepHours);
    if (sleepScore != null) {
      score += sleepScore * sleepWeight;
      totalWeight += sleepWeight;
    }

    if (todayEnergy > 0) {
      score += (todayEnergy / 5) * 100 * energyWeight;
      totalWeight += energyWeight;
    }

    final activityScore = _activityScore(todaySteps);
    if (activityScore != null) {
      score += activityScore * activityWeight;
      totalWeight += activityWeight;
    }

    if (totalWeight == 0) return unknown;
    return (score / totalWeight).round().clamp(0, 100);
  }

  /// Today's total sleep if there is any, otherwise a coarse read on the
  /// recent average so the score isn't blank first thing in the morning.
  static double? _sleepScore(DailySleep? today, double averageHours) {
    if (today != null) {
      final hours = today.totalHours;
      double base;
      if (hours >= 7 && hours <= 9) {
        base = 90;
      } else if (hours >= 6) {
        base = 70;
      } else if (hours >= 5) {
        base = 50;
      } else {
        base = 30;
      }
      // Quality nudges the band by ±10 around the neutral rating of 3.
      return (base + (today.quality - 3) * 5).clamp(0, 100).toDouble();
    }
    if (averageHours > 0) return averageHours >= 7 ? 75.0 : 50.0;
    return null;
  }

  /// Null when steps are unknown — which is not the same as having walked
  /// none, and must not drag the score down.
  static double? _activityScore(int? steps) {
    if (steps == null || steps <= 0) return null;
    if (steps >= 8000) return 90;
    if (steps >= 5000) return 70;
    if (steps >= 3000) return 50;
    return 30;
  }
}
