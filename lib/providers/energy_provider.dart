import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/energy_record.dart';
import '../services/database_service.dart';
import '../services/widget_service.dart';

const _uuid = Uuid();

class EnergyState {
  final List<EnergyRecord> records;
  final List<EnergyRecord> todayRecords;
  final Map<String, double> avgByShiftType;
  final bool isLoading;

  const EnergyState({
    this.records = const [],
    this.todayRecords = const [],
    this.avgByShiftType = const {},
    this.isLoading = false,
  });

  EnergyState copyWith({
    List<EnergyRecord>? records,
    List<EnergyRecord>? todayRecords,
    Map<String, double>? avgByShiftType,
    bool? isLoading,
  }) {
    return EnergyState(
      records: records ?? this.records,
      todayRecords: todayRecords ?? this.todayRecords,
      avgByShiftType: avgByShiftType ?? this.avgByShiftType,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  double get averageEnergy {
    if (records.isEmpty) return 0;
    final total = records.fold<int>(0, (sum, r) => sum + r.energyLevel);
    return total / records.length;
  }

  double get todayAverageEnergy {
    if (todayRecords.isEmpty) return 0;
    final total = todayRecords.fold<int>(0, (sum, r) => sum + r.energyLevel);
    return total / todayRecords.length;
  }

  EnergyRecord? get latestToday {
    if (todayRecords.isEmpty) return null;
    return todayRecords.last;
  }

  List<EnergyRecord> get last7Days {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return records
        .where((r) => r.date.isAfter(weekAgo))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  List<EnergyRecord> get last30Days {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    return records
        .where((r) => r.date.isAfter(monthAgo))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Returns daily average energy for the last N days, sorted by date
  List<MapEntry<DateTime, double>> get dailyAverages {
    final grouped = <String, List<int>>{};
    for (final r in records) {
      final key = r.date.toIso8601String().substring(0, 10);
      grouped.putIfAbsent(key, () => []).add(r.energyLevel);
    }
    final result = grouped.entries.map((e) {
      final date = DateTime.parse(e.key);
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return MapEntry(date, avg);
    }).toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return result;
  }
}

class EnergyNotifier extends StateNotifier<EnergyState> {
  final DatabaseService _db;

  EnergyNotifier(this._db) : super(const EnergyState());

  Future<void> loadRecords() async {
    state = state.copyWith(isLoading: true);
    final records = await _db.getEnergyRecords(limit: 500);
    final todayRecords = await _db.getEnergyRecordsForDate(DateTime.now());
    final avgByShift = await _db.getAverageEnergyByShiftType();

    state = state.copyWith(
      records: records,
      todayRecords: todayRecords,
      avgByShiftType: avgByShift,
      isLoading: false,
    );
    WidgetService.instance.updateEnergyData(
      latestLevel: state.latestToday?.energyLevel,
      averageEnergy: state.todayAverageEnergy,
    );
  }

  Future<void> addEnergyRecord({
    required int energyLevel,
    String? shiftType,
    String? activity,
    String? mood,
    String? note,
    String source = 'manual',
  }) async {
    final now = DateTime.now();
    final record = EnergyRecord(
      id: _uuid.v4(),
      date: DateTime(now.year, now.month, now.day),
      timestamp: now,
      energyLevel: energyLevel,
      shiftType: shiftType,
      activity: activity,
      mood: mood,
      note: note,
      source: source,
    );

    await _db.insertEnergyRecord(record);
    await loadRecords();
  }

  Future<void> deleteEnergyRecord(String id) async {
    await _db.deleteEnergyRecord(id);
    await loadRecords();
  }
}

final energyProvider =
    StateNotifierProvider<EnergyNotifier, EnergyState>((ref) {
  return EnergyNotifier(DatabaseService.instance);
});
