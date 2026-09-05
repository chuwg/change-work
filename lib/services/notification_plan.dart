import '../models/shift.dart';
import '../utils/constants.dart';

/// What a planned notification is for. Determines the channel it goes out on
/// and the label the diagnostics screen shows.
enum NotificationKind {
  /// "지금 출발하세요!" — fires [minutesBefore] ahead of a shift start.
  shiftStart,

  /// Recommended bedtime (or pre-night-shift nap) for a given shift.
  bedtime,

  /// Caffeine cutoff, 6h before the matching bedtime.
  caffeineCutoff,

  /// Noon heads-up on the day a night shift starts.
  preShiftNap,
}

/// One notification the app intends to have sitting in the OS queue.
class PlannedNotification {
  final int id;
  final NotificationKind kind;
  final DateTime time;
  final String title;
  final String body;

  const PlannedNotification({
    required this.id,
    required this.kind,
    required this.time,
    required this.title,
    required this.body,
  });

  @override
  String toString() => 'PlannedNotification($id, ${kind.name}, $time, $title)';
}

/// Works out *what* should be scheduled, without touching the OS.
///
/// Everything here is a pure function of [now] and the shift lookup, which is
/// what makes the schedule testable — and lets the settings screen show the
/// user the exact same list the scheduler is about to hand to the OS.
class NotificationPlanner {
  /// Notifications reserved per category. The OS keeps them queued while the
  /// app is closed, so this is also "how many days offline we cover".
  static const int slots = 7;

  /// How far ahead shift reminders may be pulled from.
  static const int lookaheadDays = 15;

  static const int shiftBaseId = 2000;
  static const int bedtimeBaseId = 1100;
  static const int preShiftBaseId = 4000;
  static const int caffeineBaseId = 5000;

  /// Sleep + prep window subtracted from a shift start to get bedtime.
  static const Duration _sleepWindow = Duration(hours: 8);

  /// How long before bedtime caffeine should stop.
  static const Duration _caffeineWindow = Duration(hours: 6);

  /// Every notification id this planner owns, so callers can clear the old
  /// generation before scheduling a new one.
  static List<int> get allIds => <int>[
        for (int i = 0; i < slots; i++) ...<int>[
          shiftBaseId + i,
          bedtimeBaseId + i,
          preShiftBaseId + i,
          caffeineBaseId + i,
        ],
      ];

