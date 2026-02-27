import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();
    // Set to Korea Standard Time (KST = UTC+9)
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Schedule a daily sleep reminder at the given time (repeats every day)
  Future<void> scheduleSleepReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final tzScheduled = tz.TZDateTime(
      tz.local,
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sleep_reminder',
          '수면 리마인더',
          channelDescription: '취침 시간 알림',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );
  }

  /// Schedule a one-time shift start reminder
  Future<void> scheduleShiftReminder({
    required int id,
    required String shiftType,
    required DateTime shiftStart,
    int minutesBefore = 60,
  }) async {
    final reminderTime =
        shiftStart.subtract(Duration(minutes: minutesBefore));

    // Skip if reminder time is in the past
    if (reminderTime.isBefore(DateTime.now())) return;

    final shiftLabel = {
      'day': '주간',
      'evening': '오후',
      'night': '야간',
    }[shiftType] ?? shiftType;

    final tzReminder = tz.TZDateTime.from(reminderTime, tz.local);

    await _plugin.zonedSchedule(
      id,
      '$shiftLabel 근무 준비',
      '${minutesBefore}분 후 $shiftLabel 근무가 시작됩니다. 준비하세요!',
      tzReminder,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'shift_reminder',
          '근무 알림',
          channelDescription: '근무 시작 전 알림',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedule a daily motivational message at the given hour:minute.
  Future<void> scheduleDailyMotivation({
    required int id,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final tzScheduled = tz.TZDateTime(
      tz.local,
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    await _plugin.zonedSchedule(
      id,
      '오늘의 한 마디',
      body,
      tzScheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'motivation_daily',
          '오늘의 동기부여',
          channelDescription: '교대근무자를 위한 일일 동기부여 메시지',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Get a random motivational quote for shift workers.
  static String randomMotivationQuote() {
    final quotes = [
      '교대근무는 힘들지만, 균형을 찾아가는 당신은 강인합니다.',
      '오늘도 수고했습니다. 당신의 노력이 세상을 돌아가게 합니다.',
      '불규칙한 일상 속에서도 규칙적인 나를 만드는 것, 그것이 진짜 힘입니다.',
      '밤을 버텨낸 당신, 그 용기가 하루를 특별하게 만듭니다.',
      '쉬는 날에 충분히 쉬는 것도 훌륭한 선택입니다.',
      '당신이 지킨 자리가 있어 오늘도 세상이 안전합니다.',
      '피곤함은 노력의 증거, 수면은 그 노력에 대한 보상입니다.',
      '교대근무의 어려움을 아는 당신은 이미 남다른 사람입니다.',
      '힘든 순간일수록 작은 것에서 행복을 찾는 연습을 해보세요.',
      '당신의 헌신으로 누군가의 하루가 더 나아집니다.',
      '밤을 지새우는 것, 그것은 강함의 또 다른 이름입니다.',
      '지금 이 순간, 당신은 충분히 잘 하고 있습니다.',
      '체력이 곧 자신감입니다. 오늘도 몸을 잘 챙기세요.',
      '수면 1시간이 내일의 당신을 더 빛나게 만듭니다.',
      '오늘 힘든 만큼 내일의 나는 더 단단해집니다.',
      '근무 후 나를 위한 작은 보상, 잊지 마세요.',
      '잘 자는 것도 실력입니다. 오늘 수면을 챙기세요.',
      '교대근무자라는 것, 그 자체로 대단한 일을 하는 사람입니다.',
      '오늘 하루도 무사히. 당신 덕분입니다.',
      '몸이 먼저입니다. 건강이 있어야 모든 것이 가능합니다.',
    ];
    final index = DateTime.now().millisecondsSinceEpoch % quotes.length;
    return quotes[index];
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
