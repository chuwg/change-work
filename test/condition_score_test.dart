import 'package:flutter_test/flutter_test.dart';

import 'package:change/models/daily_sleep.dart';
import 'package:change/models/sleep_record.dart';
import 'package:change/services/condition_score.dart';

void main() {
  DailySleep sleepOf({required double hours, int quality = 3}) {
    final bed = DateTime(2026, 9, 10, 0, 0);
    final wake = bed.add(Duration(minutes: (hours * 60).round()));
    return DailySleep(
      date: DateTime(2026, 9, 10),
      sessions: [
        SleepRecord(
          id: 's',
          date: DateTime(2026, 9, 10),
          bedTime: bed,
          wakeTime: wake,
          quality: quality,
        ),
      ],
    );
  }

  group('missing data', () {
    test('nothing recorded returns the neutral score, not zero', () {
      expect(ConditionScore.compute(), ConditionScore.unknown);
      expect(ConditionScore.unknown, 50);
    });

    test('unknown steps do not drag the score down', () {
      final withoutSteps = ConditionScore.compute(
        todaySleep: sleepOf(hours: 8, quality: 3),
        todayEnergy: 4,
      );
      final withZeroSteps = ConditionScore.compute(
        todaySleep: sleepOf(hours: 8, quality: 3),
        todayEnergy: 4,
        todaySteps: 0,
      );

      // 0 steps is treated as "no reading", same as null — a step permission
      // the user never granted must not look like a lazy day.
      expect(withoutSteps, withZeroSteps);
      expect(withoutSteps, greaterThan(70));
    });

    test('a single factor is still scored on a full 0-100 scale', () {
      // Sleep alone carries 40% weight; without normalising by the weights
      // that applied, a perfect night would cap out at 38.
      final sleepOnly = ConditionScore.compute(
        todaySleep: sleepOf(hours: 8, quality: 5),
      );
      expect(sleepOnly, 100);
    });

    test('falls back to the recent average before today is recorded', () {
      expect(ConditionScore.compute(averageSleepHours: 7.5), 75);
      expect(ConditionScore.compute(averageSleepHours: 5.0), 50);
      // No average either -> that factor simply does not apply.
      expect(ConditionScore.compute(averageSleepHours: 0), ConditionScore.unknown);
    });
  });

  group('sleep bands', () {
    test('7-9 hours is the top band', () {
      expect(ConditionScore.compute(todaySleep: sleepOf(hours: 7)), 90);
      expect(ConditionScore.compute(todaySleep: sleepOf(hours: 9)), 90);
    });

    test('over-sleeping drops out of the top band', () {
      expect(ConditionScore.compute(todaySleep: sleepOf(hours: 9.5)), 70);
    });

    test('quality shifts the band by five points per step', () {
      expect(ConditionScore.compute(todaySleep: sleepOf(hours: 8, quality: 3)), 90);
      expect(ConditionScore.compute(todaySleep: sleepOf(hours: 8, quality: 5)), 100);
      expect(ConditionScore.compute(todaySleep: sleepOf(hours: 8, quality: 1)), 80);
    });

    test('short sleep scores low', () {
      expect(ConditionScore.compute(todaySleep: sleepOf(hours: 4, quality: 3)), 30);
    });
  });

  group('split sleep', () {
    test('two sessions are scored on their total, not the longest', () {
      final bed = DateTime(2026, 9, 10, 8, 0);
      final split = DailySleep(
        date: DateTime(2026, 9, 10),
        sessions: [
          SleepRecord(
            id: 'main',
            date: DateTime(2026, 9, 10),
            bedTime: bed,
            wakeTime: bed.add(const Duration(hours: 6)),
            quality: 3,
          ),
          SleepRecord(
            id: 'nap',
            date: DateTime(2026, 9, 10),
            bedTime: DateTime(2026, 9, 10, 19, 0),
            wakeTime: DateTime(2026, 9, 10, 20, 30),
            quality: 3,
          ),
        ],
      );

      // 7.5h total lands in the top band; the 6h main session alone would not.
      expect(ConditionScore.compute(todaySleep: split), 90);
      expect(ConditionScore.compute(todaySleep: sleepOf(hours: 6)), 70);
    });
  });

  group('weighting', () {
    test('every factor present is a weighted mean', () {
      // sleep 90 (8h, q3), energy 80 (4/5), activity 90 (8000+ steps)
      final score = ConditionScore.compute(
        todaySleep: sleepOf(hours: 8, quality: 3),
        todayEnergy: 4,
        todaySteps: 9000,
      );
      final expected =
          (90 * 0.40 + 80 * 0.35 + 90 * 0.25) / (0.40 + 0.35 + 0.25);
      expect(score, expected.round());
    });

    test('step bands', () {
      int scoreFor(int steps) =>
          ConditionScore.compute(todaySteps: steps);
      expect(scoreFor(9000), 90);
      expect(scoreFor(6000), 70);
      expect(scoreFor(4000), 50);
      expect(scoreFor(1000), 30);
    });

    test('the result never leaves 0-100', () {
      final best = ConditionScore.compute(
        todaySleep: sleepOf(hours: 8, quality: 5),
        todayEnergy: 5,
        todaySteps: 20000,
      );
      final worst = ConditionScore.compute(
        todaySleep: sleepOf(hours: 1, quality: 1),
        todayEnergy: 1,
        todaySteps: 10,
      );
      expect(best, inInclusiveRange(0, 100));
      expect(worst, inInclusiveRange(0, 100));
      expect(best, greaterThan(worst));
    });
  });
}
