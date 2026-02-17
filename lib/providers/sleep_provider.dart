import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/sleep_record.dart';
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
    SleepRecord? todayRecord,
    Map<String, double>? avgByShiftType,
    bool? isLoading,
  }) {
    return SleepState(
      records: records ?? this.records,
      todayRecord: todayRecord ?? this.todayRecord,
      avgByShiftType: avgByShiftType ?? this.avgByShiftType,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  double get averageSleepHours {
    if (records.isEmpty) return 0;
    final total = records.fold<double>(0, (sum, r) => sum + r.durationHours);
    return total / records.length;
  }

  double get averageQuality {
    if (records.isEmpty) return 0;
    final total = records.fold<int>(0, (sum, r) => sum + r.quality);
    return total / records.length;
  }

  List<SleepRecord> get last7Days {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return records
        .where((r) => r.date.isAfter(weekAgo))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<SleepRecord> get last30Days {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    return records
        .where((r) => r.date.isAfter(monthAgo))
        .toList()
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
    WidgetService.instance.updateSleepData(
      sleepHours: todayRecord?.durationHours ?? 0,
      sleepQuality: todayRecord?.quality ?? 0,
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

final sleepProvider =
    StateNotifierProvider<SleepNotifier, SleepState>((ref) {
  return SleepNotifier(DatabaseService.instance);
});
