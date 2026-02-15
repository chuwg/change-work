class HealthTip {
  final String id;
  final String category; // sleep, meal, exercise, caffeine, light
  final String title;
  final String description;
  final String shiftType;
  final String? timing;
  final int priority; // 1=highest

  HealthTip({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.shiftType,
    this.timing,
    this.priority = 3,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'title': title,
      'description': description,
      'shift_type': shiftType,
      'timing': timing,
      'priority': priority,
    };
  }

  factory HealthTip.fromMap(Map<String, dynamic> map) {
    return HealthTip(
      id: map['id'] as String,
      category: map['category'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      shiftType: map['shift_type'] as String,
      timing: map['timing'] as String?,
      priority: map['priority'] as int? ?? 3,
    );
  }
}
