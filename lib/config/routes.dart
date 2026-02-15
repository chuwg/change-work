import 'package:flutter/material.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/sleep/sleep_tracker_screen.dart';
import '../screens/sleep/sleep_stats_screen.dart';
import '../screens/health/circadian_screen.dart';
import '../screens/health/health_coach_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String onboarding = '/onboarding';
  static const String calendar = '/calendar';
  static const String sleepTracker = '/sleep-tracker';
  static const String sleepStats = '/sleep-stats';
  static const String circadian = '/circadian';
  static const String healthCoach = '/health-coach';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
        onboarding: (context) => const OnboardingScreen(),
        calendar: (context) => const CalendarScreen(),
        sleepTracker: (context) => const SleepTrackerScreen(),
        sleepStats: (context) => const SleepStatsScreen(),
        circadian: (context) => const CircadianScreen(),
        healthCoach: (context) => const HealthCoachScreen(),
        settings: (context) => const SettingsScreen(),
      };
}