  /// Build the notification plan for the next [lookaheadDays].
  ///
  /// [shiftFor] is called with midnight-normalised dates and should return the
  /// shift on that day, or null when there is none.
  static List<PlannedNotification> build({
    required DateTime now,
    required Shift? Function(DateTime date) shiftFor,
    bool shiftEnabled = true,
    bool sleepEnabled = true,
    int minutesBefore = 60,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final plan = <PlannedNotification>[];

    if (shiftEnabled) {
      // Slots are handed out in date order and only to shifts whose reminder
      // is still ahead of us, so a shift that already started today does not
      // burn one of the seven.
      int slot = 0;
      for (int i = 0; i < lookaheadDays && slot < slots; i++) {
        final date = today.add(Duration(days: i));
        final shift = shiftFor(date);
        if (shift == null || shift.type == AppConstants.shiftOff) continue;

        final start = _atTime(date, shift.startTime);
        if (start == null) continue;

        final remindAt = start.subtract(Duration(minutes: minutesBefore));
        if (!remindAt.isAfter(now)) continue;

        plan.add(PlannedNotification(
          id: shiftBaseId + slot,
          kind: NotificationKind.shiftStart,
          time: remindAt,
          title: '지금 출발하세요!',
          body: '${_shiftLabel(shift.type)} 근무 ${_hhmm(start)} 시작 '
              '· 이동 시간 $minutesBefore분',
        ));
        slot++;
      }
    }

    if (sleepEnabled) {
      // Slot i covers the shift on today+i. Times are derived from that shift,
      // so slot 0 still covers a night shift that starts tonight.
      for (int i = 0; i < slots; i++) {
        final shiftDate = today.add(Duration(days: i));
        final shift = shiftFor(shiftDate);
        final type = shift?.type ?? AppConstants.shiftOff;
        final start = type == AppConstants.shiftOff
            ? null
            : _atTime(shiftDate, shift?.startTime);

        final bedtime = bedtimeFor(shiftDate: shiftDate, shiftStart: start);

        if (bedtime.isAfter(now)) {
          // A bedtime landing on the shift day itself (night/evening shifts)
          // must not say "내일".
          final onShiftDay = _isSameDay(bedtime, shiftDate);
          final when = onShiftDay ? '오늘' : '내일';

          plan.add(PlannedNotification(
            id: bedtimeBaseId + i,
            kind: NotificationKind.bedtime,
            time: bedtime,
            title: type == AppConstants.shiftNight
                ? '낮잠 시간이에요'
                : '취침 시간이에요',
            body: _bedtimeBody(type, when),
          ));

          final cutoff = bedtime.subtract(_caffeineWindow);
          if (cutoff.isAfter(now)) {
            plan.add(PlannedNotification(
              id: caffeineBaseId + i,
              kind: NotificationKind.caffeineCutoff,
              time: cutoff,
              title: '카페인 마감 시간',
              body: '목표 취침 ${_hhmm(bedtime)} 기준, 지금부터 카페인을 피하세요',
            ));
          }
        }

        if (type == AppConstants.shiftNight) {
          final noon = DateTime(
              shiftDate.year, shiftDate.month, shiftDate.day, 12, 0);
          if (noon.isAfter(now)) {
            plan.add(PlannedNotification(
              id: preShiftBaseId + i,
              kind: NotificationKind.preShiftNap,
              time: noon,
              title: '오늘 밤 야간근무 준비',
              body: '오후에 90분 이내 낮잠을 추천해요. 카페인은 근무 시작 전에만!',
            ));
          }
        }
      }
    }

    plan.sort((a, b) => a.time.compareTo(b.time));
    return plan;
  }

  /// Recommended bedtime for the shift on [shiftDate].
  ///
  /// Derived from the shift's own start time (start − 8h = 7h sleep + 1h prep),
  /// so it lands on whichever calendar day that actually falls on: a 06:00 day
  /// shift means 22:00 the night before, a 22:00 night shift means a 14:00 nap
  /// on the shift day itself. An off day (or a shift with no known start time)
  /// winds down at 23:00 the evening before.
  static DateTime bedtimeFor({
    required DateTime shiftDate,
    required DateTime? shiftStart,
  }) {
    if (shiftStart != null) return shiftStart.subtract(_sleepWindow);
    final day = DateTime(shiftDate.year, shiftDate.month, shiftDate.day);
    return day.subtract(const Duration(days: 1)).add(const Duration(hours: 23));
  }

  static String _bedtimeBody(String type, String when) {
    switch (type) {
      case AppConstants.shiftDay:
        return '$when 주간근무, 지금 잠들면 충분한 수면을 확보할 수 있어요';
      case AppConstants.shiftEvening:
        return '$when 오후근무, 여유 있게 수면을 취하세요';
      case AppConstants.shiftNight:
        return '$when 밤 야간근무, 지금 낮잠으로 체력을 비축하세요';
      case AppConstants.shiftOff:
        return '$when은 휴무! 편하게 쉬되 수면 리듬을 유지하세요';
      default:
        return '충분한 수면을 위해 잠자리에 드세요';
    }
  }

  /// Combine [date] with an "HH:mm" string. Returns null for an off shift, a
  /// missing time, or anything that does not parse.
  static DateTime? _atTime(DateTime date, String? hhmm) {
    if (hhmm == null) return null;
    final parts = hhmm.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  static String _shiftLabel(String type) => const {
        AppConstants.shiftDay: '주간',
        AppConstants.shiftEvening: '오후',
        AppConstants.shiftNight: '야간',
      }[type] ??
      type;
}

/// Human-readable category label for the diagnostics screen.
extension NotificationKindLabel on NotificationKind {
  String get label {
    switch (this) {
      case NotificationKind.shiftStart:
        return '출발 알림';
      case NotificationKind.bedtime:
        return '취침·낮잠';
      case NotificationKind.caffeineCutoff:
        return '카페인 마감';
      case NotificationKind.preShiftNap:
        return '야간근무 준비';
    }
  }
}
