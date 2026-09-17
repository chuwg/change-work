import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:change/models/shift.dart';
import 'package:change/services/backup_service.dart';
import 'package:change/services/database_service.dart';

void main() {
  group('BackupSnapshot codec', () {
    final snapshot = BackupSnapshot(
      createdAt: DateTime(2026, 9, 17, 23, 0),
      tables: {
        'shifts': [
          {'id': 'a', 'date': '2026-09-18T00:00:00.000', 'type': 'night'},
        ],
        'sleep_records': [],
      },
      prefs: {'reminder_minutes': 45, 'theme_mode': 'light', 'sleep_reminder': false},
    );

    test('round-trips rows, prefs and timestamp', () {
      final decoded = BackupSnapshot.decode(snapshot.encode());
      expect(decoded.createdAt, snapshot.createdAt);
      expect(decoded.tables['shifts']!.single['type'], 'night');
      expect(decoded.prefs, snapshot.prefs);
      expect(decoded.recordCount, 1);
    });

    test('rejects files that are not a Change backup', () {
      expect(() => BackupSnapshot.decode('not json'), throwsFormatException);
      expect(() => BackupSnapshot.decode('{"format":"other"}'),
          throwsFormatException);
    });

    test('rejects a backup written by a newer format version', () {
      expect(
        () => BackupSnapshot.decode(
            '{"format":"change-backup","version":${BackupSnapshot.version + 1}}'),
        throwsFormatException,
      );
    });
  });

  group('database export / replace', () {
    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      DatabaseService.databaseName = 'backup_test.db';
      await DatabaseService.resetForTesting();
      final file =
          File(p.join(await getDatabasesPath(), DatabaseService.databaseName));
      if (file.existsSync()) file.deleteSync();
    });

    tearDownAll(DatabaseService.resetForTesting);

    test('a restore replaces local data with the backup', () async {
      final db = DatabaseService.instance;
      await db.insertShift(Shift(
          id: 'old', date: DateTime(2026, 9, 1), type: 'day'));
      final backup = await db.exportTables();

      // Local data changes after the backup was taken...
      await db.deleteAllData();
      await db.insertShift(Shift(
          id: 'new', date: DateTime(2026, 9, 2), type: 'night'));

      // ...and restoring brings back exactly the backed-up state.
      await db.replaceTables(
          BackupSnapshot.decode(BackupSnapshot(
            createdAt: DateTime.now(),
            tables: backup,
            prefs: const {},
          ).encode()).tables);

      final shifts = await db.getAllShifts();
      expect(shifts.map((s) => s.id), ['old']);
    });

    test('columns from a newer schema are ignored, not fatal', () async {
      final db = DatabaseService.instance;
      await db.replaceTables({
        'shifts': [
          {
            'id': 'x',
            'date': DateTime(2026, 9, 3).toIso8601String(),
            'type': 'off',
            'created_at': DateTime(2026, 9, 3).toIso8601String(),
            'swap_partner': 'future column',
          },
        ],
      });
      expect((await db.getAllShifts()).single.id, 'x');
    });
  });
}
