import 'package:flutter_test/flutter_test.dart';

import 'package:change/models/shift.dart';
import 'package:change/services/notification_plan.dart';
import 'package:change/utils/constants.dart';

/// Regression tests for the notification schedule.
///
/// The bugs these lock down were all "the notification fires, but for the
/// wrong shift or on the wrong day", which is invisible until a user misses
/// work — so the timing is asserted to the minute.
void main() {
  Shift shift(DateTime date, String type, {String? start}) => Shift(
        id: '$type-${date.toIso8601String()}',
        date: DateTime(date.year, date.month, date.day),
        type: type,
        startTime: start ??
            AppConstants.defaultShiftTimes[type]?['start'],
        endTime: AppConstants.defaultShiftTimes[type]?['end'],
      );

  /// Build a lookup from a day-offset -> shift type map, relative to [base].
  Shift? Function(DateTime) scheduleOf(
    DateTime base,
    Map<int, String> byOffset,
  ) {
    final byDate = <DateTime, Shift>{};
    byOffset.forEach((offset, type) {
      final date = DateTime(base.year, base.month, base.day + offset);
      byDate[date] = shift(date, type);
    });
    return (date) => byDate[DateTime(date.year, date.month, date.day)];
  }

  PlannedNotification? firstOfKind(
    List<PlannedNotification> plan,
    NotificationKind kind,
  ) =>
      plan.where((p) => p.kind == kind).firstOrNull;

  List<PlannedNotification> ofKind(
    List<PlannedNotification> plan,
    NotificationKind kind,
  ) =>
      plan.where((p) => p.kind == kind).toList();

  group('bedtime lands on the right calendar day', () {
    // The night-shift case is the one that used to fire a full day early.
    test('night shift (22:00) naps at 14:00 on the shift day itself', () {
      final now = DateTime(2026, 9, 5, 8, 0);
      final plan = NotificationPlanner.build(
        now: now,
        shiftFor: scheduleOf(now, {0: AppConstants.shiftNight}),
        shiftEnabled: false,
      );

      final bedtime = firstOfKind(plan, NotificationKind.bedtime)!;
      expect(bedtime.time, DateTime(2026, 9, 5, 14, 0));
      expect(bedtime.body, contains('오늘 밤 야간근무'));
      expect(bedtime.title, '낮잠 시간이에요');
    });

    test('day shift (06:00) sleeps at 22:00 the night before', () {
      final now = DateTime(2026, 9, 5, 8, 0);
      final plan = NotificationPlanner.build(
        now: now,
        shiftFor: scheduleOf(now, {1: AppConstants.shiftDay}),
        shiftEnabled: false,
      );

      final bedtime = ofKind(plan, NotificationKind.bedtime)
          .firstWhere((p) => p.body.contains('주간근무'));
      expect(bedtime.time, DateTime(2026, 9, 5, 22, 0));
      expect(bedtime.body, startsWith('내일'));
    });

    test('evening shift (14:00) sleeps at 06:00 on the shift day', () {
      final now = DateTime(2026, 9, 5, 8, 0);
      final plan = NotificationPlanner.build(
        now: now,
        shiftFor: scheduleOf(now, {1: AppConstants.shiftEvening}),
        shiftEnabled: false,
      );

      final bedtime = ofKind(plan, NotificationKind.bedtime)
          .firstWhere((p) => p.body.contains('오후근무'));
      expect(bedtime.time, DateTime(2026, 9, 6, 6, 0));
      expect(bedtime.body, startsWith('오늘'));
    });

    test('off day winds down at 23:00 the evening before', () {
      final now = DateTime(2026, 9, 5, 8, 0);
      final plan = NotificationPlanner.build(
        now: now,
        shiftFor: scheduleOf(now, {1: AppConstants.shiftOff}),
        shiftEnabled: false,
      );

      final bedtime = ofKind(plan, NotificationKind.bedtime)
          .firstWhere((p) => p.body.contains('휴무'));
      expect(bedtime.time, DateTime(2026, 9, 5, 23, 0));
      expect(bedtime.body, startsWith('내일'));
    });
  });

  group('night-shift nap alert', () {
    test('fires at noon on the shift day, not the day before', () {
      final now = DateTime(2026, 9, 5, 8, 0);
      final plan = NotificationPlanner.build(
        now: now,
        shiftFor: scheduleOf(now, {2: AppConstants.shiftNight}),
        shiftEnabled: false,
      );

      final nap = firstOfKind(plan, NotificationKind.preShiftNap)!;
      expect(nap.time, DateTime(2026, 9, 7, 12, 0));
    });

    test('is not scheduled for non-night shifts', () {
      final now = DateTime(2026, 9, 5, 8, 0);
      final plan = NotificationPlanner.build(
        now: now,
        shiftFor: scheduleOf(now, {
          1: AppConstants.shiftDay,
          2: AppConstants.shiftEvening,
          3: AppConstants.shiftOff,
        }),
        shiftEnabled: false,
      );

      expect(ofKind(plan, NotificationKind.preShiftNap), isEmpty);
    });
  });

  group('caffeine cutoff', () {
    test('is 6h before the matching bedtime', () {
      final now = DateTime(2026, 9, 5, 3, 0);
      final plan = NotificationPlanner.build(
        now: now,
        shiftFor: scheduleOf(now, {0: AppConstants.shiftNight}),
        shiftEnabled: false,
      );

      final cutoff = firstOfKind(plan, NotificationKind.caffeineCutoff)!;
      expect(cutoff.time, DateTime(2026, 9, 5, 8, 0));
      expect(cutoff.body, contains('14:00'));
    });

    test('is dropped when it has already passed', () {
      // Bedtime 14:00 -> cutoff 08:00, and it is already 10:00.
      final now = DateTime(2026, 9, 5, 10, 0);
      final plan = NotificationPlanner.build(
        now: now,
        shiftFor: scheduleOf(now, {0: AppConstants.shiftNight}),
        shiftEnabled: false,
      );

      expect(firstOfKind(plan, NotificationKind.bedtime), isNotNull);
      expect(
        ofKind(plan, NotificationKind.caffeineCutoff)
            .where((p) => p.id == NotificationPlanner.caffeineBaseId),
        isEmpty,
      );
    });
  });

  group('shift start reminders', () {
    test('fire minutesBefore ahead of the shift start', () {
      final now = DateTime(2026, 9, 5, 8, 0);
      final plan = NotificationPlanner.build(
        now: now,
        shiftFor: scheduleOf(now, {1: AppConstants.shiftDay}),
        sleepEnabled: false,
        minutesBefore: 90,
      );

      final reminder = firstOfKind(plan, NotificationKind.shiftStart)!;
      expect(reminder.time, DateTime(2026, 9, 6, 4, 30));
      expect(reminder.body, contains('주간 근무 06:00 시작'));
      expect(reminder.body, contains('90분'));
    });

    test('a shift whose reminder already passed does not burn a slot', () {
      // 06:00 day shift today: its 05:00 reminder is gone by 08:00, so all
      // seven slots must still be available to the following days.
      final now = DateTime(2026, 9, 5, 8, 0);
      final plan = NotificationPlanner.build(
        now: now,
        shiftFor: scheduleOf(now, {
          for (int i = 0; i <= 7; i++) i: AppConstants.shiftDay,
        }),
        sleepEnabled: false,
      );

      final reminders = ofKind(plan, NotificationKind.shiftStart);
      expect(reminders, hasLength(NotificationPlanner.slots));
      // Slot 0 belongs to tomorrow, not to today's already-past shift.
      expect(reminders.first.id, NotificationPlanner.shiftBaseId);
      expect(reminders.first.time, DateTime(2026, 9, 6, 5, 0));
      // Ids are contiguous and unique.
      expect(
        reminders.map((r) => r.id).toSet(),
        {for (int i = 0; i < 7; i++) NotificationPlanner.shiftBaseId + i},
      );
    });

    test('off days are skipped and the next working day takes the slot', () {
      final now = DateTime(2026, 9, 5, 8, 0);
      final plan = NotificationPlanner.build(
        now: now,
        shiftFor: scheduleOf(now, {
          1: AppConstants.shiftOff,
          2: AppConstants.shiftOff,
          3: AppConstants.shiftNight,
        }),
        sleepEnabled: false,
      );

      final reminders = ofKind(plan, NotificationKind.shiftStart);
      expect(reminders, hasLength(1));
      expect(reminders.single.time, DateTime(2026, 9, 8, 21, 0));
    });

    test('reaches shifts in the following month', () {
      final now = DateTime(2026, 9, 28, 8, 0);
      final plan = NotificationPlanner.build(
        now: now,
        shiftFor: scheduleOf(now, {5: AppConstants.shiftDay}),
        sleepEnabled: false,
      );

      final reminder = firstOfKind(plan, NotificationKind.shiftStart)!;
      expect(reminder.time, DateTime(2026, 10, 3, 5, 0));
    });
  });

  group('settings toggles', () {
    test('shiftEnabled: false drops only the shift reminders', () {
      final now = DateTime(2026, 9, 5, 8, 0);
      final plan = NotificationPlanner.build(
        now: now,
        shiftFor: scheduleOf(now, {1: AppConstants.shiftDay}),
        shiftEnabled: false,
      );

      expect(ofKind(plan, NotificationKind.shiftStart), isEmpty);
      expect(ofKind(plan, NotificationKind.bedtime), isNotEmpty);
    });

    test('sleepEnabled: false drops sleep, caffeine and nap alerts', () {
      final now = DateTime(2026, 9, 5, 8, 0);
      final plan = NotificationPlanner.build(
        now: now,
        shiftFor: scheduleOf(now, {1: AppConstants.shiftNight}),
        sleepEnabled: false,
      );

      expect(ofKind(plan, NotificationKind.bedtime), isEmpty);
      expect(ofKind(plan, NotificationKind.caffeineCutoff), isEmpty);
      expect(ofKind(plan, NotificationKind.preShiftNap), isEmpty);
      expect(ofKind(plan, NotificationKind.shiftStart), isNotEmpty);
    });
  });

  group('plan invariants', () {
    test('no notification is ever scheduled in the past', () {
      final now = DateTime(2026, 9, 5, 13, 30);
      final plan = NotificationPlanner.build(
        now: now,
        shiftFor: scheduleOf(now, {
          0: AppConstants.shiftNight,
          1: AppConstants.shiftNight,
          2: AppConstants.shiftDay,
          3: AppConstants.shiftOff,
          4: AppConstants.shiftEvening,
        }),
      );

      expect(plan, isNotEmpty);
      for (final p in plan) {
        expect(p.time.isAfter(now), isTrue,
            reason: '${p.kind.name} scheduled at ${p.time}, now is $now');
      }
    });

    test('ids are unique and owned by the planner', () {
      final now = DateTime(2026, 9, 5, 0, 30);
      final plan = NotificationPlanner.build(
        now: now,
        shiftFor: scheduleOf(now, {
          for (int i = 0; i <= 10; i++)
            i: [
              AppConstants.shiftDay,
              AppConstants.shiftEvening,
              AppConstants.shiftNight,
              AppConstants.shiftOff,
            ][i % 4],
        }),
      );

      final ids = plan.map((p) => p.id).toList();
      expect(ids.toSet(), hasLength(ids.length), reason: 'duplicate ids');
      expect(NotificationPlanner.allIds.toSet().containsAll(ids), isTrue,
          reason: 'an id outside the cancelled ranges would never be cleared');
    });

    test('plan is ordered by time', () {
      final now = DateTime(2026, 9, 5, 0, 30);
      final plan = NotificationPlanner.build(
        now: now,
        shiftFor: scheduleOf(now, {
          for (int i = 0; i <= 8; i++)
            i: i.isEven ? AppConstants.shiftNight : AppConstants.shiftDay,
        }),
      );

      for (int i = 1; i < plan.length; i++) {
        expect(plan[i].time.isBefore(plan[i - 1].time), isFalse);
      }
    });

    test('an empty schedule still plans the off-day wind-down only', () {
      final now = DateTime(2026, 9, 5, 8, 0);
      final plan = NotificationPlanner.build(
        now: now,
        shiftFor: (_) => null,
      );

      expect(ofKind(plan, NotificationKind.shiftStart), isEmpty);
      expect(ofKind(plan, NotificationKind.preShiftNap), isEmpty);
      expect(
        ofKind(plan, NotificationKind.bedtime).every(
          (p) => p.body.contains('휴무'),
        ),
        isTrue,
      );
    });
  });
}
