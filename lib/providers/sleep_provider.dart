import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/sleep_record.dart';
import '../models/daily_sleep.dart';
import '../services/database_service.dart';
import '../services/widget_service.dart';

const _uuid = Uuid();

class SleepState {
  final List<SleepRecord> records;
  final SleepRecord? todayRecord;
  final Map<String, double> avgByShiftType;
  final bool isLoading;

  const SleepState({
    this.records = const [],
    this.todayRecord,
    this.avgByShiftType = const {},
    this.isLoading = false,
  });

  SleepState copyWith({
    List<SleepRecord>? records,
    Object? todayRecord = _sentinel,
    Map<String, double>? avgByShiftType,
    bool? isLoading,
  }) {
    return SleepState(
      records: records ?? this.records,
      todayRecord: todayRecord == _sentinel
          ? this.todayRecord
          : todayRecord as SleepRecord?,
      avgByShiftType: avgByShiftType ?? this.avgByShiftType,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  static const _sentinel = Object();

  /// [records] grouped into days, most recent first.
  ///
  /// Every "how much sleep" figure has to come from here: a day can hold more
  /// than one session, and averaging raw records counts a nap as a whole day.
  List<DailySleep> get days => DailySleep.groupByDay(records);

  /// Today's sleep, all sessions included. Null when nothing is recorded.
  DailySleep? get todaySleep {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final day in days) {
      if (day.date == today) return day;
    }
    return null;
  }

  double get averageSleepHours {
    final grouped = days;
    if (grouped.isEmpty) return 0;
    final total = grouped.fold<double>(0, (sum, d) => sum + d.totalHours);
    return total / grouped.length;
  }

  double get averageQuality {
    final grouped = days;
    if (grouped.isEmpty) return 0;
    final total = grouped.fold<int>(0, (sum, d) => sum + d.quality);
    return total / grouped.length;
  }

  List<SleepRecord> get last7Days {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return records.where((r) => r.date.isAfter(weekAgo)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Last 7 days grouped per day, oldest first — what charts and the weekly
  /// report should plot, since a split-sleep day is still one day.
  List<DailySleep> get last7DaysByDay {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return days
        .where((d) => d.date.isAfter(weekAgo))
        .toList()
        .reversed
        .toList();
  }

  /// Last 30 days grouped per day, oldest first.
  List<DailySleep> get last30DaysByDay {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    return days
        .where((d) => d.date.isAfter(monthAgo))
        .toList()
        .reversed
        .toList();
  }

  List<SleepRecord> get last30Days {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    return records.where((r) => r.date.isAfter(monthAgo)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}

class SleepNotifier extends StateNotifier<SleepState> {
  final DatabaseService _db;

  SleepNotifier(this._db) : super(const SleepState());

  Future<void> loadRecords() async {
    state = state.copyWith(isLoading: true);
    final records = await _db.getSleepRecords(limit: 90);
    final todayRecord = await _db.getSleepRecordForDate(DateTime.now());
    final avgByShift = await _db.getAverageSleepByShiftType();

    state = state.copyWith(
      records: records,
      todayRecord: todayRecord,
      avgByShiftType: avgByShift,
      isLoading: false,
    );
    final today = state.todaySleep;
    WidgetService.instance.updateSleepData(
      sleepHours: today?.totalHours ?? 0,
      sleepQuality: today?.quality ?? 0,
    );
  }

  Future<void> addSleepRecord({
    required DateTime date,
    required DateTime bedTime,
    required DateTime wakeTime,
    required int quality,
    String? shiftType,
    String? note,
  }) async {
    final record = SleepRecord(
      id: _uuid.v4(),
      date: DateTime(date.year, date.month, date.day),
      bedTime: bedTime,
      wakeTime: wakeTime,
      quality: quality,
      shiftType: shiftType,
      note: note,
    );

    await _db.insertSleepRecord(record);
    await loadRecords();
  }

  Future<void> deleteSleepRecord(String id) async {
    await _db.deleteSleepRecord(id);
    await loadRecords();
  }
}

final sleepProvider = StateNotifierProvider<SleepNotifier, SleepState>((ref) {
  return SleepNotifier(DatabaseService.instance);
});
