import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/shift.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'database_service.dart';

/// One calendar event as the native side expects it.
class CalendarShiftEvent {
  final String date; // yyyy-MM-dd
  final String title;
  final String? start; // HH:mm, null for all-day
  final String? end;
  final String? note;

  const CalendarShiftEvent({
    required this.date,
    required this.title,
    this.start,
    this.end,
    this.note,
  });

  Map<String, Object?> toMap() => {
        'date': date,
        'title': title,
        'start': start,
        'end': end,
        'note': note,
      };
}

/// Turns shifts into calendar events. Pure, so the mapping is unit-tested.
class CalendarEventBuilder {
  static List<CalendarShiftEvent> build(Iterable<Shift> shifts) {
    final fmt = DateFormat('yyyy-MM-dd');
    final events = <CalendarShiftEvent>[];
    for (final shift in shifts) {
      final date = fmt.format(shift.date);
      final note = [
        if (shift.isSwapped) '${shift.swapWith}과(와) 근무 교환',
        if (shift.hasNote) shift.note!,
      ].join('\n');

      if (shift.type == AppConstants.shiftOff) {
        // Off days are what family members most want to see, so they go in
        // as all-day events rather than being left out.
        events.add(CalendarShiftEvent(
            date: date, title: '휴무', note: note.isEmpty ? null : note));
        continue;
      }

      final defaults = AppConstants.defaultShiftTimes[shift.type];
      final start = _orNull(shift.startTime) ?? defaults?['start'];
      final end = _orNull(shift.endTime) ?? defaults?['end'];
      events.add(CalendarShiftEvent(
        date: date,
        title: AppHelpers.getShiftDisplayName(shift.type),
        start: start,
        end: start == null ? null : end,
        note: note.isEmpty ? null : note,
      ));
    }
    return events;
  }

  static String? _orNull(String? s) => (s == null || s.isEmpty) ? null : s;
}

enum CalendarSyncResult { synced, denied, failed, unsupported }

/// Keeps the "Change 근무" calendar in the iOS Calendar app in step with the
/// schedule. iOS only: the native side is EventKit.
class CalendarSyncService {
  static final CalendarSyncService instance = CalendarSyncService._();
  CalendarSyncService._();

  static const _channel = MethodChannel('com.change.app/calendar');

  /// How far back and ahead the calendar mirrors.
  static const int pastDays = 30;
  static const int futureDays = 180;

  Timer? _debounce;

  bool get isSupported => !kIsWeb && Platform.isIOS;

  Future<bool> isEnabled() async {
    if (!isSupported) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.calendarSyncKey) ?? false;
  }

  /// Ask for access, then do a first full sync. Leaves the setting off if the
  /// user declines.
  Future<CalendarSyncResult> enable() async {
    if (!isSupported) return CalendarSyncResult.unsupported;
    try {
      final granted =
          await _channel.invokeMethod<bool>('requestAccess') ?? false;
      if (!granted) return CalendarSyncResult.denied;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.calendarSyncKey, true);
      return await syncNow();
    } catch (e) {
      if (kDebugMode) debugPrint('[CalendarSync] enable failed: $e');
      return CalendarSyncResult.failed;
    }
  }

  /// Turn off and delete the app's calendar (only ever its own events).
  Future<void> disable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.calendarSyncKey, false);
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<bool>('removeCalendar');
    } catch (e) {
      if (kDebugMode) debugPrint('[CalendarSync] remove failed: $e');
    }
  }

  /// Coalesce bursts (applying a pattern writes dozens of days) into one sync.
  void scheduleSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () async {
      if (await isEnabled()) await syncNow();
    });
  }

  /// The mirrored window slides one day a day, so re-sync once per day on
  /// launch/resume — also catches edits made while access was revoked.
  Future<void> syncIfStale() async {
    if (!await isEnabled()) return;
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (prefs.getString(_lastSyncKey) == today) return;
    await syncNow();
  }

  static const _lastSyncKey = 'calendar_sync_last_day';

  Future<CalendarSyncResult> syncNow() async {
    if (!isSupported) return CalendarSyncResult.unsupported;
    try {
      final status = await _channel.invokeMethod<String>('authorizationStatus');
      if (status != 'authorized') return CalendarSyncResult.denied;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final from = today.subtract(const Duration(days: pastDays));
      final to = today.add(const Duration(days: futureDays));

      final shifts = (await DatabaseService.instance.getAllShifts()).where(
          (s) => !s.date.isBefore(from) && !s.date.isAfter(to));

      final fmt = DateFormat('yyyy-MM-dd');
      await _channel.invokeMethod<int>('sync', {
        'from': fmt.format(from),
        'to': fmt.format(to),
        'events': CalendarEventBuilder.build(shifts).map((e) => e.toMap()).toList(),
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, fmt.format(now));
      return CalendarSyncResult.synced;
    } catch (e) {
      if (kDebugMode) debugPrint('[CalendarSync] sync failed: $e');
      return CalendarSyncResult.failed;
    }
  }
}
