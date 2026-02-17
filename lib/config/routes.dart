import 'package:flutter/material.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/sleep/sleep_tracker_screen.dart';
import '../screens/sleep/sleep_stats_screen.dart';
import '../screens/energy/energy_tracker_screen.dart';
import '../screens/energy/energy_stats_screen.dart';
import '../screens/health/circadian_screen.dart';
import '../screens/health/health_coach_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/salary/salary_screen.dart';
import '../screens/salary/salary_settings_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String onboarding = '/onboarding';
  static const String calendar = '/calendar';
  static const String sleepTracker = '/sleep-tracker';
  static const String sleepStats = '/sleep-stats';
  static const String circadian = '/circadian';
  static const String energyTracker = '/energy-tracker';
  static const String energyStats = '/energy-stats';
  static const String healthCoach = '/health-coach';
  static const String settings = '/settings';
  static const String salary = '/salary';
  static const String salarySettings = '/salary-settings';

  static Map<String, WidgetBuilder> get routes => {
        onboarding: (context) => const OnboardingScreen(),
        calendar: (context) => const CalendarScreen(),
        sleepTracker: (context) => const SleepTrackerScreen(),
        sleepStats: (context) => const SleepStatsScreen(),
        energyTracker: (context) => const EnergyTrackerScreen(),
        energyStats: (context) => const EnergyStatsScreen(),
        circadian: (context) => const CircadianScreen(),
        healthCoach: (context) => const HealthCoachScreen(),
        settings: (context) => const SettingsScreen(),
        salary: (context) => const SalaryScreen(),
        salarySettings: (context) => const SalarySettingsScreen(),
      };
}
