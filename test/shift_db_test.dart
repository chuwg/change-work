import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:change/models/shift.dart';
import 'package:change/services/database_service.dart';
import 'package:change/utils/constants.dart';

/// Locks down the "one shift per date" invariant.
///
/// Shifts used to be keyed only by uuid, so editing a day inserted a *second*
/// row and the old shift could be read back — which is how a changed shift kept
/// producing notifications for the shift it replaced.
void main() {
  late String dbPath;

  String iso(DateTime d) => DateTime(d.year, d.month, d.day).toIso8601String();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    dbPath = p.join(await getDatabasesPath(), AppConstants.dbName);
    final file = File(dbPath);
    if (file.existsSync()) file.deleteSync();

    // Recreate a v4 database carrying the duplicate rows the old code left
    // behind, so opening it through DatabaseService runs the real migration.
    final legacy = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(version: 4),
    );
    await legacy.execute('''
      CREATE TABLE shifts (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        start_time TEXT,
        end_time TEXT,
        note TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    // Non-unique index: exactly what shipped before the fix.
    await legacy.execute('CREATE INDEX idx_shifts_date ON shifts(date)');

    final day = DateTime(2026, 9, 10);
    // Same day edited three times -> three rows, newest last.
    await legacy.insert('shifts', {
      'id': 'first',
      'date': iso(day),
      'type': AppConstants.shiftDay,
      'start_time': '06:00',
      'end_time': '14:00',
      'created_at': DateTime(2026, 9, 1).toIso8601String(),
    });
    await legacy.insert('shifts', {
      'id': 'second',
      'date': iso(day),
      'type': AppConstants.shiftEvening,
      'start_time': '14:00',
      'end_time': '22:00',
      'created_at': DateTime(2026, 9, 2).toIso8601String(),
    });
    await legacy.insert('shifts', {
      'id': 'third',
      'date': iso(day),
      'type': AppConstants.shiftNight,
      'start_time': '22:00',
      'end_time': '06:00',
      'created_at': DateTime(2026, 9, 3).toIso8601String(),
    });
    await legacy.insert('shifts', {
      'id': 'untouched',
      'date': iso(DateTime(2026, 9, 11)),
      'type': AppConstants.shiftOff,
      'created_at': DateTime(2026, 9, 1).toIso8601String(),
    });
    await legacy.close();
  });

  tearDownAll(() {
    final file = File(dbPath);
    if (file.existsSync()) file.deleteSync();
  });

  test('migration collapses duplicate rows, keeping the latest edit', () async {
    // First access through DatabaseService triggers the v4 -> v5 upgrade.
    final shifts =
        await DatabaseService.instance.getShiftsForMonth(2026, 9);

    expect(shifts, hasLength(2));

    final tenth = shifts.firstWhere((s) => s.date.day == 10);
    expect(tenth.type, AppConstants.shiftNight,
        reason: 'the most recently inserted row must win');
    expect(tenth.id, 'third');

    expect(shifts.firstWhere((s) => s.date.day == 11).type,
        AppConstants.shiftOff);
  });

  test('getShiftForDate returns the surviving row', () async {
    final shift =
        await DatabaseService.instance.getShiftForDate(DateTime(2026, 9, 10));
    expect(shift, isNotNull);
    expect(shift!.type, AppConstants.shiftNight);
  });

  test('re-inserting a date replaces it instead of adding a row', () async {
    final date = DateTime(2026, 9, 10);

    // A fresh uuid on an existing date — the pattern-apply path.
    await DatabaseService.instance.insertShift(Shift(
      id: 'brand-new-uuid',
      date: date,
      type: AppConstants.shiftDay,
      startTime: '06:00',
      endTime: '14:00',
    ));

    final shifts = await DatabaseService.instance.getShiftsForMonth(2026, 9);
    expect(shifts.where((s) => s.date.day == 10), hasLength(1));
    expect(shifts.firstWhere((s) => s.date.day == 10).type,
        AppConstants.shiftDay);
  });

  test('batch insert of a pattern also keeps one row per date', () async {
    final dates = [
      DateTime(2026, 9, 10),
      DateTime(2026, 9, 11),
      DateTime(2026, 9, 12),
    ];

    await DatabaseService.instance.insertShifts([
      for (final d in dates)
        Shift(
          id: 'pattern-${d.day}',
          date: d,
          type: AppConstants.shiftNight,
          startTime: '22:00',
          endTime: '06:00',
        ),
    ]);

    final shifts = await DatabaseService.instance.getShiftsForMonth(2026, 9);
    expect(shifts, hasLength(3));
    expect(shifts.every((s) => s.type == AppConstants.shiftNight), isTrue);
  });
}
