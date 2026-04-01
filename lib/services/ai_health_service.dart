import '../models/health_tip.dart';
import '../models/sleep_record.dart';
import '../models/energy_record.dart';
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
    double averageEnergy = 0,
    ShiftSchedule? schedule,
    int? userAge,
    SleepRecord? yesterdaySleep,
    List<SleepRecord> recentSleep = const [],
    List<EnergyRecord> recentEnergy = const [],
    int? todaySteps,
    double? lastHeartRate,
  }) {
    final sched = schedule ?? ShiftSchedule.defaultForType(currentShiftType);
    final tips = <HealthTip>[];
    final now = DateTime.now();
    final hour = now.hour;

    // Data-driven insights first (highest priority)
    tips.addAll(_getPersonalInsights(
      sched: sched,
      yesterdaySleep: yesterdaySleep,
      recentSleep: recentSleep,
      recentEnergy: recentEnergy,
      todaySteps: todaySteps,
      lastHeartRate: lastHeartRate,
      userAge: userAge,
    ));

    // Time-aware contextual tips
    tips.addAll(_getTimeAwareTips(sched, hour));

    // Base guidance tips (lower priority)
    tips.addAll(_getSleepTips(sched, averageSleepHours, userAge));
    tips.addAll(_getMealTips(sched, hour));
    tips.addAll(_getExerciseTips(sched, hour));
    tips.addAll(_getCaffeineTips(sched, hour));
    tips.addAll(_getLightTips(sched, hour));
    tips.addAll(_getEnergyTips(sched, averageEnergy, averageSleepHours));

    tips.sort((a, b) => a.priority.compareTo(b.priority));
    return tips;
  }

  /// Generate personalized insights based on actual user data.
  List<HealthTip> _getPersonalInsights({
    required ShiftSchedule sched,
    SleepRecord? yesterdaySleep,
    List<SleepRecord> recentSleep = const [],
    List<EnergyRecord> recentEnergy = const [],
    int? todaySteps,
    double? lastHeartRate,
    int? userAge,
  }) {
    final tips = <HealthTip>[];
    final type = sched.type;
    final targetHours = _targetSleepHours(userAge);

    // --- Yesterday's sleep analysis ---
    if (yesterdaySleep != null) {
      final hours = yesterdaySleep.durationHours;
      final bedHour = yesterdaySleep.bedTime.hour;
      final bedMin = yesterdaySleep.bedTime.minute;
      final bedStr = '${bedHour.toString().padLeft(2, '0')}:${bedMin.toString().padLeft(2, '0')}';
      final wakeHour = yesterdaySleep.wakeTime.hour;
      final wakeMin = yesterdaySleep.wakeTime.minute;
      final wakeStr = '${wakeHour.toString().padLeft(2, '0')}:${wakeMin.toString().padLeft(2, '0')}';

      if (hours < targetHours - 1) {
        final deficit = targetHours - hours;
        tips.add(HealthTip(
          id: 'insight_sleep_deficit',
          category: AppConstants.tipSleep,
          title: '어제 수면 ${hours.toStringAsFixed(1)}시간 - 부족',
          description:
              '어제 $bedStr~$wakeStr에 ${hours.toStringAsFixed(1)}시간 수면했습니다. '
              '권장 ${targetHours.toStringAsFixed(0)}시간 대비 ${deficit.toStringAsFixed(1)}시간 부족합니다. '
              '오늘은 ${sched.recommendedBedTimeStr}까지 취침을 목표로 하세요.',
          shiftType: type,
          timing: '오늘 ${sched.recommendedBedTimeStr} 취침 권장',
          priority: 0,
        ));
      } else if (hours >= targetHours && yesterdaySleep.quality >= 4) {
        tips.add(HealthTip(
          id: 'insight_sleep_good',
          category: AppConstants.tipSleep,
          title: '어제 수면 ${hours.toStringAsFixed(1)}시간 - 충분',
          description:
              '어제 $bedStr~$wakeStr에 충분히 잘 수면했습니다. '
              '이 패턴을 유지하면 서카디안 리듬이 안정됩니다. '
              '오늘도 비슷한 시간에 취침하세요.',
          shiftType: type,
          timing: '$bedStr 취침 패턴 유지',
          priority: 1,
        ));
      } else {
        tips.add(HealthTip(
          id: 'insight_sleep_ok',
          category: AppConstants.tipSleep,
          title: '어제 수면 ${hours.toStringAsFixed(1)}시간',
          description:
              '어제 $bedStr~$wakeStr에 수면했습니다. '
              '${hours < targetHours ? "조금 더 수면 시간을 확보하면 컨디션이 좋아집니다." : "수면 시간은 적절합니다."} '
              '${yesterdaySleep.quality < 3 ? "수면 품질 개선을 위해 취침 전 스마트폰 사용을 줄여보세요." : ""}',
          shiftType: type,
          priority: 1,
        ));
      }
    }

    // --- Weekly sleep trend ---
    if (recentSleep.length >= 3) {
      final avgHours = recentSleep.fold<double>(
              0, (sum, r) => sum + r.durationHours) /
          recentSleep.length;
      final avgQuality = recentSleep.fold<int>(
              0, (sum, r) => sum + r.quality) /
          recentSleep.length;

      // Check bed time consistency
      final bedMinutes = recentSleep
          .map((r) {
            var m = r.bedTime.hour * 60 + r.bedTime.minute;
            if (m < 720) m += 1440; // normalize past-midnight times
            return m;
          })
          .toList();
      final avgBedMin = bedMinutes.reduce((a, b) => a + b) / bedMinutes.length;
      final variance = bedMinutes
              .map((m) => (m - avgBedMin) * (m - avgBedMin))
              .reduce((a, b) => a + b) /
          bedMinutes.length;
      final stdDev = _sqrt(variance);

      if (stdDev > 90) {
        // More than 1.5 hours variation
        tips.add(HealthTip(
          id: 'insight_bed_irregular',
          category: AppConstants.tipSleep,
          title: '취침 시간이 불규칙합니다',
          description:
              '최근 ${recentSleep.length}일간 취침 시간 편차가 ${(stdDev / 60).toStringAsFixed(1)}시간입니다. '
              '취침 시간이 매일 1시간 이상 차이나면 서카디안 리듬이 깨져 '
              '피로감이 늘어납니다. 일정한 취침 시간을 유지해보세요.',
          shiftType: type,
          timing: '${sched.recommendedBedTimeStr} 고정 취침 권장',
          priority: 0,
        ));
      } else if (stdDev < 30 && avgHours >= targetHours - 0.5) {
        tips.add(HealthTip(
          id: 'insight_bed_consistent',
          category: AppConstants.tipSleep,
          title: '수면 패턴이 안정적입니다',
          description:
              '최근 ${recentSleep.length}일간 평균 ${avgHours.toStringAsFixed(1)}시간, '
              '품질 ${avgQuality.toStringAsFixed(1)}/5로 좋은 수면 패턴을 유지하고 있습니다. '
              '이 리듬을 유지하세요!',
          shiftType: type,
          priority: 2,
        ));
      }

      // Sleep debt accumulation
      if (avgHours < targetHours - 0.5 && recentSleep.length >= 5) {
        final totalDebt = recentSleep.fold<double>(
            0, (sum, r) => sum + (targetHours - r.durationHours).clamp(0, 24));
        tips.add(HealthTip(
          id: 'insight_sleep_debt',
          category: AppConstants.tipSleep,
          title: '수면 부채 ${totalDebt.toStringAsFixed(1)}시간 누적',
          description:
              '최근 ${recentSleep.length}일간 평균 ${avgHours.toStringAsFixed(1)}시간 수면으로 '
              '총 ${totalDebt.toStringAsFixed(1)}시간의 수면 부채가 쌓였습니다. '
              '휴무일에 1-2시간 더 자거나, 근무일에 30분씩 일찍 취침해 회복하세요.',
          shiftType: type,
          priority: 0,
        ));
      }
    }

    // --- Activity insights ---
    if (todaySteps != null && todaySteps > 0) {
      if (todaySteps < 3000 && DateTime.now().hour >= 15) {
        tips.add(HealthTip(
          id: 'insight_steps_low',
          category: AppConstants.tipExercise,
          title: '오늘 활동량이 적습니다',
          description:
              '현재 ${_formatSteps(todaySteps)}걸음입니다. '
              '가벼운 산책이라도 하면 수면 품질과 에너지에 도움됩니다. '
              '${type == AppConstants.shiftNight ? "야간 근무 전 10-15분 산책을 추천합니다." : "퇴근 후 20분 산책을 추천합니다."}',
          shiftType: type,
          timing: '지금 가벼운 산책 추천',
          priority: 1,
        ));
      } else if (todaySteps >= 8000) {
        tips.add(HealthTip(
          id: 'insight_steps_good',
          category: AppConstants.tipExercise,
          title: '활동량 충분 - ${_formatSteps(todaySteps)}걸음',
          description:
              '오늘 충분히 활동했습니다. '
              '적절한 신체 활동은 수면 품질을 높여줍니다. '
              '다만 취침 2시간 전부터는 격렬한 운동을 피하세요.',
          shiftType: type,
          priority: 3,
        ));
      }
    }

    // --- Heart rate insight ---
    if (lastHeartRate != null) {
      if (lastHeartRate > 100 && type != AppConstants.shiftOff) {
        tips.add(HealthTip(
          id: 'insight_hr_high',
          category: AppConstants.tipEnergy,
          title: '심박수가 높습니다 (${lastHeartRate.round()} BPM)',
          description:
              '안정 시 심박수가 높으면 스트레스나 피로가 원인일 수 있습니다. '
              '심호흡을 5분간 해보세요 (4초 들이쉬고, 7초 참고, 8초 내쉬기). '
              '카페인 섭취도 확인해보세요.',
          shiftType: type,
          timing: '지금 심호흡 5분',
          priority: 1,
        ));
      }
    }

    // --- Energy pattern insight ---
    if (recentEnergy.length >= 3) {
      final avgEnergy = recentEnergy.fold<int>(
              0, (sum, r) => sum + r.energyLevel) /
          recentEnergy.length;

      if (avgEnergy < 2.5) {
        tips.add(HealthTip(
          id: 'insight_energy_declining',
          category: AppConstants.tipEnergy,
          title: '최근 에너지가 낮은 상태입니다',
          description:
              '최근 평균 에너지 ${avgEnergy.toStringAsFixed(1)}/5입니다. '
              '${recentSleep.isNotEmpty && recentSleep.fold<double>(0, (s, r) => s + r.durationHours) / recentSleep.length < 6 ? "수면 부족이 주요 원인으로 보입니다. 수면 시간 확보가 우선입니다." : "규칙적인 식사, 수분 섭취, 가벼운 산책으로 회복해보세요."}',
          shiftType: type,
          priority: 0,
        ));
      }
    }

    return tips;
  }

  /// Generate time-aware contextual tips based on current time and shift.
  List<HealthTip> _getTimeAwareTips(ShiftSchedule sched, int hour) {
    final tips = <HealthTip>[];
    final type = sched.type;
    final bedH = sched.recommendedBedHour;

    // 2 hours before recommended bedtime
    if (_inHourRange(hour, (bedH - 2 + 24) % 24, bedH)) {
      tips.add(HealthTip(
        id: 'time_pre_sleep',
        category: AppConstants.tipSleep,
        title: '취침 준비 시간입니다',
        description:
            '${sched.recommendedBedTimeStr} 취침까지 약 ${(bedH - hour + 24) % 24}시간 남았습니다. '
            '스마트폰 블루라이트를 줄이고, 카페인을 피하세요. '
            '따뜻한 물 한 잔이나 가벼운 스트레칭이 도움됩니다.',
        shiftType: type,
        timing: '지금 ~ ${sched.recommendedBedTimeStr}',
        priority: 0,
      ));
    }

    // Just woke up (within 2 hours of recommended wake time)
    if (_inHourRange(hour, sched.recommendedWakeHour,
        (sched.recommendedWakeHour + 2) % 24)) {
      if (type == AppConstants.shiftNight) {
        tips.add(HealthTip(
          id: 'time_wake_night',
          category: AppConstants.tipLight,
          title: '기상 후 빛 차단 유지',
          description:
              '야간 근무 후 기상했다면 실내를 어둡게 유지하세요. '
              '다음 수면을 위해 밝은 빛 노출을 최소화하는 것이 중요합니다.',
          shiftType: type,
          timing: '지금',
          priority: 1,
        ));
      } else {
        tips.add(HealthTip(
          id: 'time_wake_day',
          category: AppConstants.tipLight,
          title: '기상 후 햇빛을 쬐세요',
          description:
              '15-30분 햇빛 노출로 멜라토닌 분비를 억제하고 각성도를 높이세요. '
              '창가에서 아침 식사를 하는 것도 좋은 방법입니다.',
          shiftType: type,
          timing: '지금 ~ 30분',
          priority: 1,
        ));
      }
    }

    // During shift - mid-point energy dip warning
    final midShift = (sched.startHour +
            ((sched.endHour - sched.startHour + 24) % 24) ~/ 2) %
        24;
    if (_inHourRange(hour, midShift, (midShift + 2) % 24)) {
      tips.add(HealthTip(
        id: 'time_mid_shift',
        category: AppConstants.tipEnergy,
        title: '근무 중반 - 에너지 관리',
        description:
            '근무 중간에 에너지가 떨어지기 쉽습니다. '
            '물 한 잔 마시고, 가능하면 2-3분 스트레칭을 하세요. '
            '${type == AppConstants.shiftNight ? "냉수로 세안하면 각성에 도움됩니다." : "짧은 걷기도 효과적입니다."}',
        shiftType: type,
        timing: '지금',
        priority: 2,
      ));
    }

    return tips;
  }

  List<HealthTip> _getEnergyTips(
      ShiftSchedule sched, double avgEnergy, double avgSleepHours) {
    final tips = <HealthTip>[];
    final type = sched.type;

    if (type == AppConstants.shiftNight) {
      tips.add(HealthTip(
        id: 'energy_night_1',
        category: AppConstants.tipEnergy,
        title: '야간 근무 에너지 관리',
        description:
            '근무 시작 시 밝은 빛에 노출하고, '
            '02:00-04:00 사이 가벼운 스트레칭으로 각성도를 유지하세요. '
            '짧은 산책이나 냉수 세안도 효과적입니다.',
        shiftType: type,
        timing: '02:00-04:00',
        priority: 4,
      ));
    } else if (type == AppConstants.shiftDay) {
      tips.add(HealthTip(
        id: 'energy_day_1',
        category: AppConstants.tipEnergy,
        title: '오후 슬럼프 극복',
        description:
            '13:00-15:00 사이 에너지가 떨어질 수 있습니다. '
            '가벼운 산책이나 스트레칭으로 각성도를 유지하세요. '
            '고당분 간식 대신 견과류나 과일을 섭취하세요.',
        shiftType: type,
        timing: '13:00-15:00',
        priority: 4,
      ));
    } else if (type == AppConstants.shiftEvening) {
      tips.add(HealthTip(
        id: 'energy_evening_1',
        category: AppConstants.tipEnergy,
        title: '저녁 근무 에너지 관리',
        description:
            '출근 전 가벼운 운동으로 에너지를 끌어올리세요. '
            '근무 중 규칙적으로 수분을 섭취하면 집중력 유지에 도움됩니다.',
        shiftType: type,
        priority: 4,
      ));
    }

    return tips;
  }

  List<HealthTip> _getSleepTips(
      ShiftSchedule sched, double avgHours, int? userAge) {
    final tips = <HealthTip>[];
    final type = sched.type;

    if (type == AppConstants.shiftNight) {
      tips.add(HealthTip(
        id: 'sleep_night_1',
        category: AppConstants.tipSleep,
        title: '야간 근무 후 수면 가이드',
        description:
            '퇴근(${sched.endTimeStr}) 후 바로 수면을 취하세요. '
            '암막 커튼과 수면 안대를 사용하고, '
            '실내 온도를 18-20도로 유지하면 깊은 수면에 도움됩니다.',
        shiftType: type,
        timing: '${sched.endTimeStr} 퇴근 후',
        priority: 3,
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
        priority: 3,
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
        priority: 3,
      ));
    } else {
      tips.add(HealthTip(
        id: 'sleep_off_1',
        category: AppConstants.tipSleep,
        title: '휴무일 수면 리듬 유지',
        description:
            '휴무일에도 평소 기상 시간과 1시간 이상 차이나지 않도록 하세요. '
            '주말 몰아자기는 서카디안 리듬을 깨뜨립니다.',
        shiftType: type,
        priority: 3,
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
        priority: 4,
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
        priority: 4,
      ));
    } else if (type == AppConstants.shiftDay) {
      final breakfastHour = sched.recommendedWakeHour;
      final lunchHour = (sched.startHour + 6) % 24;
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
        priority: 4,
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
        priority: 4,
      ));
    } else {
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
        priority: 4,
      ));
    }

    return tips;
  }

  List<HealthTip> _getCaffeineTips(ShiftSchedule sched, int currentHour) {
    final tips = <HealthTip>[];
    final type = sched.type;

    if (type == AppConstants.shiftOff) return tips;

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
        priority: 4,
      ));
    }

    return tips;
  }

  bool _isHourPassed(int current, int target) {
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
        priority: 3,
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
        priority: 4,
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
          .map((r) {
            var m = r.bedTime.hour * 60 + r.bedTime.minute;
            if (m < 720) m += 1440; // normalize past-midnight times
            return m;
          })
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

  static String _formatSteps(int steps) {
    if (steps >= 10000) {
      return '${(steps / 10000).toStringAsFixed(1)}만';
    }
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}천';
    }
    return steps.toString();
  }

  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}
