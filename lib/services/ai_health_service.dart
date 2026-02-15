import '../models/health_tip.dart';
import '../models/sleep_record.dart';
import '../providers/health_provider.dart';
import '../utils/constants.dart';

class AiHealthService {
  List<HealthTip> generateTips({
    required String currentShiftType,
    required double averageSleepHours,
    required double averageSleepQuality,
  }) {
    final tips = <HealthTip>[];
    final now = DateTime.now();
    final hour = now.hour;

    // Sleep tips based on shift type
    tips.addAll(_getSleepTips(currentShiftType, averageSleepHours));

    // Meal timing tips
    tips.addAll(_getMealTips(currentShiftType, hour));

    // Exercise tips
    tips.addAll(_getExerciseTips(currentShiftType, hour));

    // Caffeine tips
    tips.addAll(_getCaffeineTips(currentShiftType, hour));

    // Light exposure tips
    tips.addAll(_getLightTips(currentShiftType, hour));

    // Sort by priority
    tips.sort((a, b) => a.priority.compareTo(b.priority));

    return tips;
  }

  List<HealthTip> _getSleepTips(String shiftType, double avgHours) {
    final tips = <HealthTip>[];

    switch (shiftType) {
      case AppConstants.shiftNight:
        tips.add(HealthTip(
          id: 'sleep_night_1',
          category: AppConstants.tipSleep,
          title: '야간 근무 후 수면 가이드',
          description:
              '퇴근 후 바로 수면을 취하세요. 암막 커튼과 수면 안대를 사용하고, '
              '실내 온도를 18-20°C로 유지하면 깊은 수면에 도움됩니다.',
          shiftType: shiftType,
          timing: '퇴근 직후',
          priority: 1,
        ));
        tips.add(HealthTip(
          id: 'sleep_night_2',
          category: AppConstants.tipSleep,
          title: '분할 수면 전략',
          description:
              '야간 근무자는 주 수면(4-5시간) + 보조 낮잠(1.5-2시간) '
              '분할 수면이 효과적입니다. 출근 전 90분 낮잠으로 각성도를 높이세요.',
          shiftType: shiftType,
          timing: '출근 3시간 전',
          priority: 2,
        ));
        break;

      case AppConstants.shiftEvening:
        tips.add(HealthTip(
          id: 'sleep_evening_1',
          category: AppConstants.tipSleep,
          title: '오후 근무 수면 패턴',
          description:
              '오후 근무자는 자정~오전 8시 수면이 이상적입니다. '
              '퇴근 후 바로 잠들지 말고, 1시간 정도 릴랙스 타임을 가진 후 수면하세요.',
          shiftType: shiftType,
          timing: '퇴근 1시간 후',
          priority: 1,
        ));
        break;

      case AppConstants.shiftDay:
        tips.add(HealthTip(
          id: 'sleep_day_1',
          category: AppConstants.tipSleep,
          title: '주간 근무 수면 최적화',
          description:
              '밤 10시~11시 사이에 잠자리에 드세요. 취침 1시간 전 블루라이트를 차단하고, '
              '일정한 기상 시간을 유지하면 서카디안 리듬이 안정됩니다.',
          shiftType: shiftType,
          timing: '22:00-23:00',
          priority: 1,
        ));
        break;
    }

    if (avgHours > 0 && avgHours < 6) {
      tips.add(HealthTip(
        id: 'sleep_warning',
        category: AppConstants.tipSleep,
        title: '수면 부족 경고',
        description:
            '최근 평균 수면 시간이 ${avgHours.toStringAsFixed(1)}시간입니다. '
            '최소 7시간 수면을 목표로 하세요. 만성 수면 부족은 면역력 저하, '
            '집중력 감소, 사고 위험 증가를 유발합니다.',
        shiftType: shiftType,
        priority: 1,
      ));
    }

    return tips;
  }

