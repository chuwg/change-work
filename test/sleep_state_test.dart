import 'package:flutter_test/flutter_test.dart';

import 'package:change/models/sleep_record.dart';
import 'package:change/providers/sleep_provider.dart';

/// SleepState's aggregates used to average raw records. Once split sleep is
/// preserved that is wrong: a 90-minute nap is not a day.
void main() {
  SleepRecord record(DateTime bed, DateTime wake, {int quality = 3}) =>
      SleepRecord(
        id: '$bed',
        date: DateTime(wake.year, wake.month, wake.day),
        bedTime: bed,
        wakeTime: wake,
        quality: quality,
      );

  DateTime today(int hour, [int minute = 0]) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  test('today is the sum of every session, not just the longest', () {
    final state = SleepState(records: [
      record(today(8), today(14), quality: 4), // 6h
      record(today(19), today(20, 30), quality: 2), // 1.5h
    ]);

    expect(state.todaySleep, isNotNull);
    expect(state.todaySleep!.totalHours, 7.5);
    expect(state.todaySleep!.isSplit, isTrue);
    expect(state.todaySleep!.mainSession.quality, 4);
  });

  test('todaySleep is null when nothing is recorded today', () {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final state = SleepState(records: [
      record(
        DateTime(yesterday.year, yesterday.month, yesterday.day, 1),
        DateTime(yesterday.year, yesterday.month, yesterday.day, 8),
      ),
    ]);

    expect(state.todaySleep, isNull);
  });

  test('the average is per day, so a nap cannot halve it', () {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    DateTime y(int hour, [int minute = 0]) =>
        DateTime(yesterday.year, yesterday.month, yesterday.day, hour, minute);

    final state = SleepState(records: [
      record(y(0), y(8)), // 8h
      record(today(8), today(14)), // 6h
      record(today(19), today(20, 30)), // 1.5h
    ]);

    // Two days: 8h and 7.5h -> 7.75. Averaging the three records gives 5.17.
    expect(state.days, hasLength(2));
    expect(state.averageSleepHours, closeTo(7.75, 0.001));
    expect(state.averageSleepHours, isNot(closeTo(5.17, 0.01)));
  });

  test('quality averages per day and is duration weighted inside a day', () {
    final state = SleepState(records: [
      record(today(8), today(14), quality: 4), // 6h
      record(today(19), today(20, 30), quality: 2), // 1.5h
    ]);

    // (4*360 + 2*90) / 450 = 3.6 -> 4. A plain record mean would be 3.
    expect(state.averageQuality, 4);
  });

  test('an empty state reports zeroes rather than dividing by zero', () {
    const state = SleepState();

    expect(state.days, isEmpty);
    expect(state.averageSleepHours, 0);
    expect(state.averageQuality, 0);
    expect(state.todaySleep, isNull);
  });

  test('last7DaysByDay is one entry per day, oldest first', () {
    final now = DateTime.now();
    final records = <SleepRecord>[];
    for (int i = 0; i < 3; i++) {
      final d = now.subtract(Duration(days: i));
      records.add(record(
        DateTime(d.year, d.month, d.day, 1),
        DateTime(d.year, d.month, d.day, 8),
      ));
    }
    // A second session on today, which must not become a fourth "day".
    records.add(record(today(19), today(20)));

    final byDay = SleepState(records: records).last7DaysByDay;

    expect(byDay, hasLength(3));
    for (int i = 1; i < byDay.length; i++) {
      expect(byDay[i].date.isAfter(byDay[i - 1].date), isTrue,
          reason: 'oldest first');
    }
    expect(byDay.last.isSplit, isTrue, reason: 'today has two sessions');
  });
}
