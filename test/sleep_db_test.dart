import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:change/models/daily_sleep.dart';
import 'package:change/models/sleep_record.dart';
import 'package:change/services/database_service.dart';

/// The sleep table has no unique constraint on date — more than one session a
/// day is expected. This locks in that the storage layer actually keeps them.
void main() {
  late String dbPath;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseService.databaseName = 'sleep_test.db';
    await DatabaseService.resetForTesting();
    dbPath = p.join(await getDatabasesPath(), DatabaseService.databaseName);
    final file = File(dbPath);
    if (file.existsSync()) file.deleteSync();
  });

  tearDownAll(() async {
    await DatabaseService.resetForTesting();
    final file = File(dbPath);
    if (file.existsSync()) file.deleteSync();
  });

  final day = DateTime(2026, 9, 10);

  SleepRecord session(String id, DateTime bed, DateTime wake, int quality) =>
      SleepRecord(
        id: id,
        date: day,
        bedTime: bed,
        wakeTime: wake,
        quality: quality,
        shiftType: 'night',
        source: 'healthkit',
      );

  test('both sessions of a split-sleep day survive', () async {
    final db = DatabaseService.instance;

    await db.insertSleepRecord(session(
        'main', DateTime(2026, 9, 10, 8, 0), DateTime(2026, 9, 10, 14, 0), 4));
    await db.insertSleepRecord(session(
        'nap', DateTime(2026, 9, 10, 19, 0), DateTime(2026, 9, 10, 20, 30), 2));

    final records = await db.getSleepRecordsForDate(day);
    expect(records, hasLength(2));

    // Longest first, so the singular accessor is deterministic.
    expect(records.first.id, 'main');
    expect((await db.getSleepRecordForDate(day))!.id, 'main');

    final grouped = DailySleep.groupByDay(records).single;
    expect(grouped.totalHours, 7.5);
    expect(grouped.isSplit, isTrue);
  });

  test('shift-type averages count days, not records', () async {
    final averages = await DatabaseService.instance.getAverageSleepByShiftType();

    // One night-shift day totalling 7.5h — not the 3.75h a per-record mean of
    // the 6h session and the 1.5h nap would have reported.
    expect(averages['night'], closeTo(7.5, 0.01));
  });
}
