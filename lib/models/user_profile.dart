class UserProfile {
  final String? name;
  final int? birthYear;
  final String? gender; // male, female, other
  final double? heightCm;
  final double? weightKg;

  const UserProfile({
    this.name,
    this.birthYear,
    this.gender,
    this.heightCm,
    this.weightKg,
  });

  int? get age {
    if (birthYear == null) return null;
    return DateTime.now().year - birthYear!;
  }

  double? get bmi {
    if (heightCm == null || weightKg == null) return null;
    final heightM = heightCm! / 100;
    return weightKg! / (heightM * heightM);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'birth_year': birthYear,
      'gender': gender,
      'height_cm': heightCm,
      'weight_kg': weightKg,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] as String?,
      birthYear: map['birth_year'] as int?,
      gender: map['gender'] as String?,
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
    );
  }

  UserProfile copyWith({
    String? name,
    int? birthYear,
    String? gender,
    double? heightCm,
    double? weightKg,
    bool clearName = false,
  }) {
    return UserProfile(
      name: clearName ? null : (name ?? this.name),
      birthYear: birthYear ?? this.birthYear,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
    );
  }
}