  List<HealthTip> _getMealTips(String shiftType, int currentHour) {
    final tips = <HealthTip>[];

    switch (shiftType) {
      case AppConstants.shiftNight:
        tips.add(HealthTip(
          id: 'meal_night_1',
          category: AppConstants.tipMeal,
          title: '야간 근무 식사 전략',
          description:
              '야간 근무 중 새벽 2-3시에 가벼운 식사를 하세요. '
              '고탄수화물 음식은 피하고, 단백질 위주의 가벼운 식사가 좋습니다. '
              '퇴근 후에는 소화가 잘 되는 죽이나 수프를 추천합니다.',
          shiftType: shiftType,
          timing: '02:00-03:00',
          priority: 2,
        ));
        break;

      case AppConstants.shiftEvening:
        tips.add(HealthTip(
          id: 'meal_evening_1',
          category: AppConstants.tipMeal,
          title: '오후 근무 식사 가이드',
          description:
              '출근 전 충분한 점심 식사를 하세요. 근무 중 간식은 견과류, '
              '과일 등 건강한 선택을 하고, 퇴근 후 야식은 자제하세요.',
          shiftType: shiftType,
          timing: '12:00 점심, 18:00 저녁',
          priority: 2,
        ));
        break;

      case AppConstants.shiftDay:
        tips.add(HealthTip(
          id: 'meal_day_1',
          category: AppConstants.tipMeal,
          title: '규칙적 식사 리마인더',
          description:
              '아침, 점심, 저녁 규칙적인 식사를 유지하세요. '
              '특히 아침 식사는 서카디안 리듬 안정에 중요합니다.',
          shiftType: shiftType,
          timing: '07:00, 12:00, 18:30',
          priority: 3,
        ));
        break;
    }

    return tips;
  }

  List<HealthTip> _getExerciseTips(String shiftType, int currentHour) {
    final tips = <HealthTip>[];

    switch (shiftType) {
      case AppConstants.shiftNight:
        tips.add(HealthTip(
          id: 'exercise_night_1',
          category: AppConstants.tipExercise,
          title: '야간 근무자 운동 타이밍',
          description:
              '기상 후 1-2시간 내에 가벼운 운동(스트레칭, 요가)을 하세요. '
              '격렬한 운동은 출근 4시간 전까지 마치세요. '
              '수면 직전 운동은 수면 질을 떨어뜨립니다.',
          shiftType: shiftType,
          timing: '기상 후 1-2시간',
          priority: 3,
        ));
        break;

      case AppConstants.shiftOff:
        tips.add(HealthTip(
          id: 'exercise_off_1',
          category: AppConstants.tipExercise,
          title: '휴무일 운동 추천',
          description:
              '오늘은 휴무일입니다! 30-40분 유산소 운동으로 체력을 회복하세요. '
              '야외 운동으로 햇빛을 충분히 쬐면 비타민D 합성과 '
              '서카디안 리듬 회복에 도움됩니다.',
          shiftType: shiftType,
          timing: '오전 10시-오후 2시',
          priority: 2,
        ));
        break;

      default:
        tips.add(HealthTip(
          id: 'exercise_general',
          category: AppConstants.tipExercise,
          title: '출근 전 스트레칭',
          description:
              '출근 전 10분 스트레칭으로 몸을 깨워주세요. '
              '특히 목, 어깨, 허리 스트레칭은 장시간 근무에 도움됩니다.',
          shiftType: shiftType,
          timing: '출근 30분 전',
          priority: 3,
        ));
    }

    return tips;
  }

  List<HealthTip> _getCaffeineTips(String shiftType, int currentHour) {
    final tips = <HealthTip>[];

    switch (shiftType) {
      case AppConstants.shiftNight:
        tips.add(HealthTip(
          id: 'caffeine_night_1',
          category: AppConstants.tipCaffeine,
          title: '야간 근무 카페인 전략',
          description:
              '근무 시작 시 커피 한 잔으로 각성도를 높이되, '
              '새벽 3시 이후에는 카페인을 피하세요. '
              '카페인 반감기(5-6시간)를 고려하면 퇴근 후 수면에 방해됩니다.',
          shiftType: shiftType,
          timing: '22:00-03:00까지만',
          priority: 2,
        ));
        break;

      case AppConstants.shiftDay:
        if (currentHour >= 14) {
          tips.add(HealthTip(
            id: 'caffeine_day_afternoon',
            category: AppConstants.tipCaffeine,
            title: '카페인 컷오프 시간',
            description:
                '오후 2시 이후 카페인 섭취는 자제하세요. '
                '카페인이 체내에서 완전히 분해되려면 8-10시간이 걸립니다. '
                '대신 냉수나 허브차를 마시세요.',
            shiftType: shiftType,
            timing: '14:00 이후 금지',
            priority: 2,
          ));
        }
        break;
    }

    return tips;
  }

