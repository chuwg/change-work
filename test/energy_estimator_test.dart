import 'package:flutter_test/flutter_test.dart';

import 'package:change/models/daily_sleep.dart';
import 'package:change/models/sleep_record.dart';
import 'package:change/services/energy_estimator.dart';
import 'package:change/utils/constants.dart';

void main() {
  DailySleep sleepOf({required double hours, int quality = 3, bool split = false}) {
    final bed = DateTime(2026, 9, 15, 0, 0);
    final total = Duration(minutes: (hours * 60).round());
    final sessions = <SleepRecord>[];
    if (split) {
      final first = Duration(minutes: (total.inMinutes * 0.8).round());
      sessions.add(SleepRecord(
          id: 'a', date: DateTime(2026, 9, 15), bedTime: bed,
          wakeTime: bed.add(first), quality: quality));
      sessions.add(SleepRecord(
          id: 'b', date: DateTime(2026, 9, 15),
          bedTime: DateTime(2026, 9, 15, 19),
          wakeTime: DateTime(2026, 9, 15, 19).add(total - first),
          quality: quality));
    } else {
      sessions.add(SleepRecord(
          id: 'a', date: DateTime(2026, 9, 15), bedTime: bed,
          wakeTime: bed.add(total), quality: quality));
    }
    return DailySleep(date: DateTime(2026, 9, 15), sessions: sessions);
  }

  final midMorning = DateTime(2026, 9, 15, 10, 0);

  test('good sleep and no debt reads high', () {
    final e = EnergyEstimator.estimate(
      now: midMorning,
      todaySleep: sleepOf(hours: 8, quality: 4),
      shiftType: AppConstants.shiftDay,
    );
    expect(e.level, greaterThanOrEqualTo(4));
    expect(e.reason, contains('푹'));
  });

  test('short sleep drags it down and says so', () {
    final e = EnergyEstimator.estimate(
      now: midMorning,
      todaySleep: sleepOf(hours: 4, quality: 2),
      shiftType: AppConstants.shiftDay,
    );
    expect(e.level, lessThanOrEqualTo(2));
    expect(e.reason, contains('4.0시간'));
  });

  test('split sleep is judged on the total, and the reason says it was split',
      () {
    final split = EnergyEstimator.estimate(
      now: midMorning,
      todaySleep: sleepOf(hours: 4.5, quality: 2, split: true),
      shiftType: AppConstants.shiftNight,
    );
    expect(split.reason, contains('나눠서'));

    // 7.5h split must not score below 7.5h in one block.
    final splitGood = EnergyEstimator.estimate(
      now: midMorning,
      todaySleep: sleepOf(hours: 7.5, quality: 3, split: true),
      shiftType: AppConstants.shiftDay,
    );
    final whole = EnergyEstimator.estimate(
      now: midMorning,
      todaySleep: sleepOf(hours: 7.5, quality: 3),
      shiftType: AppConstants.shiftDay,
    );
    expect(splitGood.level, whole.level);
  });

  test('the night-shift small hours are the low point', () {
    final smallHours = EnergyEstimator.estimate(
      now: DateTime(2026, 9, 15, 4, 30),
      todaySleep: sleepOf(hours: 7, quality: 4),
      shiftType: AppConstants.shiftNight,
    );
    final afternoon = EnergyEstimator.estimate(
      now: DateTime(2026, 9, 15, 15, 0),
      todaySleep: sleepOf(hours: 7, quality: 4),
      shiftType: AppConstants.shiftNight,
    );

    expect(smallHours.level, lessThan(afternoon.level));
    expect(smallHours.reason, contains('야간근무'));
  });

  test('an elevated heart rate overrides a good night', () {
    final calm = EnergyEstimator.estimate(
      now: midMorning,
      todaySleep: sleepOf(hours: 8, quality: 4),
      heartRate: 62,
      shiftType: AppConstants.shiftDay,
    );
    final strained = EnergyEstimator.estimate(
      now: midMorning,
      todaySleep: sleepOf(hours: 8, quality: 4),
      heartRate: 118,
      shiftType: AppConstants.shiftDay,
    );

    expect(strained.level, lessThanOrEqualTo(calm.level));
    expect(strained.reason, contains('심박수'));
  });

  test('sleep debt pulls the estimate down', () {
    final rested = EnergyEstimator.estimate(
      now: midMorning,
      todaySleep: sleepOf(hours: 7, quality: 3),
      shiftType: AppConstants.shiftDay,
    );
    final indebted = EnergyEstimator.estimate(
      now: midMorning,
      todaySleep: sleepOf(hours: 7, quality: 3),
      sleepDebtHours: 9,
      shiftType: AppConstants.shiftDay,
    );
    expect(indebted.level, lessThanOrEqualTo(rested.level));
  });

  test('no data at all still returns a usable middling estimate', () {
    final e = EnergyEstimator.estimate(now: midMorning);
    expect(e.level, inInclusiveRange(1, 5));
    expect(e.reason, isNotEmpty);
    expect(e.isRecorded, isFalse);
  });

  test('the level never leaves 1-5', () {
    final worst = EnergyEstimator.estimate(
      now: DateTime(2026, 9, 15, 4, 0),
      todaySleep: sleepOf(hours: 2, quality: 1),
      sleepDebtHours: 20,
      todaySteps: 0,
      heartRate: 130,
      shiftType: AppConstants.shiftNight,
    );
    final best = EnergyEstimator.estimate(
      now: DateTime(2026, 9, 15, 9, 0),
      todaySleep: sleepOf(hours: 9, quality: 5),
      todaySteps: 12000,
      heartRate: 58,
      shiftType: AppConstants.shiftDay,
    );
    expect(worst.level, 1);
    expect(best.level, 5);
  });
}
