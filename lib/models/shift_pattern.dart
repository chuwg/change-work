class ShiftPattern {
  final String id;
  final String name;
  final List<String> pattern; // e.g., ['day','day','night','night','off','off']
  final String? description;
  final bool isCustom;

  ShiftPattern({
    required this.id,
    required this.name,
    required this.pattern,
    this.description,
    this.isCustom = false,
  });

  int get cycleDays => pattern.length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'pattern': pattern.join(','),
      'description': description,
      'is_custom': isCustom ? 1 : 0,
    };
  }

  factory ShiftPattern.fromMap(Map<String, dynamic> map) {
    return ShiftPattern(
      id: map['id'] as String,
      name: map['name'] as String,
      pattern: (map['pattern'] as String).split(','),
      description: map['description'] as String?,
      isCustom: (map['is_custom'] as int) == 1,
    );
  }

  static List<ShiftPattern> presets = [
    ShiftPattern(
      id: 'preset_2shift',
      name: '2교대 (주/야)',
      pattern: ['day', 'day', 'night', 'night', 'off', 'off'],
      description: '주간 2일 → 야간 2일 → 휴무 2일',
    ),
    ShiftPattern(
      id: 'preset_3shift',
      name: '3교대',
      pattern: [
        'day', 'day', 'evening', 'evening', 'night', 'night', 'off', 'off',
      ],
      description: '주간 2일 → 오후 2일 → 야간 2일 → 휴무 2일',
    ),
    ShiftPattern(
      id: 'preset_alternate',
      name: '격일 근무',
      pattern: ['day', 'off'],
      description: '1일 근무 → 1일 휴무',
    ),
    ShiftPattern(
      id: 'preset_4team_2shift',
      name: '4조 2교대 (주휴야휴)',
      pattern: [
        'day', 'day', 'off', 'off',
        'night', 'night', 'off', 'off',
      ],
      description: '주간 2일 → 휴무 2일 → 야간 2일 → 휴무 2일',
    ),
    ShiftPattern(
      id: 'preset_4day',
      name: '4조 2교대 (장주기)',
      pattern: [
        'day', 'day', 'day', 'day', 'off', 'off',
        'night', 'night', 'night', 'night', 'off', 'off',
      ],
      description: '주간 4일 → 휴무 2일 → 야간 4일 → 휴무 2일',
    ),
    ShiftPattern(
      id: 'preset_nurse',
      name: '간호사 3교대',
      pattern: [
        'day', 'day', 'evening', 'evening', 'night', 'night', 'night',
        'off', 'off',
      ],
      description: '주간 2일 → 오후 2일 → 야간 3일 → 휴무 2일',
    ),
  ];
}
