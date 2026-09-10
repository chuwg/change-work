import 'sleep_record.dart';

/// All the sleep a person got on one calendar day.
///
/// Shift workers routinely sleep more than once a day — six hours after a
/// night shift plus a nap before the next one — and each of those is stored as
/// its own [SleepRecord]. Anything that means "how much did I sleep" has to go
/// through this, because a per-record average would count that 90-minute nap
/// as if it were a whole day's sleep.
class DailySleep {
  /// Midnight of the day these sessions are filed under (the day they ended).
  final DateTime date;

  /// Every session for [date], longest first. Never empty.
  final List<SleepRecord> sessions;

  DailySleep({required this.date, required List<SleepRecord> sessions})
      : assert(sessions.isNotEmpty),
        sessions = List.unmodifiable(
          [...sessions]..sort((a, b) => b.duration.compareTo(a.duration)),
        );

  /// Group raw records into one [DailySleep] per day, most recent first.
  static List<DailySleep> groupByDay(Iterable<SleepRecord> records) {
    final byDay = <DateTime, List<SleepRecord>>{};
    for (final r in records) {
      final key = DateTime(r.date.year, r.date.month, r.date.day);
      byDay.putIfAbsent(key, () => []).add(r);
    }
    final days = byDay.entries
        .map((e) => DailySleep(date: e.key, sessions: e.value))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return days;
  }

  /// The longest session — what the UI shows as the day's 취침/기상 time.
  SleepRecord get mainSession => sessions.first;

  /// Everything except the main session.
  List<SleepRecord> get additionalSessions => sessions.skip(1).toList();

  bool get isSplit => sessions.length > 1;

  Duration get totalDuration => sessions.fold(
        Duration.zero,
        (sum, r) => sum + r.duration,
      );

  double get totalHours => totalDuration.inMinutes / 60.0;

  /// Quality weighted by how long each session was, so a short nap cannot
  /// drag down the rating of a full night.
  int get quality {
    final minutes = totalDuration.inMinutes;
    if (minutes == 0) return mainSession.quality;
    final weighted = sessions.fold<double>(
      0,
      (sum, r) => sum + r.quality * r.duration.inMinutes,
    );
    return (weighted / minutes).round().clamp(1, 5);
  }

  String? get shiftType => mainSession.shiftType;
}
