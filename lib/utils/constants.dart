class AppConstants {
  AppConstants._();

  static const String appName = 'Change';
  static const String appVersion = '1.0.0';
  static const String dbName = 'change.db';
  static const int dbVersion = 2;

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
}
