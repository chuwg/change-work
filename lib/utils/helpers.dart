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
}
