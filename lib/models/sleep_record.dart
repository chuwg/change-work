class SleepRecord {
  final String id;
  final DateTime date;
  final DateTime bedTime;
  final DateTime wakeTime;
  final int quality; // 1-5
  final String? shiftType;
  final String? note;
  final String? source; // 'manual' | 'healthkit' | 'health_connect'
  final DateTime createdAt;

  SleepRecord({
    required this.id,
    required this.date,
    required this.bedTime,
    required this.wakeTime,
    required this.quality,
    this.shiftType,
    this.note,
    this.source,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Duration get duration => wakeTime.difference(bedTime);
  double get durationHours => duration.inMinutes / 60.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'bed_time': bedTime.toIso8601String(),
      'wake_time': wakeTime.toIso8601String(),
      'quality': quality,
      'shift_type': shiftType,
      'note': note,
      'source': source,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SleepRecord.fromMap(Map<String, dynamic> map) {
    return SleepRecord(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      bedTime: DateTime.parse(map['bed_time'] as String),
      wakeTime: DateTime.parse(map['wake_time'] as String),
      quality: map['quality'] as int,
      shiftType: map['shift_type'] as String?,
      note: map['note'] as String?,
      source: map['source'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  SleepRecord copyWith({
    DateTime? date,
    DateTime? bedTime,
    DateTime? wakeTime,
    int? quality,
    String? shiftType,
    String? note,
    String? source,
  }) {
    return SleepRecord(
      id: id,
      date: date ?? this.date,
      bedTime: bedTime ?? this.bedTime,
      wakeTime: wakeTime ?? this.wakeTime,
      quality: quality ?? this.quality,
      shiftType: shiftType ?? this.shiftType,
      note: note ?? this.note,
      source: source ?? this.source,
      createdAt: createdAt,
    );
  }
}
