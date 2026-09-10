import 'package:flutter_test/flutter_test.dart';

import 'package:change/models/daily_sleep.dart';
import 'package:change/models/sleep_record.dart';

/// Shift workers routinely sleep twice in one day. Every "how much sleep"
/// figure has to be the day's total — averaging raw records counted a
/// 90-minute nap as if it were a whole day.
void main() {
  SleepRecord session(
    DateTime bed,
    DateTime wake, {
    int quality = 3,
    String? shiftType,
    String source = 'healthkit',
  }) =>
      SleepRecord(
        id: '$bed-$wake',
        date: DateTime(wake.year, wake.month, wake.day),
        bedTime: bed,
        wakeTime: wake,
        quality: quality,
        shiftType: shiftType,
        source: source,
      );

  /// The night-shift pattern: sleep after the shift, nap before the next one.
  final postShiftSleep = session(
    DateTime(2026, 9, 10, 8, 0),
    DateTime(2026, 9, 10, 14, 0), // 6h
    quality: 4,
  );
  final preShiftNap = session(
    DateTime(2026, 9, 10, 19, 0),
    DateTime(2026, 9, 10, 20, 30), // 1.5h
    quality: 2,
  );

  group('DailySleep', () {
    test('totals every session in the day', () {
      final day = DailySleep(
        date: DateTime(2026, 9, 10),
        sessions: [postShiftSleep, preShiftNap],
      );

      expect(day.totalHours, 7.5);
      expect(day.isSplit, isTrue);
      expect(day.sessions, hasLength(2));
    });

    test('the main session is the longest one, whatever order it came in', () {
      final day = DailySleep(
        date: DateTime(2026, 9, 10),
        sessions: [preShiftNap, postShiftSleep],
      );

      expect(day.mainSession, postShiftSleep);
      expect(day.additionalSessions, [preShiftNap]);
    });

    test('quality is weighted by duration so a short nap cannot dominate', () {
      final day = DailySleep(
        date: DateTime(2026, 9, 10),
        sessions: [postShiftSleep, preShiftNap],
      );

      // 4 for 360min, 2 for 90min -> (1440 + 180) / 450 = 3.6 -> 4
      expect(day.quality, 4);
      // A plain mean would have been 3.
      expect(day.quality, isNot(3));
    });

    test('a single session day is not marked as split', () {
      final day = DailySleep(
        date: DateTime(2026, 9, 10),
        sessions: [postShiftSleep],
      );

      expect(day.isSplit, isFalse);
      expect(day.totalHours, 6);
      expect(day.additionalSessions, isEmpty);
    });

    test('groupByDay buckets by date, most recent first', () {
      final yesterday = session(
        DateTime(2026, 9, 9, 23, 0),
        DateTime(2026, 9, 9, 23, 45),
      );

      final days = DailySleep.groupByDay([preShiftNap, yesterday, postShiftSleep]);

      expect(days, hasLength(2));
      expect(days.first.date, DateTime(2026, 9, 10));
      expect(days.first.sessions, hasLength(2));
      expect(days.last.date, DateTime(2026, 9, 9));
      expect(days.last.sessions, hasLength(1));
    });

    test('averaging days, not records, is what keeps a nap from counting '
        'as a whole day', () {
      final singleLongDay = session(
        DateTime(2026, 9, 9, 0, 0),
        DateTime(2026, 9, 9, 8, 0), // 8h
      );

      final days = DailySleep.groupByDay(
        [singleLongDay, postShiftSleep, preShiftNap],
      );
      final perDayAverage =
          days.fold<double>(0, (sum, d) => sum + d.totalHours) / days.length;

      // Two days: 8h and 7.5h.
      expect(days, hasLength(2));
      expect(perDayAverage, closeTo(7.75, 0.001));

      // Averaging the three raw records instead would report 5.17h.
      final perRecordAverage = (8 + 6 + 1.5) / 3;
      expect(perRecordAverage, closeTo(5.17, 0.01));
    });
  });
}
