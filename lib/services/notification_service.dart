import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'notification_plan.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Android 14+ denies SCHEDULE_EXACT_ALARM by default, and the plugin throws
  /// instead of scheduling. Remember that so we stop paying for a failed exact
  /// attempt on every single reschedule.
  bool _exactAlarmsBlocked = false;

  /// Schedule [id], preferring an exact alarm and degrading to an inexact one
  /// when the OS refuses. Without this every zonedSchedule call throws on
  /// Android 12+ (no SCHEDULE_EXACT_ALARM grant) and no notification is set.
  Future<void> _schedule(
    int id,
    String title,
    String body,
    tz.TZDateTime when,
    NotificationDetails details, {
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    Future<void> run(AndroidScheduleMode mode) => _plugin.zonedSchedule(
          id,
          title,
          body,
          when,
          details,
          androidScheduleMode: mode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: matchDateTimeComponents,
        );

    if (!_exactAlarmsBlocked) {
      try {
        await run(AndroidScheduleMode.exactAllowWhileIdle);
        return;
      } on PlatformException catch (e) {
        if (e.code != 'exact_alarms_not_permitted') rethrow;
        _exactAlarmsBlocked = true;
      }
    }
    await run(AndroidScheduleMode.inexactAllowWhileIdle);
  }

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

    await _schedule(
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

  /// Schedule a weekly report notification every Sunday at 20:00
  Future<void> scheduleWeeklyReport({required int id}) async {
    final now = DateTime.now();
    // Find the next Sunday 20:00 that is still ahead of us. Returning early
    // when this Sunday's slot has passed meant an app opened on a Sunday
    // evening never got a weekly report scheduled at all.
    var nextSunday = DateTime(now.year, now.month, now.day);
    while (nextSunday.weekday != DateTime.sunday) {
      nextSunday = nextSunday.add(const Duration(days: 1));
    }
    var scheduledTime = DateTime(
        nextSunday.year, nextSunday.month, nextSunday.day, 20, 0);
    if (!scheduledTime.isAfter(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 7));
    }

    final tzScheduled = tz.TZDateTime(
      tz.local,
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    await _schedule(
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
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Put one planned notification into the OS queue.
  Future<void> schedulePlanned(PlannedNotification planned) async {
    await _schedule(
      planned.id,
      planned.title,
      planned.body,
      tz.TZDateTime.from(planned.time, tz.local),
      _detailsFor(planned.kind),
    );
  }

  static NotificationDetails _detailsFor(NotificationKind kind) {
    switch (kind) {
      case NotificationKind.shiftStart:
        return _details('shift_reminder', '근무 알림', '근무 시작 전 알림');
      case NotificationKind.bedtime:
        return _details('sleep_reminder', '수면 리마인더', '근무에 맞춘 취침 시간 알림');
      case NotificationKind.caffeineCutoff:
        return _details('caffeine_cutoff', '카페인 마감 알림', '수면을 위한 카페인 마감 시간 알림',
            high: false);
      case NotificationKind.preShiftNap:
        return _details('pre_shift_alert', '근무 준비 알림', '야간/오후 근무 대비 사전 알림');
    }
  }

  static NotificationDetails _details(
    String channelId,
    String channelName,
    String description, {
    bool high = true,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: description,
        importance: high ? Importance.high : Importance.defaultImportance,
        priority: high ? Priority.high : Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: high,
        presentSound: true,
      ),
    );
  }

  /// Whether notifications are allowed, and (Android only) whether exact
  /// alarms are permitted. Null means "the platform does not report it".
  Future<NotificationStatus> checkStatus() async {
    bool? enabled;
    bool? exactAlarms;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      enabled = await android.areNotificationsEnabled();
      exactAlarms = await android.canScheduleExactNotifications();
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      enabled = (await ios.checkPermissions())?.isEnabled;
    }

    final pending = await _plugin.pendingNotificationRequests();
    return NotificationStatus(
      notificationsEnabled: enabled,
      exactAlarmsAllowed: exactAlarms,
      pendingCount: pending.length,
    );
  }

  /// Send the user to the OS screen where exact alarms can be granted.
  /// Android-only; a no-op elsewhere.
  Future<void> requestExactAlarms() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
    // The user may have just granted it — stop assuming exact alarms fail.
    _exactAlarmsBlocked = false;
  }

  /// Fire a notification right now so the user can confirm delivery works.
  Future<void> sendTestNotification() async {
    await _plugin.show(
      9999,
      '알림이 정상 동작합니다',
      '근무·취침 알림도 이렇게 도착합니다',
      _details('shift_reminder', '근무 알림', '근무 시작 전 알림'),
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}

/// Snapshot of what the OS currently allows and holds.
class NotificationStatus {
  /// Null when the platform does not report it.
  final bool? notificationsEnabled;

  /// Android only. False means reminders may drift by several minutes.
  final bool? exactAlarmsAllowed;

  /// How many notifications the OS currently has queued for this app.
  final int pendingCount;

  const NotificationStatus({
    required this.notificationsEnabled,
    required this.exactAlarmsAllowed,
    required this.pendingCount,
  });
}
