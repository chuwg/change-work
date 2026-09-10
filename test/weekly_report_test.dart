import 'package:flutter_test/flutter_test.dart';

import 'package:change/models/daily_sleep.dart';
import 'package:change/models/energy_record.dart';
import 'package:change/models/sleep_record.dart';
import 'package:change/services/weekly_report.dart';

void main() {
  SleepRecord session(DateTime bed, DateTime wake, {int quality = 3}) =>
      SleepRecord(
        id: '$bed',
        date: DateTime(wake.year, wake.month, wake.day),
        bedTime: bed,
        wakeTime: wake,
        quality: quality,
      );

  DailySleep day(int dayOfMonth, List<SleepRecord> sessions) =>
      DailySleep(date: DateTime(2026, 9, dayOfMonth), sessions: sessions);

  DailySleep simpleDay(int dayOfMonth, double hours, {int quality = 3}) {
    final bed = DateTime(2026, 9, dayOfMonth, 0, 0);
    return day(dayOfMonth, [
      session(bed, bed.add(Duration(minutes: (hours * 60).round())),
          quality: quality),
    ]);
  }

  List<EnergyRecord> energyOf(List<int> levels) => [
        for (int i = 0; i < levels.length; i++)
          EnergyRecord(
            id: '$i',
            date: DateTime(2026, 9, 10),
            timestamp: DateTime(2026, 9, 10, 9 + i),
            energyLevel: levels[i],
          ),
      ];

  group('sleep debt', () {
    test('a split-sleep day counts once, not twice', () {
      // 6h after the night shift + 1.5h nap before the next = 7.5h in one day.
      final splitDay = day(10, [
        session(DateTime(2026, 9, 10, 8), DateTime(2026, 9, 10, 14)),
        session(DateTime(2026, 9, 10, 19), DateTime(2026, 9, 10, 20, 30)),
      ]);

      final stats = WeeklyStats.from(sleepDays: [splitDay], energy: []);

      // Target is 7h for the one day. The old per-record maths took the
      // record count instead, making the target 14h and reporting a 6.5h debt
      // to someone who had slept more than enough.
      expect(stats.sleepDebt, 0);
      expect(stats.avgSleepHours, 7.5);
    });

    test('a genuinely short week still reports a debt', () {
      final stats = WeeklyStats.from(
        sleepDays: [simpleDay(8, 5), simpleDay(9, 5.5), simpleDay(10, 6)],
        energy: [],
      );

      // 21h target, 16.5h slept.
      expect(stats.sleepDebt, closeTo(4.5, 0.001));
    });

    test('sleeping extra does not bank negative debt', () {
      final stats = WeeklyStats.from(
        sleepDays: [simpleDay(9, 10), simpleDay(10, 10)],
        energy: [],
      );

      expect(stats.sleepDebt, 0);
      expect(stats.sleepDebt, isNot(lessThan(0)));
    });

    test('no sleep data means no debt rather than a full week of it', () {
      final stats = WeeklyStats.from(sleepDays: [], energy: energyOf([3, 4]));

      expect(stats.sleepDebt, 0);
      expect(stats.avgSleepHours, 0);
      expect(stats.avgEnergy, 3.5);
    });
  });

  group('best and worst day', () {
    test('ranked by the day total, so a nap is not the worst night', () {
      final splitDay = day(10, [
        session(DateTime(2026, 9, 10, 8), DateTime(2026, 9, 10, 14)),
        session(DateTime(2026, 9, 10, 19), DateTime(2026, 9, 10, 20, 30)),
      ]); // 7.5h
      final shortDay = simpleDay(9, 5); // 5h

      final stats =
          WeeklyStats.from(sleepDays: [splitDay, shortDay], energy: []);

      expect(stats.bestSleepDay!.date, DateTime(2026, 9, 10));
      expect(stats.worstSleepDay!.date, DateTime(2026, 9, 9));
      expect(stats.worstSleepDay!.totalHours, 5);
    });
  });

  group('hoursOn', () {
    test('returns the day total and zero for days with no record', () {
      final stats = WeeklyStats.from(sleepDays: [simpleDay(10, 7.5)], energy: []);

      expect(stats.hoursOn(DateTime(2026, 9, 10, 13, 45)), 7.5);
      expect(stats.hoursOn(DateTime(2026, 9, 11)), 0);
    });
  });

  group('grade', () {
    test('a good week grades A+', () {
      final stats = WeeklyStats.from(
        sleepDays: [simpleDay(9, 8), simpleDay(10, 7.5)],
        energy: energyOf([4, 4, 5]),
      );
      expect(stats.grade, 'A+');
    });

    test('short sleep and low energy grade poorly', () {
      final stats = WeeklyStats.from(
        sleepDays: [simpleDay(9, 4), simpleDay(10, 4.5)],
        energy: energyOf([2, 1]),
      );
      expect(stats.grade, anyOf('C', 'D'));
    });

    test('the split-sleep fix moves the grade, not just the number', () {
      final splitDay = day(10, [
        session(DateTime(2026, 9, 10, 8), DateTime(2026, 9, 10, 14)),
        session(DateTime(2026, 9, 10, 19), DateTime(2026, 9, 10, 20, 30)),
      ]);
      final stats =
          WeeklyStats.from(sleepDays: [splitDay], energy: energyOf([4]));

      // 7.5h average, no debt, decent energy.
      expect(stats.grade, 'A+');
    });
  });
}
