import '../models/health_tip.dart';
import '../models/sleep_record.dart';
import '../providers/health_provider.dart';
import '../utils/constants.dart';

/// Shift schedule with actual start/end times.
class ShiftSchedule {
  final String type;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  const ShiftSchedule({
    required this.type,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  String get startTimeStr =>
      '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
  String get endTimeStr =>
      '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

  /// Recommended bedtime: shift start - 8 hours.
  int get recommendedBedHour => (startHour - 8 + 24) % 24;

  /// Recommended wake time: shift start - 1 hour.
  int get recommendedWakeHour => (startHour - 1 + 24) % 24;

  /// Caffeine cutoff: recommended bedtime - 6 hours.
  int get caffeineCutoffHour => (recommendedBedHour - 6 + 24) % 24;

  /// Last meal: recommended bedtime - 2 hours.
  int get lastMealHour => (recommendedBedHour - 2 + 24) % 24;

  /// Nap time for night shift: shift start - 3h to start - 1.5h.
  int get napStartHour => (startHour - 3 + 24) % 24;
  int get napEndHour => (startHour - 1 + 24) % 24;

  String _formatHour(int h) => '${h.toString().padLeft(2, '0')}:00';

  String get recommendedBedTimeStr => _formatHour(recommendedBedHour);
  String get recommendedWakeTimeStr => _formatHour(recommendedWakeHour);
  String get caffeineCutoffStr => _formatHour(caffeineCutoffHour);
  String get lastMealStr => _formatHour(lastMealHour);
  String get napTimeStr =>
      '${_formatHour(napStartHour)}-${napEndHour.toString().padLeft(2, '0')}:30';

  /// Default schedule when no actual times are available.
  factory ShiftSchedule.defaultForType(String type) {
    final times = AppConstants.defaultShiftTimes[type];
    if (times != null) {
      final startParts = times['start']!.split(':');
      final endParts = times['end']!.split(':');
      return ShiftSchedule(
        type: type,
        startHour: int.parse(startParts[0]),
        startMinute: int.parse(startParts[1]),
        endHour: int.parse(endParts[0]),
        endMinute: int.parse(endParts[1]),
      );
    }
    // Off day defaults
    return ShiftSchedule(
      type: type,
      startHour: 9,
      startMinute: 0,
      endHour: 17,
      endMinute: 0,
    );
  }

  factory ShiftSchedule.fromTimeStrings(
      String type, String startTime, String endTime) {
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    return ShiftSchedule(
      type: type,
      startHour: int.parse(startParts[0]),
      startMinute: int.parse(startParts[1]),
      endHour: int.parse(endParts[0]),
      endMinute: int.parse(endParts[1]),
    );
  }
}

class AiHealthService {
  List<HealthTip> generateTips({
    required String currentShiftType,
    required double averageSleepHours,
    required double averageSleepQuality,
    ShiftSchedule? schedule,
    int? userAge,
  }) {
    final sched = schedule ?? ShiftSchedule.defaultForType(currentShiftType);
    final tips = <HealthTip>[];
    final now = DateTime.now();
    final hour = now.hour;

    tips.addAll(_getSleepTips(sched, averageSleepHours, userAge));
    tips.addAll(_getMealTips(sched, hour));
    tips.addAll(_getExerciseTips(sched, hour));
    tips.addAll(_getCaffeineTips(sched, hour));
    tips.addAll(_getLightTips(sched, hour));

    tips.sort((a, b) => a.priority.compareTo(b.priority));
    return tips;
  }

  List<HealthTip> _getSleepTips(
      ShiftSchedule sched, double avgHours, int? userAge) {
    final tips = <HealthTip>[];
    final type = sched.type;

    // Recommended sleep hours based on age
    final targetHours = _targetSleepHours(userAge);

    if (type == AppConstants.shiftNight) {
      tips.add(HealthTip(
        id: 'sleep_night_1',
        category: AppConstants.tipSleep,
        title: '야간 근무 후 수면 가이드',
        description:
            '퇴근(${sched.endTimeStr}) 후 바로 수면을 취하세요. '
            '암막 커튼과 수면 안대를 사용하고, '
            '실내 온도를 18-20°C로 유지하면 깊은 수면에 도움됩니다.',
        shiftType: type,
        timing: '${sched.endTimeStr} 퇴근 후',
        priority: 1,
      ));
      tips.add(HealthTip(
        id: 'sleep_night_2',
        category: AppConstants.tipSleep,
        title: '분할 수면 전략',
        description:
            '야간 근무자는 주 수면(4-5시간) + 보조 낮잠(1.5-2시간) '
            '분할 수면이 효과적입니다. '
            '출근 전 ${sched.napTimeStr}에 낮잠으로 각성도를 높이세요.',
        shiftType: type,
        timing: '낮잠 ${sched.napTimeStr}',
        priority: 2,
      ));
    } else if (type == AppConstants.shiftEvening) {
      tips.add(HealthTip(
        id: 'sleep_evening_1',
        category: AppConstants.tipSleep,
        title: '저녁 근무 수면 패턴',
        description:
            '퇴근(${sched.endTimeStr}) 후 1시간 릴랙스 후 수면하세요. '
            '권장 취침: ${sched.recommendedBedTimeStr}, '
            '기상: ${sched.recommendedWakeTimeStr}',
        shiftType: type,
        timing: '${sched.recommendedBedTimeStr}~${sched.recommendedWakeTimeStr}',
        priority: 1,
      ));
    } else if (type == AppConstants.shiftDay) {
      tips.add(HealthTip(
        id: 'sleep_day_1',
        category: AppConstants.tipSleep,
        title: '주간 근무 수면 최적화',
        description:
            '${sched.recommendedBedTimeStr}에 잠자리에 드세요. '
            '취침 1시간 전 블루라이트를 차단하고, '
            '${sched.recommendedWakeTimeStr} 기상을 유지하면 서카디안 리듬이 안정됩니다.',
        shiftType: type,
        timing: '${sched.recommendedBedTimeStr}~${sched.recommendedWakeTimeStr}',
        priority: 1,
      ));
    } else {
      // Off day
      tips.add(HealthTip(
        id: 'sleep_off_1',
        category: AppConstants.tipSleep,
        title: '휴무일 수면 리듬 유지',
        description:
            '휴무일에도 평소 기상 시간과 1시간 이상 차이나지 않도록 하세요. '
            '주말 몰아자기는 서카디안 리듬을 깨뜨립니다.',
        shiftType: type,
        priority: 2,
      ));
    }

    if (avgHours > 0 && avgHours < targetHours - 1) {
      tips.add(HealthTip(
        id: 'sleep_warning',
        category: AppConstants.tipSleep,
        title: '수면 부족 경고',
        description:
            '최근 평균 수면 시간이 ${avgHours.toStringAsFixed(1)}시간입니다. '
            '${userAge != null && userAge >= 65 ? "65세 이상은 최소 ${targetHours.toStringAsFixed(0)}시간" : "최소 ${targetHours.toStringAsFixed(0)}시간"} 수면을 목표로 하세요.',
        shiftType: type,
        priority: 1,
      ));
    }

    return tips;
  }

  double _targetSleepHours(int? age) {
    if (age == null) return 7.0;
    if (age <= 25) return 8.0;
    if (age <= 64) return 7.0;
    return 7.0; // 65+
  }

  List<HealthTip> _getMealTips(ShiftSchedule sched, int currentHour) {
    final tips = <HealthTip>[];
    final type = sched.type;

    if (type == AppConstants.shiftNight) {
      // Mid-shift meal: halfway through the shift
      final midShiftHour = (sched.startHour + 4) % 24;
      tips.add(HealthTip(
        id: 'meal_night_1',
        category: AppConstants.tipMeal,
        title: '야간 근무 식사 전략',
        description:
            '근무 중 ${midShiftHour.toString().padLeft(2, '0')}:00경 가벼운 식사를 하세요. '
            '고탄수화물 음식은 피하고, 단백질 위주의 가벼운 식사가 좋습니다.',
        shiftType: type,
        timing: '${midShiftHour.toString().padLeft(2, '0')}:00',
        priority: 2,
      ));
    } else if (type == AppConstants.shiftEvening) {
      tips.add(HealthTip(
        id: 'meal_evening_1',
        category: AppConstants.tipMeal,
        title: '저녁 근무 식사 가이드',
        description:
            '출근 전 충분한 식사를 하세요. '
            '마지막 식사는 ${sched.lastMealStr}까지 마치세요.',
        shiftType: type,
        timing: '마지막 식사 ${sched.lastMealStr}',
        priority: 2,
      ));
    } else if (type == AppConstants.shiftDay) {
      final breakfastHour = sched.recommendedWakeHour;
      final lunchHour = (sched.startHour + 6) % 24; // ~6h into shift
      tips.add(HealthTip(
        id: 'meal_day_1',
        category: AppConstants.tipMeal,
        title: '규칙적 식사 리마인더',
        description:
            '아침(${breakfastHour.toString().padLeft(2, '0')}:00), '
            '점심(${lunchHour.toString().padLeft(2, '0')}:00), '
            '저녁(${sched.lastMealStr}) 규칙적인 식사를 유지하세요.',
        shiftType: type,
        timing:
            '${breakfastHour.toString().padLeft(2, '0')}:00, ${lunchHour.toString().padLeft(2, '0')}:00, ${sched.lastMealStr}',
        priority: 3,
      ));
    }

    return tips;
  }

  List<HealthTip> _getExerciseTips(ShiftSchedule sched, int currentHour) {
    final tips = <HealthTip>[];
    final type = sched.type;

    if (type == AppConstants.shiftOff) {
      tips.add(HealthTip(
        id: 'exercise_off_1',
        category: AppConstants.tipExercise,
        title: '휴무일 운동 추천',
        description:
            '30-40분 유산소 운동으로 체력을 회복하세요. '
            '야외 운동으로 햇빛을 충분히 쬐면 서카디안 리듬 회복에 도움됩니다.',
        shiftType: type,
        timing: '오전 10시-오후 2시',
        priority: 2,
      ));
    } else {
      // Exercise after shift, before bed - 3 hours
      final exerciseStart = (sched.endHour + 1) % 24;
      final exerciseEnd = (sched.recommendedBedHour - 3 + 24) % 24;
      tips.add(HealthTip(
        id: 'exercise_${type}_1',
        category: AppConstants.tipExercise,
        title: '운동 추천 시간',
        description:
            '퇴근 후 ${exerciseStart.toString().padLeft(2, '0')}:00~'
            '${exerciseEnd.toString().padLeft(2, '0')}:00 사이에 운동하세요. '
            '취침 3시간 전까지 마쳐야 수면에 방해가 되지 않습니다.',
        shiftType: type,
        timing:
            '${exerciseStart.toString().padLeft(2, '0')}:00~${exerciseEnd.toString().padLeft(2, '0')}:00',
        priority: 3,
      ));
    }

    return tips;
  }

  List<HealthTip> _getCaffeineTips(ShiftSchedule sched, int currentHour) {
    final tips = <HealthTip>[];
    final type = sched.type;

    if (type == AppConstants.shiftOff) return tips;

    // Always show caffeine cutoff based on actual schedule
    final cutoff = sched.caffeineCutoffHour;
    final isCutoffPassed = _isHourPassed(currentHour, cutoff);

    if (isCutoffPassed) {
      tips.add(HealthTip(
        id: 'caffeine_cutoff',
        category: AppConstants.tipCaffeine,
        title: '카페인 컷오프 시간 경과',
        description:
            '${cutoff.toString().padLeft(2, '0')}:00 이후입니다. '
            '카페인 섭취를 자제하세요. '
            '카페인 반감기(5-6시간)를 고려하면 수면에 방해됩니다. '
            '대신 물이나 허브차를 마시세요.',
        shiftType: type,
        timing: '${cutoff.toString().padLeft(2, '0')}:00 이후 금지',
        priority: 2,
      ));
    } else {
      tips.add(HealthTip(
        id: 'caffeine_ok',
        category: AppConstants.tipCaffeine,
        title: '카페인 섭취 가능 시간',
        description:
            '${cutoff.toString().padLeft(2, '0')}:00까지 카페인 섭취가 가능합니다. '
            '근무 시작 시 커피 한 잔으로 각성도를 높이세요.',
        shiftType: type,
        timing: '${cutoff.toString().padLeft(2, '0')}:00까지',
        priority: 3,
      ));
    }

    return tips;
  }

  bool _isHourPassed(int current, int target) {
    // Simple check: if target is e.g. 14 and current is 15, passed.
    // Handle overnight wrap: if target is 3 (night shift cutoff)
    // and current is 4, passed.
    return current >= target && (current - target) < 12;
  }

  List<HealthTip> _getLightTips(ShiftSchedule sched, int currentHour) {
    final tips = <HealthTip>[];
    final type = sched.type;

    if (type == AppConstants.shiftNight) {
      tips.add(HealthTip(
        id: 'light_night_1',
        category: AppConstants.tipLight,
        title: '빛 노출 관리 (야간)',
        description:
            '퇴근(${sched.endTimeStr}) 시 선글라스를 착용해 햇빛을 차단하세요. '
            '암막 커튼으로 수면 환경을 조성하고, '
            '출근 전 15분간 밝은 빛에 노출되면 각성에 도움됩니다.',
        shiftType: type,
        timing: '퇴근 시 차단, 출근 전 노출',
        priority: 1,
      ));
    } else if (type != AppConstants.shiftOff) {
      tips.add(HealthTip(
        id: 'light_${type}_1',
        category: AppConstants.tipLight,
        title: '아침 햇빛 노출',
        description:
            '기상(${sched.recommendedWakeTimeStr}) 후 30분 이내에 15-30분 햇빛을 쬐세요. '
            '멜라토닌 분비를 억제하고 서카디안 리듬을 안정시킵니다.',
        shiftType: type,
        timing: '${sched.recommendedWakeTimeStr} 기상 후 30분 이내',
        priority: 2,
      ));
    }

    return tips;
  }

  /// Get current circadian phase based on actual shift schedule.
  CircadianPhase getCurrentCircadianPhase({
    required String shiftType,
    ShiftSchedule? schedule,
  }) {
    final sched = schedule ?? ShiftSchedule.defaultForType(shiftType);
    final hour = DateTime.now().hour;
    final bedH = sched.recommendedBedHour;
    final wakeH = sched.recommendedWakeHour;

    if (_inHourRange(hour, bedH, (bedH + 2) % 24)) return CircadianPhase.sleep;
    if (_inHourRange(hour, (bedH + 2) % 24, (bedH + 5) % 24)) {
      return CircadianPhase.deepSleep;
    }
    if (_inHourRange(hour, (wakeH - 1 + 24) % 24, wakeH)) {
      return CircadianPhase.waking;
    }
    if (_inHourRange(hour, wakeH, (wakeH + 3) % 24)) {
      return CircadianPhase.alert;
    }

    // During work: active
    if (_inHourRange(hour, sched.startHour, sched.endHour)) {
      return CircadianPhase.active;
    }

    // 2 hours before bed: drowsy
    if (_inHourRange(hour, (bedH - 2 + 24) % 24, bedH)) {
      return CircadianPhase.drowsy;
    }

    return CircadianPhase.alert;
  }

  bool _inHourRange(int hour, int start, int end) {
    if (start <= end) {
      return hour >= start && hour < end;
    }
    // Wraps around midnight
    return hour >= start || hour < end;
  }

  double calculateCircadianScore({
    required String shiftType,
    required List<SleepRecord> sleepRecords,
  }) {
    if (sleepRecords.isEmpty) return 50.0;

    double score = 50.0;

    final avgHours = sleepRecords.fold<double>(
            0, (sum, r) => sum + r.durationHours) /
        sleepRecords.length;

    if (avgHours >= 7 && avgHours <= 9) {
      score += 20;
    } else if (avgHours >= 6) {
      score += 10;
    } else {
      score -= 10;
    }

    final avgQuality = sleepRecords.fold<int>(
            0, (sum, r) => sum + r.quality) /
        sleepRecords.length;
    score += (avgQuality - 3) * 10;

    if (sleepRecords.length >= 3) {
      final bedTimeMinutes = sleepRecords
          .map((r) => r.bedTime.hour * 60 + r.bedTime.minute)
          .toList();
      final avgBedTime =
          bedTimeMinutes.reduce((a, b) => a + b) / bedTimeMinutes.length;
      final variance = bedTimeMinutes
              .map((m) => (m - avgBedTime) * (m - avgBedTime))
              .reduce((a, b) => a + b) /
          bedTimeMinutes.length;

      if (variance < 900) {
        score += 15;
      } else if (variance < 3600) {
        score += 5;
      } else {
        score -= 5;
      }
    }

    return score.clamp(0, 100);
  }

  /// Get recommended sleep times based on actual shift schedule.
  Map<String, String> getRecommendedSleepTimes({
    required String shiftType,
    ShiftSchedule? schedule,
  }) {
    final sched = schedule ?? ShiftSchedule.defaultForType(shiftType);
    final result = <String, String>{
      'bedTime': sched.recommendedBedTimeStr,
      'wakeTime': sched.recommendedWakeTimeStr,
    };

    if (shiftType == AppConstants.shiftNight) {
      result['napTime'] = sched.napTimeStr;
    }

    return result;
  }

  /// Generate 24-hour phase timeline for the circadian screen.
  List<Map<String, dynamic>> generatePhaseTimeline({
    required String shiftType,
    ShiftSchedule? schedule,
  }) {
    final sched = schedule ?? ShiftSchedule.defaultForType(shiftType);
    final bedH = sched.recommendedBedHour;
    final wakeH = sched.recommendedWakeHour;
    final phases = <Map<String, dynamic>>[];

    for (int h = 0; h < 24; h++) {
      CircadianPhase phase;
      if (_inHourRange(h, bedH, (bedH + 2) % 24)) {
        phase = CircadianPhase.sleep;
      } else if (_inHourRange(h, (bedH + 2) % 24, (wakeH - 1 + 24) % 24)) {
        phase = CircadianPhase.deepSleep;
      } else if (_inHourRange(h, (wakeH - 1 + 24) % 24, wakeH)) {
        phase = CircadianPhase.waking;
      } else if (_inHourRange(h, wakeH, (wakeH + 3) % 24)) {
        phase = CircadianPhase.alert;
      } else if (_inHourRange(h, sched.startHour, sched.endHour)) {
        phase = CircadianPhase.active;
      } else if (_inHourRange(h, (bedH - 2 + 24) % 24, bedH)) {
        phase = CircadianPhase.drowsy;
      } else {
        phase = CircadianPhase.alert;
      }

      phases.add({
        'hour': h,
        'phase': phase,
      });
    }

    return phases;
  }
}
