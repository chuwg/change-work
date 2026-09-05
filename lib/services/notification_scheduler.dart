import 'package:shared_preferences/shared_preferences.dart';
import '../models/shift.dart';
import '../providers/schedule_provider.dart';
import '../utils/constants.dart';
import 'database_service.dart';
import 'notification_plan.dart';
import 'notification_service.dart';

/// Centralized rescheduling of all schedule-dependent notifications.
///
/// This MUST be called whenever the shift schedule changes (add/remove/apply
/// pattern) or "today" rolls over, otherwise notifications scheduled for an
/// old schedule keep firing — producing duplicate/stale alarms.
///
/// It always cancels every id the planner owns first, so a slot that no longer
/// maps to a shift can never linger in the OS.
///
/// What gets scheduled is decided by [NotificationPlanner], which is pure and
/// unit-tested; this class only resolves the schedule and talks to the OS.
class NotificationScheduler {
  /// Resolve the shifts for [today .. today + lookaheadDays].
  ///
  /// [schedule] is the source of truth (it is always written before this runs),
  /// but its map only holds the months the UI has loaded — so a day past the
  /// month boundary would silently look like "no shift". Fill those gaps from
  /// the DB, which every mutation writes to before rescheduling.
  static Future<Map<DateTime, Shift?>> _resolveWindow(
    ScheduleState schedule,
    DateTime today,
  ) async {
    final window = <DateTime, Shift?>{};
    final missing = <DateTime>[];

    for (int i = 0; i <= NotificationPlanner.lookaheadDays; i++) {
      final date = today.add(Duration(days: i));
      final key = DateTime(date.year, date.month, date.day);
      final shift = schedule.getShiftForDate(key);
      window[key] = shift;
      if (shift == null) missing.add(key);
    }

    if (missing.isNotEmpty) {
      try {
        for (final key in missing) {
          window[key] = await DatabaseService.instance.getShiftForDate(key);
        }
      } catch (_) {
        // No DB (e.g. web): the in-memory schedule is all we have.
      }
    }

    return window;
  }

  /// Build the plan the OS should be holding right now, without scheduling it.
  /// The notification settings screen renders this so the user sees exactly
  /// what the scheduler would queue.
  static Future<List<PlannedNotification>> buildPlan(
    ScheduleState schedule,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final window = await _resolveWindow(schedule, today);

    return NotificationPlanner.build(
      now: now,
      shiftFor: (date) => window[DateTime(date.year, date.month, date.day)],
      shiftEnabled: prefs.getBool(AppConstants.shiftReminderKey) ?? true,
      sleepEnabled: prefs.getBool(AppConstants.sleepReminderKey) ?? true,
      minutesBefore: prefs.getInt(AppConstants.reminderMinutesKey) ?? 60,
    );
  }

  static Future<void> rescheduleForSchedule(ScheduleState schedule) async {
    final plan = await buildPlan(schedule);
    final notif = NotificationService.instance;

    // Always clear the previous generation first so stale shifts never fire.
    for (final id in NotificationPlanner.allIds) {
      await notif.cancelNotification(id);
    }

    for (final planned in plan) {
      await notif.schedulePlanned(planned);
    }
  }
}