  List<HealthTip> _getLightTips(String shiftType, int currentHour) {
    final tips = <HealthTip>[];

    switch (shiftType) {
      case AppConstants.shiftNight:
        tips.add(HealthTip(
          id: 'light_night_1',
          category: AppConstants.tipLight,
          title: '빛 노출 관리 (야간)',
          description:
              '퇴근 시 선글라스를 착용해 아침 햇빛을 차단하세요. '
              '귀가 후 암막 커튼으로 수면 환경을 조성하세요. '
              '다음 근무 출발 전 15분간 밝은 빛에 노출되면 각성에 도움됩니다.',
          shiftType: shiftType,
          timing: '퇴근 시 선글라스, 출근 전 밝은 빛',
          priority: 1,
        ));
        break;

      case AppConstants.shiftDay:
        tips.add(HealthTip(
          id: 'light_day_1',
          category: AppConstants.tipLight,
          title: '아침 햇빛 노출',
          description:
              '기상 후 30분 이내에 밝은 햇빛을 15-30분 쬐세요. '
              '이는 멜라토닌 분비를 억제하고 서카디안 리듬을 안정시킵니다. '
              '실내에서도 창가에서 햇빛을 받는 것이 도움됩니다.',
          shiftType: shiftType,
          timing: '기상 후 30분 이내',
          priority: 2,
        ));
        break;
    }

    return tips;
  }

  CircadianPhase getCurrentCircadianPhase(String shiftType) {
    final hour = DateTime.now().hour;

    if (shiftType == AppConstants.shiftNight) {
      // Night shift: shifted circadian
      if (hour >= 8 && hour < 10) return CircadianPhase.drowsy;
      if (hour >= 10 && hour < 18) return CircadianPhase.sleep;
      if (hour >= 18 && hour < 20) return CircadianPhase.waking;
      if (hour >= 20 || hour < 2) return CircadianPhase.alert;
      if (hour >= 2 && hour < 5) return CircadianPhase.active;
      return CircadianPhase.drowsy;
    }

    if (shiftType == AppConstants.shiftEvening) {
      if (hour >= 0 && hour < 7) return CircadianPhase.sleep;
      if (hour >= 7 && hour < 9) return CircadianPhase.waking;
      if (hour >= 9 && hour < 13) return CircadianPhase.alert;
      if (hour >= 13 && hour < 15) return CircadianPhase.active;
      if (hour >= 15 && hour < 22) return CircadianPhase.alert;
      return CircadianPhase.drowsy;
    }

    // Day shift (default)
    if (hour >= 0 && hour < 5) return CircadianPhase.deepSleep;
    if (hour >= 5 && hour < 7) return CircadianPhase.waking;
    if (hour >= 7 && hour < 10) return CircadianPhase.alert;
    if (hour >= 10 && hour < 14) return CircadianPhase.active;
    if (hour >= 14 && hour < 16) return CircadianPhase.drowsy;
    if (hour >= 16 && hour < 20) return CircadianPhase.alert;
    if (hour >= 20 && hour < 22) return CircadianPhase.drowsy;
    return CircadianPhase.sleep;
  }

  double calculateCircadianScore({
    required String shiftType,
    required List<SleepRecord> sleepRecords,
  }) {
    if (sleepRecords.isEmpty) return 50.0;

    double score = 50.0;

    // Average sleep hours score (target: 7-8 hours)
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

    // Sleep quality score
    final avgQuality = sleepRecords.fold<int>(
            0, (sum, r) => sum + r.quality) /
        sleepRecords.length;
    score += (avgQuality - 3) * 10;

    // Consistency score (check if bed times are similar)
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
        // Less than 30 min variance
        score += 15;
      } else if (variance < 3600) {
        // Less than 1 hour variance
        score += 5;
      } else {
        score -= 5;
      }
    }

    return score.clamp(0, 100);
  }

  // Get recommended sleep times for shift type
  Map<String, String> getRecommendedSleepTimes(String shiftType) {
    switch (shiftType) {
      case AppConstants.shiftNight:
        return {
          'bedTime': '08:00',
          'wakeTime': '15:00',
          'napTime': '19:00-20:30',
        };
      case AppConstants.shiftEvening:
        return {
          'bedTime': '00:00',
          'wakeTime': '08:00',
        };
      case AppConstants.shiftDay:
        return {
          'bedTime': '22:30',
          'wakeTime': '06:00',
        };
      default:
        return {
          'bedTime': '23:00',
          'wakeTime': '07:00',
        };
    }
  }
}
