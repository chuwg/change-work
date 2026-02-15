class Shift {
  final String id;
  final DateTime date;
  final String type; // day, evening, night, off
  final String? startTime;
  final String? endTime;
  final String? note;
  final DateTime createdAt;

  Shift({
    required this.id,
    required this.date,
    required this.type,
    this.startTime,
    this.endTime,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type,
      'start_time': startTime,
      'end_time': endTime,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Shift.fromMap(Map<String, dynamic> map) {
    return Shift(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      type: map['type'] as String,
      startTime: map['start_time'] as String?,
      endTime: map['end_time'] as String?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Shift copyWith({
    String? id,
    DateTime? date,
    String? type,
    String? startTime,
    String? endTime,
    String? note,
  }) {
    return Shift(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }
}
