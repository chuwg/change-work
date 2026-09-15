import 'package:flutter_test/flutter_test.dart';

import 'package:change/models/daily_sleep.dart';
import 'package:change/models/energy_record.dart';
import 'package:change/models/shift.dart';
import 'package:change/models/sleep_record.dart';
import 'package:change/services/pattern_insights.dart';
import 'package:change/utils/constants.dart';

void main() {
  DateTime d(int day) => DateTime(2026, 9, day);

  DailySleep sleep(int day, double hours, {int bedHour = 23}) {
    final bed = DateTime(2026, 9, day - 1, bedHour);
    return DailySleep(date: d(day), sessions: [
      SleepRecord(
        id: '$day',
        date: d(day),
        bedTime: bed,
        wakeTime: bed.add(Duration(minutes: (hours * 60).round())),
        quality: 3,
      ),
    ]);
  }

  Shift shiftOf(int day, String type) =>
      Shift(id: '$day', date: d(day), type: type);

  Shift? Function(DateTime) scheduleOf(Map<int, String> byDay) =>
      (date) => byDay.containsKey(date.day)
          ? shiftOf(date.day, byDay[date.day]!)
          : null;

  EnergyRecord energyOn(int day, int level) => EnergyRecord(
        id: '$day-$level',
        date: d(day),
        timestamp: DateTime(2026, 9, day, 14),
        energyLevel: level,
      );

  test('names the shift type the user sleeps worst on', () {
    final insights = PatternInsights.weekly(
      sleepDays: [
        sleep(10, 5.0), sleep(11, 5.2), // night days
        sleep(12, 7.4), sleep(13, 7.6), // day-shift days
      ],
      shiftFor: scheduleOf({
        10: AppConstants.shiftNight, 11: AppConstants.shiftNight,
        12: AppConstants.shiftDay, 13: AppConstants.shiftDay,
      }),
      energy: const [],
      sleepDebt: 0,
    );

    final gap = insights.firstWhere((i) => i.title.contains('야간'));
    expect(gap.body, contains('5.1시간'));
    expect(gap.body, contains('2.4시간 적게'));
    expect(gap.tone, InsightTone.warn);
  });

  test('stays quiet when the difference between shifts is noise', () {
    final insights = PatternInsights.weekly(
      sleepDays: [sleep(10, 7.0), sleep(12, 7.3)],
      shiftFor: scheduleOf(
          {10: AppConstants.shiftNight, 12: AppConstants.shiftDay}),
      energy: const [],
      sleepDebt: 0,
    );
    expect(insights.where((i) => i.title.contains('가장 짧아요')), isEmpty);
  });

  test('spots catching up on days off', () {
    final insights = PatternInsights.weekly(
      sleepDays: [
        sleep(10, 5.5), sleep(11, 5.5),
        sleep(12, 9.5), sleep(13, 9.5),
      ],
      shiftFor: scheduleOf({
        10: AppConstants.shiftNight, 11: AppConstants.shiftNight,
        12: AppConstants.shiftOff, 13: AppConstants.shiftOff,
      }),
      energy: const [],
      sleepDebt: 0,
    );

    final catchUp = insights.firstWhere((i) => i.title.contains('휴무일'));
    expect(catchUp.body, contains('9.5시간'));
    expect(catchUp.body, contains('4.0시간 차이'));
  });

  test('measures the energy dip the day after a night shift', () {
    final insights = PatternInsights.weekly(
      sleepDays: const [],
      shiftFor: scheduleOf({
        10: AppConstants.shiftNight, 12: AppConstants.shiftNight,
        14: AppConstants.shiftDay, 16: AppConstants.shiftDay,
      }),
      energy: [
        energyOn(11, 2), energyOn(13, 2), // days after a night shift
        energyOn(15, 4), energyOn(17, 4), // days after a day shift
      ],
      sleepDebt: 0,
    );

    final dip = insights.firstWhere((i) => i.title.contains('야간근무 다음'));
    expect(dip.body, contains('2.0점 낮아요'));
  });

  test('praises a steady bedtime and flags a wandering one', () {
    final steady = PatternInsights.weekly(
      sleepDays: [
        sleep(10, 7, bedHour: 23), sleep(11, 7, bedHour: 23),
        sleep(12, 7, bedHour: 0), sleep(13, 7, bedHour: 23),
      ],
      shiftFor: (_) => null,
      energy: const [],
      sleepDebt: 0,
    );
    expect(steady.any((i) => i.tone == InsightTone.good), isTrue);

    final wandering = PatternInsights.weekly(
      sleepDays: [
        sleep(10, 7, bedHour: 22), sleep(11, 7, bedHour: 3),
        sleep(12, 7, bedHour: 14), sleep(13, 7, bedHour: 23),
      ],
      shiftFor: (_) => null,
      energy: const [],
      sleepDebt: 0,
    );
    expect(wandering.any((i) => i.title.contains('흔들려요')), isTrue);
  });

  test('bedtimes either side of midnight count as close together', () {
    final byShift = PatternInsights.sleepByShiftType(
      [sleep(10, 7), sleep(11, 8)],
      scheduleOf({10: AppConstants.shiftDay, 11: AppConstants.shiftDay}),
    );
    expect(byShift[AppConstants.shiftDay], closeTo(7.5, 0.001));
  });

  test('an empty week produces nothing rather than a false pattern', () {
    final insights = PatternInsights.weekly(
      sleepDays: const [],
      shiftFor: (_) => null,
      energy: const [],
      sleepDebt: 0,
    );
    expect(insights, isEmpty);
  });
}
