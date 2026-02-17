class EnergyRecord {
  final String id;
  final DateTime date;
  final DateTime timestamp;
  final int energyLevel; // 1-5
  final String? shiftType;
  final String? activity;
  final String? mood;
  final String? note;
  final String source; // 'manual' | 'quick'
  final DateTime createdAt;

  EnergyRecord({
    required this.id,
    required this.date,
    required this.timestamp,
    required this.energyLevel,
    this.shiftType,
    this.activity,
    this.mood,
    this.note,
    this.source = 'manual',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get timeOfDay {
    final hour = timestamp.hour;
    if (hour < 6) return 'dawn';
    if (hour < 12) return 'morning';
    if (hour < 18) return 'afternoon';
    return 'evening';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'timestamp': timestamp.toIso8601String(),
      'energy_level': energyLevel,
      'shift_type': shiftType,
      'activity': activity,
      'mood': mood,
      'note': note,
      'source': source,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EnergyRecord.fromMap(Map<String, dynamic> map) {
    return EnergyRecord(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      timestamp: DateTime.parse(map['timestamp'] as String),
      energyLevel: map['energy_level'] as int,
      shiftType: map['shift_type'] as String?,
      activity: map['activity'] as String?,
      mood: map['mood'] as String?,
      note: map['note'] as String?,
      source: (map['source'] as String?) ?? 'manual',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  EnergyRecord copyWith({
    DateTime? date,
    DateTime? timestamp,
    int? energyLevel,
    String? shiftType,
    String? activity,
    String? mood,
    String? note,
    String? source,
  }) {
    return EnergyRecord(
      id: id,
      date: date ?? this.date,
      timestamp: timestamp ?? this.timestamp,
      energyLevel: energyLevel ?? this.energyLevel,
      shiftType: shiftType ?? this.shiftType,
      activity: activity ?? this.activity,
      mood: mood ?? this.mood,
      note: note ?? this.note,
      source: source ?? this.source,
      createdAt: createdAt,
    );
  }
}
