import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'constants.dart';

class AppHelpers {
  AppHelpers._();

  static String formatDate(DateTime date) {
    return DateFormat('yyyy.MM.dd').format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}시간 ${minutes}분';
  }

  static String getShiftLabel(String shiftType) {
    switch (shiftType) {
      case AppConstants.shiftDay:
        return '주간';
      case AppConstants.shiftEvening:
        return '오후';
      case AppConstants.shiftNight:
        return '야간';
      case AppConstants.shiftOff:
        return '휴무';
      default:
        return '미정';
    }
  }

  static Color getShiftColor(String shiftType) {
    switch (shiftType) {
      case AppConstants.shiftDay:
        return const Color(0xFFE8B94A); // Golden yellow
      case AppConstants.shiftEvening:
        return const Color(0xFFE07B7B); // Coral
      case AppConstants.shiftNight:
        return const Color(0xFF8B7EC8); // Soft lavender
      case AppConstants.shiftOff:
        return const Color(0xFF7CB88A); // Sage green
      default:
        return const Color(0xFF8A7E73); // Warm grey
    }
  }

  static IconData getShiftIcon(String shiftType) {
    switch (shiftType) {
      case AppConstants.shiftDay:
        return Icons.wb_sunny_rounded;
      case AppConstants.shiftEvening:
        return Icons.wb_twilight_rounded;
      case AppConstants.shiftNight:
        return Icons.nightlight_round;
      case AppConstants.shiftOff:
        return Icons.weekend_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  static String getSleepQualityLabel(int quality) {
    switch (quality) {
      case 5:
        return '최고';
      case 4:
        return '좋음';
      case 3:
        return '보통';
      case 2:
        return '나쁨';
      case 1:
        return '최악';
      default:
        return '미기록';
    }
  }

  static Color getSleepQualityColor(int quality) {
    switch (quality) {
      case 5:
        return const Color(0xFF7CB88A); // Sage
      case 4:
        return const Color(0xFF9DC4A0); // Light sage
      case 3:
        return const Color(0xFFE8B94A); // Warm yellow
      case 2:
        return const Color(0xFFE07B7B); // Coral
      case 1:
        return const Color(0xFFD4675A); // Terra cotta
      default:
        return const Color(0xFF8A7E73); // Warm grey
    }
  }

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '좋은 새벽이에요';
    if (hour < 12) return '좋은 아침이에요';
    if (hour < 18) return '좋은 오후예요';
    return '좋은 저녁이에요';
  }

  static DateTime dateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Energy helpers
  static String getEnergyLabel(int level) {
    switch (level) {
      case 5:
        return '최고';
      case 4:
        return '좋음';
      case 3:
        return '보통';
      case 2:
        return '피곤';
      case 1:
        return '탈진';
      default:
        return '미기록';
    }
  }

  static Color getEnergyColor(int level) {
    switch (level) {
      case 5:
        return const Color(0xFF7CB88A);
      case 4:
        return const Color(0xFF9DC4A0);
      case 3:
        return const Color(0xFFE8B94A);
      case 2:
        return const Color(0xFFE07B7B);
      case 1:
        return const Color(0xFFD4675A);
      default:
        return const Color(0xFF8A7E73);
    }
  }

  static IconData getEnergyIcon(int level) {
    switch (level) {
      case 5:
        return Icons.bolt_rounded;
      case 4:
        return Icons.battery_full_rounded;
      case 3:
        return Icons.battery_std_rounded;
      case 2:
        return Icons.battery_3_bar_rounded;
      case 1:
        return Icons.battery_1_bar_rounded;
      default:
        return Icons.battery_unknown_rounded;
    }
  }

  static String getActivityLabel(String activity) {
    switch (activity) {
      case 'work':
        return '근무 중';
      case 'commute':
        return '출퇴근';
      case 'exercise':
        return '운동 후';
      case 'meal':
        return '식사 후';
      case 'rest':
        return '휴식 중';
      case 'wakeup':
        return '기상 직후';
      case 'other':
        return '기타';
      default:
        return activity;
    }
  }

  static IconData getActivityIcon(String activity) {
    switch (activity) {
      case 'work':
        return Icons.work_rounded;
      case 'commute':
        return Icons.directions_bus_rounded;
      case 'exercise':
        return Icons.fitness_center_rounded;
      case 'meal':
        return Icons.restaurant_rounded;
      case 'rest':
        return Icons.self_improvement_rounded;
      case 'wakeup':
        return Icons.alarm_rounded;
      case 'other':
        return Icons.more_horiz_rounded;
      default:
        return Icons.circle;
    }
  }

  static String getMoodLabel(String mood) {
    switch (mood) {
      case 'great':
        return '좋음';
      case 'normal':
        return '보통';
      case 'tired':
        return '피곤';
      case 'stressed':
        return '스트레스';
      case 'anxious':
        return '불안';
      default:
        return mood;
    }
  }

  static IconData getMoodIcon(String mood) {
    switch (mood) {
      case 'great':
        return Icons.sentiment_very_satisfied_rounded;
      case 'normal':
        return Icons.sentiment_neutral_rounded;
      case 'tired':
        return Icons.sentiment_dissatisfied_rounded;
      case 'stressed':
        return Icons.mood_bad_rounded;
      case 'anxious':
        return Icons.psychology_alt_rounded;
      default:
        return Icons.sentiment_neutral_rounded;
    }
  }

  // Salary helpers
  static String formatKRW(double amount) {
    if (amount >= 100000000) {
      final eok = amount / 100000000;
      return '${eok.toStringAsFixed(eok % 1 == 0 ? 0 : 1)}억원';
    } else if (amount >= 10000) {
      final man = amount / 10000;
      return '${man.toStringAsFixed(man % 1 == 0 ? 0 : 1)}만원';
    }
    return '${amount.toStringAsFixed(0)}원';
  }

  static String formatKRWFull(double amount) {
    final formatter = NumberFormat('#,###', 'ko_KR');
    return '₩${formatter.format(amount.round())}';
  }

  static String getPayTypeLabel(String payType) {
    return payType == AppConstants.payTypeHourly ? '시급제' : '월급제';
  }
}
