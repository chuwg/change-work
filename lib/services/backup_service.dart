import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';
import 'database_service.dart';

/// A decoded backup: the database rows plus the settings worth carrying to a
/// new phone.
class BackupSnapshot {
  static const String format = 'change-backup';
  static const int version = 1;

  final DateTime createdAt;
  final Map<String, List<Map<String, Object?>>> tables;
  final Map<String, Object> prefs;

  const BackupSnapshot({
    required this.createdAt,
    required this.tables,
    required this.prefs,
  });

  int count(String table) => tables[table]?.length ?? 0;

  /// Shifts, sleep and energy — whether there is anything worth keeping.
  int get recordCount =>
      count('shifts') + count('sleep_records') + count('energy_records');

  String encode() => jsonEncode({
        'format': format,
        'version': version,
        'createdAt': createdAt.toIso8601String(),
        'tables': tables,
        'prefs': prefs,
      });

  /// Throws [FormatException] for anything that is not a backup this version
  /// can read.
  static BackupSnapshot decode(String source) {
    final Object? json;
    try {
      json = jsonDecode(source);
    } catch (_) {
      throw const FormatException('not JSON');
    }
    if (json is! Map || json['format'] != format) {
      throw const FormatException('not a Change backup');
    }
    final v = json['version'];
    if (v is! int || v > version) {
      throw const FormatException('backup from a newer app version');
    }

    final tables = <String, List<Map<String, Object?>>>{};
    final rawTables = json['tables'];
    if (rawTables is Map) {
      rawTables.forEach((name, rows) {
        if (name is String && rows is List) {
          tables[name] = rows
              .whereType<Map>()
              .map((r) => r.map((k, v) => MapEntry(k.toString(), v as Object?)))
              .toList();
        }
      });
    }

    final prefs = <String, Object>{};
    final rawPrefs = json['prefs'];
    if (rawPrefs is Map) {
      rawPrefs.forEach((k, v) {
        if (k is String && (v is bool || v is num || v is String)) {
          prefs[k] = v as Object;
        }
      });
    }

    return BackupSnapshot(
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      tables: tables,
      prefs: prefs,
    );
  }
}

/// Automatic backup of all app data to the app's iCloud Drive folder.
class BackupService {
  static final BackupService instance = BackupService._();
  BackupService._();

  static const _channel = MethodChannel('com.change.app/icloud');
  static const String fileName = 'change-backup.json';
  static const String _lastBackupDayKey = 'icloud_backup_last_day';

  /// Settings that describe the user's setup and belong on a new phone.
  /// Device state (permissions, sync bookkeeping, calendar link) stays out.
  static const List<String> backedUpPrefs = [
    AppConstants.customShiftTimesKey,
    AppConstants.sleepReminderKey,
    AppConstants.shiftReminderKey,
    AppConstants.reminderMinutesKey,
    AppConstants.recoveryGuideKey,
    AppConstants.motivationEnabledKey,
    AppConstants.motivationHourKey,
    AppConstants.motivationMinuteKey,
    AppConstants.salarySettingsKey,
    'theme_mode',
  ];

  Timer? _debounce;
  bool _running = false;

  bool get isSupported => !kIsWeb && Platform.isIOS;

  Future<bool> isEnabled() async {
    if (!isSupported) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.icloudBackupKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.icloudBackupKey, value);
    if (value) await backupNow();
  }

  Future<bool> isAvailable() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<DateTime?> lastBackupAt() async {
    if (!isSupported) return null;
    try {
      final ms = await _channel.invokeMethod<int>('modifiedAt', {'name': fileName});
      return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (_) {
      return null;
    }
  }

  /// Back up a little after a burst of schedule edits.
  void scheduleBackup() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 20), () async {
      if (await isEnabled()) await backupNow();
    });
  }

  /// Once a day on launch/resume, so sleep and energy records are covered too.
  Future<void> backupIfStale() async {
    if (!await isEnabled()) return;
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (prefs.getString(_lastBackupDayKey) == today) return;
    await backupNow();
  }

  /// Returns true when a backup was written.
  Future<bool> backupNow() async {
    if (!isSupported || _running) return false;
    _running = true;
    try {
      if (!await isAvailable()) return false;
      final snapshot = await _capture();

      // A fresh install (or a reset) has nothing in it. Writing that would
      // replace the user's real backup with an empty one — exactly the data
      // loss backup exists to prevent. Only an existing backup that is also
      // empty may be overwritten by an empty one.
      if (snapshot.recordCount == 0) {
        final existing = await fetch();
        if (existing != null && existing.recordCount > 0) return false;
      }

      await _channel.invokeMethod<bool>('write', {
        'name': fileName,
        'contents': snapshot.encode(),
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _lastBackupDayKey, DateFormat('yyyy-MM-dd').format(DateTime.now()));
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[Backup] failed: $e');
      return false;
    } finally {
      _running = false;
    }
  }

  /// The backup in iCloud, or null when there is none (or it is unreadable).
  Future<BackupSnapshot?> fetch() async {
    if (!isSupported) return null;
    try {
      final raw = await _channel.invokeMethod<String>('read', {'name': fileName});
      if (raw == null || raw.isEmpty) return null;
      return BackupSnapshot.decode(raw);
    } catch (e) {
      if (kDebugMode) debugPrint('[Backup] fetch failed: $e');
      return null;
    }
  }

  /// Replace local data with [snapshot]. Callers reload their providers.
  Future<void> restore(BackupSnapshot snapshot) async {
    await DatabaseService.instance.replaceTables(snapshot.tables);
    final prefs = await SharedPreferences.getInstance();
    for (final entry in snapshot.prefs.entries) {
      if (!backedUpPrefs.contains(entry.key)) continue;
      final v = entry.value;
      if (v is bool) {
        await prefs.setBool(entry.key, v);
      } else if (v is int) {
        await prefs.setInt(entry.key, v);
      } else if (v is double) {
        await prefs.setDouble(entry.key, v);
      } else if (v is String) {
        await prefs.setString(entry.key, v);
      }
    }
  }

  Future<BackupSnapshot> _capture() async {
    final prefs = await SharedPreferences.getInstance();
    final values = <String, Object>{};
    for (final key in backedUpPrefs) {
      final v = prefs.get(key);
      if (v is bool || v is num || v is String) values[key] = v!;
    }
    return BackupSnapshot(
      createdAt: DateTime.now(),
      tables: await DatabaseService.instance.exportTables(),
      prefs: values,
    );
  }
}
