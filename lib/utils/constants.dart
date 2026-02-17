class AppConstants {
  AppConstants._();

  static const String appName = 'Change';
  static const String appVersion = '1.0.0';
  static const String dbName = 'change.db';
  static const int dbVersion = 4;

  // Shift Types
  static const String shiftDay = 'day';
  static const String shiftEvening = 'evening';
  static const String shiftNight = 'night';
  static const String shiftOff = 'off';

  // Default shift times
  static const Map<String, Map<String, String>> defaultShiftTimes = {
    'day': {'start': '06:00', 'end': '14:00'},
    'evening': {'start': '14:00', 'end': '22:00'},
    'night': {'start': '22:00', 'end': '06:00'},
  };

  // Sleep quality levels
  static const int sleepQualityExcellent = 5;
  static const int sleepQualityGood = 4;
  static const int sleepQualityFair = 3;
  static const int sleepQualityPoor = 2;
  static const int sleepQualityTerrible = 1;

  // Circadian rhythm phases
  static const String phaseAlert = 'alert';
  static const String phaseDrowsy = 'drowsy';
  static const String phaseDeepSleep = 'deep_sleep';
  static const String phaseWaking = 'waking';

  // Health data sync keys
  static const String healthSyncEnabledKey = 'health_sync_enabled';
  static const String lastHealthSyncKey = 'last_health_sync';

  // Custom shift times key
  static const String customShiftTimesKey = 'custom_shift_times';

  // Settings keys
  static const String sleepReminderKey = 'sleep_reminder';
  static const String shiftReminderKey = 'shift_reminder';
  static const String healthTipsKey = 'health_tips';
  static const String reminderMinutesKey = 'reminder_minutes';

  // Health tip categories
  static const String tipSleep = 'sleep';
  static const String tipMeal = 'meal';
  static const String tipExercise = 'exercise';
  static const String tipCaffeine = 'caffeine';
  static const String tipLight = 'light';
  static const String tipEnergy = 'energy';

  // Energy levels
  static const int energyExcellent = 5;
  static const int energyGood = 4;
  static const int energyNormal = 3;
  static const int energyTired = 2;
  static const int energyExhausted = 1;

  // Energy activity types
  static const List<String> energyActivities = [
    'work',
    'commute',
    'exercise',
    'meal',
    'rest',
    'wakeup',
    'other',
  ];

  // Energy mood types
  static const List<String> energyMoods = [
    'great',
    'normal',
    'tired',
    'stressed',
    'anxious',
  ];

  // Salary settings
  static const String salarySettingsKey = 'salary_settings';

  // Widget
  static const String appGroupId = 'group.com.change.app.change';
  static const String payTypeHourly = 'hourly';
  static const String payTypeMonthly = 'monthly';
  static const double defaultNightMultiplier = 1.5;
  static const double defaultWeekendMultiplier = 1.5;
  static const double defaultOvertimeMultiplier = 1.5;
  static const double defaultShiftHours = 8.0;
  static const double overtimeThresholdHoursPerWeek = 40.0;
}
