import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/shift.dart';
import '../models/shift_pattern.dart';
import '../models/sleep_record.dart';
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

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

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

    await db.execute(
      'CREATE INDEX idx_shifts_date ON shifts(date)',
    );
    await db.execute(
      'CREATE INDEX idx_sleep_date ON sleep_records(date)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE sleep_records ADD COLUMN source TEXT');
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
      orderBy: 'date ASC',
    );

    return maps.map((m) => Shift.fromMap(m)).toList();
  }

  Future<Shift?> getShiftForDate(DateTime date) async {
    final db = await database;
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String();

    final maps = await db.query(
      'shifts',
      where: 'date = ?',
      whereArgs: [dateStr],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Shift.fromMap(maps.first);
  }

  Future<void> deleteShift(String id) async {
    final db = await database;
    await db.delete('shifts', where: 'id = ?', whereArgs: [id]);
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

  Future<SleepRecord?> getSleepRecordForDate(DateTime date) async {
    final db = await database;
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String();

    final maps = await db.query(
      'sleep_records',
      where: 'date = ?',
      whereArgs: [dateStr],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return SleepRecord.fromMap(maps.first);
  }

  Future<void> deleteSleepRecord(String id) async {
    final db = await database;
    await db.delete('sleep_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, double>> getAverageSleepByShiftType() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT shift_type,
        AVG(
          (julianday(wake_time) - julianday(bed_time)) * 24
        ) as avg_hours
      FROM sleep_records
      WHERE shift_type IS NOT NULL
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

  // === Data Management ===

  Future<void> deleteAllData() async {
    final db = await database;
    await db.delete('shifts');
    await db.delete('sleep_records');
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
