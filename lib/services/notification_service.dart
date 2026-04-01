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

    final startTimeStr =
        '${shiftStart.hour.toString().padLeft(2, '0')}:${shiftStart.minute.toString().padLeft(2, '0')}';

    await _plugin.zonedSchedule(
      id,
      '지금 출발하세요!',
      '$shiftLabel 근무 $startTimeStr 시작 · 이동 시간 ${minutesBefore}분',
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

  /// Get a daily motivational quote for shift workers.
  /// Uses day-of-year so the quote changes once per day and cycles through all.
  static String randomMotivationQuote() {
    final quotes = [
      // 교대근무자 응원
      '교대근무는 힘들지만, 균형을 찾아가는 당신은 강인합니다.',
      '오늘도 수고했습니다. 당신의 노력이 세상을 돌아가게 합니다.',
      '당신이 지킨 자리가 있어 오늘도 세상이 안전합니다.',
      '교대근무자라는 것, 그 자체로 대단한 일을 하는 사람입니다.',
      '밤을 버텨낸 당신, 그 용기가 하루를 특별하게 만듭니다.',
      '당신의 헌신으로 누군가의 하루가 더 나아집니다.',
      '다른 사람이 잠든 시간에 깨어 있는 것, 그것이 책임감입니다.',
      '교대근무를 선택한 당신은 이미 용기 있는 사람입니다.',
      '세상이 멈추지 않는 건 당신 같은 사람이 있기 때문입니다.',
      '누군가는 잠들고, 누군가는 지키고. 당신은 지키는 사람입니다.',
      '야간근무의 고독함을 아는 사람만이 새벽의 아름다움도 압니다.',
      '불규칙한 삶 속에서 균형을 찾는 것, 이미 대단한 일입니다.',
      '오늘 밤도 묵묵히 자리를 지켜주셔서 감사합니다.',
      '교대근무의 힘듦은 아무나 견딜 수 없는 것입니다.',
      '당신의 밤근무 덕분에 누군가의 아침이 안전합니다.',

      // 건강·수면 동기부여
      '잘 자는 것도 실력입니다. 오늘 수면을 챙기세요.',
      '수면 1시간이 내일의 당신을 더 빛나게 만듭니다.',
      '체력이 곧 자신감입니다. 오늘도 몸을 잘 챙기세요.',
      '몸이 먼저입니다. 건강이 있어야 모든 것이 가능합니다.',
      '피곤함은 노력의 증거, 수면은 그 노력에 대한 보상입니다.',
      '좋은 수면은 최고의 자기 투자입니다.',
      '오늘 충분히 잤다면, 내일은 더 좋은 하루가 될 거예요.',
      '수면의 질이 삶의 질을 바꿉니다.',
      '30분 일찍 잠드는 것이 내일 1시간의 집중력을 만듭니다.',
      '피곤할 때 무리하지 마세요. 쉬는 것도 전략입니다.',
      '규칙적인 수면이 불규칙한 근무를 이기는 방법입니다.',
      '잠을 줄이는 것은 절약이 아니라 낭비입니다.',
      '숙면 한 번이 카페인 열 잔보다 낫습니다.',
      '오늘의 낮잠이 오늘 밤의 안전을 지킵니다.',
      '몸이 보내는 신호를 무시하지 마세요. 쉬어야 할 때는 쉬세요.',

      // 일상·마인드셋
      '불규칙한 일상 속에서도 규칙적인 나를 만드는 것, 그것이 진짜 힘입니다.',
      '쉬는 날에 충분히 쉬는 것도 훌륭한 선택입니다.',
      '힘든 순간일수록 작은 것에서 행복을 찾는 연습을 해보세요.',
      '오늘 힘든 만큼 내일의 나는 더 단단해집니다.',
      '근무 후 나를 위한 작은 보상, 잊지 마세요.',
      '지금 이 순간, 당신은 충분히 잘 하고 있습니다.',
      '완벽하지 않아도 괜찮아요. 꾸준한 것이 완벽보다 낫습니다.',
      '작은 루틴 하나가 하루 전체를 바꿀 수 있습니다.',
      '오늘 하루도 무사히 마쳤다면, 그것만으로 충분합니다.',
      '힘든 날도 지나갑니다. 좋은 날이 반드시 옵니다.',
      '비교하지 마세요. 어제의 나보다 나으면 됩니다.',
      '작은 성취도 성취입니다. 오늘의 나를 칭찬해주세요.',
      '포기하고 싶을 때가 가장 성장에 가까운 순간입니다.',
      '나를 위한 시간은 사치가 아니라 필수입니다.',
      '완벽한 하루는 없지만, 의미 있는 하루는 만들 수 있습니다.',

      // 명언·격언
      '"시작이 반이다." 오늘도 시작한 당신, 이미 반은 해낸 겁니다.',
      '"천 리 길도 한 걸음부터." 오늘 한 걸음이면 충분합니다.',
      '"할 수 있다고 믿으면 이미 반은 이룬 것이다." - 루즈벨트',
      '"성공은 매일 반복한 작은 노력의 합이다." - 로버트 콜리어',
      '"오늘 할 수 있는 일에 최선을 다하라." - 에이브러햄 링컨',
      '"넘어진 것은 실패가 아니다. 넘어진 채 일어나지 않는 것이 실패다."',
      '"인생은 자전거 타기와 같다. 균형을 잡으려면 계속 움직여야 한다." - 아인슈타인',
      '"위대한 일은 갑자기 이루어지지 않는다." - 빈센트 반 고흐',
      '"행복은 습관이다. 그것을 몸에 지니라." - 허바드',
      '"오늘 심은 나무가 내일의 그늘이 된다."',
      '"꿈을 이루는 비결은 시작하는 것이다." - 마크 트웨인',
      '"어두운 밤이 지나면 반드시 밝은 아침이 온다."',
      '"고통이 남긴 것을 보라. 극복한 사람에게는 힘이 남는다." - 프리드리히 실러',
      '"변화를 원한다면 스스로 그 변화가 되어라." - 간디',
      '"매일 조금씩, 꾸준히. 그것이 기적을 만든다."',

      // 실용적 동기부여
      '퇴근 후 10분 스트레칭이 내일의 컨디션을 좌우합니다.',
      '물 한 잔으로 시작하는 아침이 하루를 바꿉니다.',
      '오늘 근무가 끝나면 좋아하는 것 하나를 해보세요.',
      '심호흡 3번이면 마음이 한결 가벼워집니다.',
      '짧은 산책이 긴 고민을 해결해줄 때가 있습니다.',
      '감사한 것 3가지를 떠올리면 하루가 달라집니다.',
      '5분의 명상이 1시간의 걱정을 줄여줍니다.',
      '좋아하는 음악 한 곡이 피로를 녹여줍니다.',
      '가까운 사람에게 안부 한 마디, 나도 힘이 됩니다.',
      '오늘의 식사를 정성껏 챙기세요. 몸이 감사할 거예요.',
      '근무 전 가벼운 준비운동이 하루의 질을 높여줍니다.',
      '카페인보다 효과적인 건 10분 햇빛입니다.',
      '퇴근길 좋아하는 팟캐스트 하나, 작은 행복입니다.',
      '주말에 하고 싶은 것을 미리 정해두면 한 주가 기대됩니다.',
      '오늘 하루를 잘 보냈다면 내일도 그럴 수 있습니다.',

      // 관계·감정
      '힘들 때 도움을 요청하는 것은 약함이 아니라 용기입니다.',
      '당신을 응원하는 사람이 분명히 있습니다.',
      '혼자가 아닙니다. 같은 시간을 견디는 동료가 있습니다.',
      '가족이 자랑스러워할 당신, 오늘도 멋집니다.',
      '웃는 얼굴은 최고의 명함입니다. 오늘 한 번 웃어보세요.',
      '고마운 사람에게 오늘 한 마디 전해보세요.',
      '당신의 노력을 알아주는 사람은 반드시 있습니다.',
      '힘들었던 오늘을 버텨낸 나에게 "수고했어"라고 말해주세요.',
      '주변 사람에게 따뜻한 말 한마디, 나에게도 돌아옵니다.',
      '오늘 만난 모든 사람에게 좋은 영향을 줄 수 있습니다.',

      // 성장·목표
      '지금의 힘든 시간이 미래의 나를 만들고 있습니다.',
      '작은 목표를 세우고 이루는 것부터 시작해보세요.',
      '배움에는 나이도, 시간도 제한이 없습니다.',
      '어제보다 1%만 나아져도 1년이면 37배 성장합니다.',
      '실수에서 배우는 사람은 결국 성공합니다.',
      '꿈은 잊지 마세요. 지금의 노력이 그 꿈의 디딤돌입니다.',
      '성장은 편안한 곳 밖에서 일어납니다.',
      '오늘 읽은 한 페이지가 내일의 나를 바꿉니다.',
      '안 되는 이유보다 되는 방법을 찾는 사람이 됩시다.',
      '지금 하는 일이 미래에 반드시 빛날 날이 옵니다.',
    ];
    final now = DateTime.now();
    // Change quote daily: use day-of-year as seed
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final index = dayOfYear % quotes.length;
    return quotes[index];
  }

  /// Schedule a smart sleep reminder based on shift type.
  /// Returns the scheduled bedtime for chaining (e.g., caffeine cutoff).
  Future<DateTime?> scheduleSmartSleepReminder({
    required int id,
    required String tomorrowShiftType,
    required DateTime date,
    String? shiftStartTime,
  }) async {
    // Calculate recommended bedtime based on tomorrow's shift
    int bedHour;
    int bedMinute = 0;
    String body;

    switch (tomorrowShiftType) {
      case 'day':
        bedHour = 22;
        body = '내일 주간근무, 지금 잠들면 충분한 수면을 확보할 수 있어요';
      case 'evening':
        bedHour = 0; // midnight
        body = '내일 오후근무, 여유 있게 수면을 취하세요';
      case 'night':
        bedHour = 14; // afternoon nap before night shift
        body = '오늘 밤 야간근무, 지금 낮잠으로 체력을 비축하세요';
      case 'off':
        bedHour = 23;
        body = '내일은 휴무! 편하게 쉬되 수면 리듬을 유지하세요';
      default:
        bedHour = 22;
        body = '충분한 수면을 위해 잠자리에 드세요';
    }

    // If we know the actual shift start time, adjust bedtime
    // to ensure ~7 hours of sleep + 1 hour prep
    if (shiftStartTime != null && tomorrowShiftType != 'off') {
      final parts = shiftStartTime.split(':');
      final startHour = int.parse(parts[0]);
      // Bedtime = shift start - 8 hours (7 sleep + 1 prep)
      bedHour = (startHour - 8) % 24;
    }

    var scheduledTime = DateTime(date.year, date.month, date.day, bedHour, bedMinute);
    // For times past midnight (e.g., evening → 00:00), move to next day
    if (tomorrowShiftType == 'evening' && bedHour < 12) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    if (scheduledTime.isBefore(DateTime.now())) return null;

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
      '취침 시간이에요',
      body,
      tzScheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sleep_reminder',
          '수면 리마인더',
          channelDescription: '근무에 맞춘 취침 시간 알림',
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

    return scheduledTime;
  }

  /// Schedule a pre-shift preparation alert (day before night/evening shift)
  Future<void> schedulePreShiftAlert({
    required int id,
    required String tomorrowShiftType,
    required DateTime today,
  }) async {
    // Only for night shifts - recommend afternoon nap
    if (tomorrowShiftType != 'night') return;

    // Alert at 12:00 noon the day before night shift
    final alertTime = DateTime(today.year, today.month, today.day, 12, 0);
    if (alertTime.isBefore(DateTime.now())) return;

    final tzAlert = tz.TZDateTime(
      tz.local,
      alertTime.year,
      alertTime.month,
      alertTime.day,
      alertTime.hour,
      alertTime.minute,
    );

    await _plugin.zonedSchedule(
      id,
      '오늘 밤 야간근무 준비',
      '오후에 90분 이내 낮잠을 추천해요. 카페인은 근무 시작 전에만!',
      tzAlert,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'pre_shift_alert',
          '근무 준비 알림',
          channelDescription: '야간/오후 근무 대비 사전 알림',
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

  /// Schedule a caffeine cutoff notification (6 hours before recommended bedtime)
  Future<void> scheduleCaffeineCutoff({
    required int id,
    required DateTime bedtime,
  }) async {
    final cutoffTime = bedtime.subtract(const Duration(hours: 6));
    if (cutoffTime.isBefore(DateTime.now())) return;

    final tzCutoff = tz.TZDateTime(
      tz.local,
      cutoffTime.year,
      cutoffTime.month,
      cutoffTime.day,
      cutoffTime.hour,
      cutoffTime.minute,
    );

    final bedStr =
        '${bedtime.hour.toString().padLeft(2, '0')}:${bedtime.minute.toString().padLeft(2, '0')}';

    await _plugin.zonedSchedule(
      id,
      '카페인 마감 시간',
      '목표 취침 $bedStr 기준, 지금부터 카페인을 피하세요',
      tzCutoff,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'caffeine_cutoff',
          '카페인 마감 알림',
          channelDescription: '수면을 위한 카페인 마감 시간 알림',
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
    );
  }

  /// Schedule a weekly report notification every Sunday at 20:00
  Future<void> scheduleWeeklyReport({required int id}) async {
    final now = DateTime.now();
    // Find next Sunday
    var nextSunday = now;
    while (nextSunday.weekday != DateTime.sunday) {
      nextSunday = nextSunday.add(const Duration(days: 1));
    }
    final scheduledTime = DateTime(
        nextSunday.year, nextSunday.month, nextSunday.day, 20, 0);
    if (scheduledTime.isBefore(now)) {
      return; // Skip if already past this Sunday 20:00
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
      '이번 주 리포트가 준비됐어요',
      '수면, 에너지, 근무 패턴을 확인해보세요',
      tzScheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_report',
          '주간 리포트',
          channelDescription: '주간 건강·근무 리포트 알림',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
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
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
