import 'package:shared_preferences/shared_preferences.dart';
import '../providers/schedule_provider.dart';
import '../utils/constants.dart';
import 'notification_service.dart';

/// Centralized rescheduling of all schedule-dependent notifications.
///
/// This MUST be called whenever the shift schedule changes (add/remove/apply
/// pattern) or "today" rolls over, otherwise notifications scheduled for an
/// old schedule keep firing — producing duplicate/stale alarms.
///
/// It always cancels the relevant notification ID ranges first, so a slot that
/// no longer maps to a shift can never linger in the OS.
class NotificationScheduler {
  // ID ranges (kept in sync with NotificationService usage):
  //   2000-2006 : one-time shift start reminders (ordinal slots)
  //   1100-1106 : smart sleep reminders (day offset 0-6)
  //   5000-5006 : caffeine cutoff (day offset 0-6)
  //   4000-4006 : pre-shift nap alert (day offset 0-6)
  static const int _slots = 7;

  static Future<void> rescheduleForSchedule(ScheduleState schedule) async {
    final prefs = await SharedPreferences.getInstance();
    final shiftEnabled = prefs.getBool(AppConstants.shiftReminderKey) ?? true;
    final sleepEnabled = prefs.getBool(AppConstants.sleepReminderKey) ?? true;
    final minutesBefore = prefs.getInt(AppConstants.reminderMinutesKey) ?? 60;

    final notif = NotificationService.instance;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // --- Shift start reminders (slots 2000-2006) ---
    // Always cancel previous slots first so stale shifts never fire.
    for (int slot = 0; slot < _slots; slot++) {
      await notif.cancelNotification(2000 + slot);
    }
    if (shiftEnabled) {
      int slot = 0;
      for (int i = 0; i <= 14 && slot < _slots; i++) {
        final date = today.add(Duration(days: i));
        final shift = schedule.getShiftForDate(date);
        if (shift == null ||
            shift.type == AppConstants.shiftOff ||
            shift.startTime == null) continue;

        final parts = shift.startTime!.split(':');
        final shiftStart = DateTime(
          date.year, date.month, date.day,
          int.parse(parts[0]), int.parse(parts[1]),
        );

        // scheduleShiftReminder internally skips if reminder time is past.
        await notif.scheduleShiftReminder(
          id: 2000 + slot,
          shiftType: shift.type,
          shiftStart: shiftStart,
          minutesBefore: minutesBefore,
        );
        slot++;
      }
    }

    // --- Smart sleep / caffeine / pre-shift (day-offset slots) ---
    // Always cancel previous slots first (the old code only cancelled when
    // disabled, so changed days left stale reminders behind).
    for (int i = 0; i < _slots; i++) {
      await notif.cancelNotification(1100 + i);
      await notif.cancelNotification(4000 + i);
      await notif.cancelNotification(5000 + i);
    }
    if (sleepEnabled) {
      for (int i = 0; i < _slots; i++) {
        final date = today.add(Duration(days: i));
        final tomorrow = date.add(const Duration(days: 1));
        final tomorrowShift = schedule.getShiftForDate(tomorrow);
        final tomorrowType = tomorrowShift?.type ?? 'off';

        final bedtime = await notif.scheduleSmartSleepReminder(
          id: 1100 + i,
          tomorrowShiftType: tomorrowType,
          date: date,
          shiftStartTime: tomorrowShift?.startTime,
        );

        if (bedtime != null) {
          await notif.scheduleCaffeineCutoff(id: 5000 + i, bedtime: bedtime);
        }

        await notif.schedulePreShiftAlert(
          id: 4000 + i,
          tomorrowShiftType: tomorrowType,
          today: date,
        );
      }
    }
  }
}
