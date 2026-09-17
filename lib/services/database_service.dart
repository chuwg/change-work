import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/shift.dart';
import '../models/shift_pattern.dart';
import '../models/sleep_record.dart';
import '../models/energy_record.dart';
import '../models/user_profile.dart';
import '../utils/constants.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService instance = DatabaseService._internal();

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  /// Database file name, overridable so each test file gets its own file.
  /// `flutter test` runs test files concurrently, and two suites sharing the
  /// app database would clobber each other's fixtures.
  @visibleForTesting
  static String databaseName = AppConstants.dbName;

  /// Drop the cached handle so a test can reopen against a different file.
  @visibleForTesting
  static Future<void> resetForTesting() async {
    await _database?.close();
    _database = null;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, databaseName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
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

    await db.execute('''
      CREATE TABLE shift_patterns (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        pattern TEXT NOT NULL,
        description TEXT,
        is_custom INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE sleep_records (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        bed_time TEXT NOT NULL,
        wake_time TEXT NOT NULL,
        quality INTEGER NOT NULL,
        shift_type TEXT,
        note TEXT,
        source TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY DEFAULT 1,
        name TEXT,
        birth_year INTEGER,
        gender TEXT,
        height_cm REAL,
        weight_kg REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE energy_records (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        energy_level INTEGER NOT NULL,
        shift_type TEXT,
        activity TEXT,
        mood TEXT,
        note TEXT,
        source TEXT DEFAULT 'manual',
        created_at TEXT NOT NULL
      )
    ''');

    // UNIQUE: one shift per date. Combined with ConflictAlgorithm.replace this
    // makes re-inserting a date overwrite the existing shift instead of adding
    // a second row (which used to leave the old shift alive in the DB).
    await db.execute(
      'CREATE UNIQUE INDEX idx_shifts_date ON shifts(date)',
    );
    await db.execute(
      'CREATE INDEX idx_sleep_date ON sleep_records(date)',
    );
    await db.execute(
      'CREATE INDEX idx_energy_date ON energy_records(date)',
    );
    await db.execute(
      'CREATE INDEX idx_energy_timestamp ON energy_records(timestamp)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE sleep_records ADD COLUMN source TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_profile (
          id INTEGER PRIMARY KEY DEFAULT 1,
          name TEXT,
          birth_year INTEGER,
          gender TEXT,
          height_cm REAL,
          weight_kg REAL
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS energy_records (
          id TEXT PRIMARY KEY,
          date TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          energy_level INTEGER NOT NULL,
          shift_type TEXT,
          activity TEXT,
          mood TEXT,
          note TEXT,
          source TEXT DEFAULT 'manual',
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_energy_date ON energy_records(date)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_energy_timestamp ON energy_records(timestamp)',
      );
    }
    if (oldVersion < 5) {
      // Shifts used to be keyed only by uuid, so editing a day inserted a
      // *second* row for the same date and the old shift kept being read back
      // (stale schedule -> stale notifications). Drop the leftovers, keeping
      // the most recently inserted row per date, then enforce one-per-date.
      await db.execute('''
        DELETE FROM shifts
        WHERE rowid NOT IN (SELECT MAX(rowid) FROM shifts GROUP BY date)
      ''');
      await db.execute('DROP INDEX IF EXISTS idx_shifts_date');
      await db.execute(
        'CREATE UNIQUE INDEX idx_shifts_date ON shifts(date)',
      );
    }
  }

  // === Shifts ===

  Future<void> insertShift(Shift shift) async {
    final db = await database;
    await db.insert('shifts', shift.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertShifts(List<Shift> shifts) async {
    final db = await database;
    final batch = db.batch();
    for (final shift in shifts) {
      batch.insert('shifts', shift.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Shift>> getShiftsForMonth(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    final maps = await db.query(
      'shifts',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC, created_at ASC',
    );

    return maps.map((m) => Shift.fromMap(m)).toList();
  }

  /// Every stored shift, past and future. Used for backups, where a monthly
  /// window would silently drop schedules entered ahead of time.
  Future<List<Shift>> getAllShifts() async {
    final db = await database;
    final maps = await db.query('shifts', orderBy: 'date ASC');
    return maps.map((m) => Shift.fromMap(m)).toList();
  }

  Future<Shift?> getShiftForDate(DateTime date) async {
    final db = await database;
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String();

    final maps = await db.query(
      'shifts',
      where: 'date = ?',
      whereArgs: [dateStr],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Shift.fromMap(maps.first);
  }

  Future<void> deleteShift(String id) async {
    final db = await database;
    await db.delete('shifts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateShiftTimesForType(
      String type, String startTime, String endTime) async {
    final db = await database;
    await db.update(
      'shifts',
      {'start_time': startTime, 'end_time': endTime},
      where: 'type = ?',
      whereArgs: [type],
    );
  }

  Future<void> deleteShiftsInRange(DateTime start, DateTime end) async {
    final db = await database;
    await db.delete(
      'shifts',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );
  }

  // === Shift Patterns ===

  Future<void> saveShiftPattern(ShiftPattern pattern) async {
    final db = await database;
    await db.insert('shift_patterns', pattern.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ShiftPattern>> getCustomPatterns() async {
    final db = await database;
    final maps = await db.query(
      'shift_patterns',
      where: 'is_custom = 1',
    );
    return maps.map((m) => ShiftPattern.fromMap(m)).toList();
  }

  // === Sleep Records ===

  Future<void> insertSleepRecord(SleepRecord record) async {
    final db = await database;
    await db.insert('sleep_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SleepRecord>> getSleepRecords({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (startDate != null && endDate != null) {
      where = 'date BETWEEN ? AND ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    }

    final maps = await db.query(
      'sleep_records',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
      limit: limit,
    );

    return maps.map((m) => SleepRecord.fromMap(m)).toList();
  }

  /// Every sleep session filed under [date], longest first.
  ///
  /// A day can hold more than one: shift workers sleep after a night shift and
  /// again before the next one.
  Future<List<SleepRecord>> getSleepRecordsForDate(DateTime date) async {
    final db = await database;
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String();

    final maps = await db.query(
      'sleep_records',
      where: 'date = ?',
      whereArgs: [dateStr],
    );

    final records = maps.map((m) => SleepRecord.fromMap(m)).toList()
      ..sort((a, b) => b.duration.compareTo(a.duration));
    return records;
  }

  /// The main (longest) sleep session for [date].
  /// Use [getSleepRecordsForDate] when the day's *total* is what matters.
  Future<SleepRecord?> getSleepRecordForDate(DateTime date) async {
    final records = await getSleepRecordsForDate(date);
    if (records.isEmpty) return null;
    return records.first;
  }

  Future<void> deleteSleepRecord(String id) async {
    final db = await database;
    await db.delete('sleep_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, double>> getAverageSleepByShiftType() async {
    final db = await database;
    // Sum each day first, then average the days. Averaging raw rows would
    // count a 90-minute nap as a full day of sleep and drag the figure down
    // for exactly the shift patterns that produce split sleep.
    final result = await db.rawQuery('''
      SELECT shift_type, AVG(day_hours) as avg_hours
      FROM (
        SELECT shift_type, date,
          SUM((julianday(wake_time) - julianday(bed_time)) * 24) as day_hours
        FROM sleep_records
        WHERE shift_type IS NOT NULL
        GROUP BY shift_type, date
      )
      GROUP BY shift_type
    ''');

    final map = <String, double>{};
    for (final row in result) {
      final type = row['shift_type'] as String;
      final avg = row['avg_hours'] as double;
      map[type] = avg;
    }
    return map;
  }

  // === Energy Records ===

  Future<void> insertEnergyRecord(EnergyRecord record) async {
    final db = await database;
    await db.insert('energy_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<EnergyRecord>> getEnergyRecords({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (startDate != null && endDate != null) {
      where = 'date BETWEEN ? AND ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    }

    final maps = await db.query(
      'energy_records',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((m) => EnergyRecord.fromMap(m)).toList();
  }

  Future<List<EnergyRecord>> getEnergyRecordsForDate(DateTime date) async {
    final db = await database;
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String();

    final maps = await db.query(
      'energy_records',
      where: 'date = ?',
      whereArgs: [dateStr],
      orderBy: 'timestamp ASC',
    );

    return maps.map((m) => EnergyRecord.fromMap(m)).toList();
  }

  Future<void> deleteEnergyRecord(String id) async {
    final db = await database;
    await db.delete('energy_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, double>> getAverageEnergyByShiftType() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT shift_type, AVG(energy_level) as avg_energy
      FROM energy_records
      WHERE shift_type IS NOT NULL
      GROUP BY shift_type
    ''');

    final map = <String, double>{};
    for (final row in result) {
      final type = row['shift_type'] as String;
      final avg = (row['avg_energy'] as num).toDouble();
      map[type] = avg;
    }
    return map;
  }

  // === User Profile ===

  Future<UserProfile?> getUserProfile() async {
    final db = await database;
    final maps = await db.query('user_profile', where: 'id = 1', limit: 1);
    if (maps.isEmpty) return null;
    return UserProfile.fromMap(maps.first);
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final db = await database;
    final data = profile.toMap();
    data['id'] = 1;
    await db.insert('user_profile', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // === Data Management ===

  /// Tables carried by a full backup, in restore order.
  static const List<String> backupTables = [
    'shifts',
    'shift_patterns',
    'sleep_records',
    'energy_records',
    'user_settings',
    'user_profile',
  ];

  /// Every row of every backed-up table, as plain column maps.
  Future<Map<String, List<Map<String, Object?>>>> exportTables() async {
    final db = await database;
    return {
      for (final table in backupTables)
        table: (await db.query(table))
            .map((row) => Map<String, Object?>.from(row))
            .toList(),
    };
  }

  /// Replace the backed-up tables with [data] in one transaction, so a failed
  /// restore leaves the current data untouched.
  ///
  /// Columns this schema does not know are dropped rather than failing the
  /// insert — a backup from a newer app version still restores what it can.
  Future<void> replaceTables(
      Map<String, List<Map<String, Object?>>> data) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final table in backupTables) {
        final rows = data[table];
        if (rows == null) continue;
        final columns = (await txn.rawQuery('PRAGMA table_info($table)'))
            .map((c) => c['name'] as String)
            .toSet();
        await txn.delete(table);
        for (final row in rows) {
          final filtered = Map<String, Object?>.fromEntries(
              row.entries.where((e) => columns.contains(e.key)));
          if (filtered.isEmpty) continue;
          await txn.insert(table, filtered,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }

  Future<void> deleteAllData() async {
    final db = await database;
    await db.delete('shifts');
    await db.delete('sleep_records');
    await db.delete('energy_records');
    await db.delete('user_settings');
  }

  // === Settings ===

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'user_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query(
      'user_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first['value'] as String;
  }
}
