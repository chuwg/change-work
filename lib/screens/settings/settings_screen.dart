import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../providers/health_sync_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/sleep_provider.dart';
import '../../models/user_profile.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../utils/constants.dart';
import '../../config/routes.dart';
import 'profile_edit_screen.dart';
import 'shift_times_screen.dart';
import '../../services/export_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _sleepReminder = true;
  bool _shiftReminder = true;
  bool _healthTips = true;
  bool _motivationEnabled = false;
  int _reminderMinutes = 60;
  int _motivationHour = 7;
  int _motivationMinute = 0;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await DatabaseService.instance.getUserProfile();
    if (mounted) setState(() => _profile = profile);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sleepReminder = prefs.getBool(AppConstants.sleepReminderKey) ?? true;
      _shiftReminder = prefs.getBool(AppConstants.shiftReminderKey) ?? true;
      _healthTips = prefs.getBool(AppConstants.healthTipsKey) ?? true;
      _motivationEnabled =
          prefs.getBool(AppConstants.motivationEnabledKey) ?? false;
      _reminderMinutes = prefs.getInt(AppConstants.reminderMinutesKey) ?? 60;
      _motivationHour = prefs.getInt(AppConstants.motivationHourKey) ?? 7;
      _motivationMinute = prefs.getInt(AppConstants.motivationMinuteKey) ?? 0;
    });
  }

  Future<void> _saveSleepReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.sleepReminderKey, value);
    setState(() => _sleepReminder = value);

    if (value) {
      // Schedule smart sleep reminders based on shift schedule
      final schedule = ref.read(scheduleProvider);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (int i = 0; i < 7; i++) {
        final date = today.add(Duration(days: i));
        final tomorrow = date.add(const Duration(days: 1));
        final tomorrowShift = schedule.getShiftForDate(tomorrow);
        final tomorrowType = tomorrowShift?.type ?? 'off';

        final bedtime =
            await NotificationService.instance.scheduleSmartSleepReminder(
          id: 1100 + i,
          tomorrowShiftType: tomorrowType,
          date: date,
          shiftStartTime: tomorrowShift?.startTime,
        );

        if (bedtime != null) {
          await NotificationService.instance.scheduleCaffeineCutoff(
            id: 5000 + i,
            bedtime: bedtime,
          );
        }

        await NotificationService.instance.schedulePreShiftAlert(
          id: 4000 + i,
          tomorrowShiftType: tomorrowType,
          today: date,
        );
      }
    } else {
      // Cancel all smart notification slots
      await NotificationService.instance.cancelNotification(1000);
      for (int i = 0; i < 7; i++) {
        await NotificationService.instance.cancelNotification(1100 + i);
        await NotificationService.instance.cancelNotification(4000 + i);
        await NotificationService.instance.cancelNotification(5000 + i);
      }
    }
  }

  Future<void> _saveShiftReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.shiftReminderKey, value);
    setState(() => _shiftReminder = value);

    // Cancel all previously scheduled shift reminders (slots 0-6)
    for (int slot = 0; slot < 7; slot++) {
      await NotificationService.instance.cancelNotification(2000 + slot);
    }

    if (!value) return;

    // Schedule up to 7 upcoming shifts in advance
    final schedule = ref.read(scheduleProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int slot = 0;
    for (int i = 0; i <= 14 && slot < 7; i++) {
      final date = today.add(Duration(days: i));
      final shift = schedule.getShiftForDate(date);
      if (shift == null ||
          shift.type == AppConstants.shiftOff ||
          shift.startTime == null) continue;
      final parts = shift.startTime!.split(':');
      final shiftStart = DateTime(
        date.year, date.month, date.day,
        int.parse(parts[0]), int.parse(parts[1]),
      );
      await NotificationService.instance.scheduleShiftReminder(
        id: 2000 + slot,
        shiftType: shift.type,
        shiftStart: shiftStart,
        minutesBefore: _reminderMinutes,
      );
      slot++;
    }
  }

  Future<void> _pickCommuteMinutes() async {
    final controller =
        TextEditingController(text: _reminderMinutes.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDarkElevated,
        title: const Text(
          '이동 시간 설정',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '근무지까지 이동하는 데 걸리는 시간을 입력하세요.\n출발 알림이 이 시간에 맞춰 울립니다.',
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                suffixText: '분',
                suffixStyle: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 18),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0 && val <= 300) {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('확인',
                style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
    if (result != null) await _saveReminderMinutes(result);
  }

  Future<void> _saveHealthTips(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.healthTipsKey, value);
    setState(() => _healthTips = value);
  }

  Future<void> _saveMotivation({bool? enabled, int? hour, int? minute}) async {
    final prefs = await SharedPreferences.getInstance();
    final newEnabled = enabled ?? _motivationEnabled;
    final newHour = hour ?? _motivationHour;
    final newMinute = minute ?? _motivationMinute;

    await prefs.setBool(AppConstants.motivationEnabledKey, newEnabled);
    await prefs.setInt(AppConstants.motivationHourKey, newHour);
    await prefs.setInt(AppConstants.motivationMinuteKey, newMinute);

    setState(() {
      if (enabled != null) _motivationEnabled = newEnabled;
      if (hour != null) _motivationHour = newHour;
      if (minute != null) _motivationMinute = newMinute;
    });

    await NotificationService.instance.cancelNotification(3000);
    if (newEnabled) {
      await NotificationService.instance.scheduleDailyMotivation(
        id: 3000,
        body: NotificationService.randomMotivationQuote(),
        hour: newHour,
        minute: newMinute,
      );
    }
  }

  Future<void> _pickMotivationTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _motivationHour, minute: _motivationMinute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              surface: AppTheme.surfaceDarkElevated,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      await _saveMotivation(hour: picked.hour, minute: picked.minute);
    }
  }

  Future<void> _saveReminderMinutes(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.reminderMinutesKey, value);
    setState(() => _reminderMinutes = value);

    // Re-schedule shift reminder with new timing if enabled
    if (_shiftReminder) {
      await _saveShiftReminder(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              '설정',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Profile section
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push<UserProfile>(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ProfileEditScreen()),
                );
                if (result != null) {
                  setState(() => _profile = result);
                }
              },
              child: Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassCard,
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profile?.name ?? '교대근무자',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '프로필 편집',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textTertiary,
                  ),
                ],
              ),
            ),
            ),

            const SizedBox(height: 24),

            // Shift times settings
            _buildSectionHeader('근무 설정'),
            const SizedBox(height: 8),
            Container(
              decoration: AppTheme.glassCard,
              child: _buildActionTile(
                icon: Icons.schedule_rounded,
                title: '근무 시간 설정',
                subtitle: '근무 타입별 시작/종료 시간',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ShiftTimesScreen()),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Salary settings
            _buildSectionHeader('급여 설정'),
            const SizedBox(height: 8),
            Container(
              decoration: AppTheme.glassCard,
              child: Column(
                children: [
                  _buildActionTile(
                    icon: Icons.account_balance_wallet_rounded,
                    title: '급여 설정',
                    subtitle: '시급/월급 및 수당 설정',
                    onTap: () => Navigator.pushNamed(
                        context, AppRoutes.salarySettings),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildActionTile(
                    icon: Icons.bar_chart_rounded,
                    title: '급여 내역',
                    subtitle: '월별 예상 급여 및 수당 내역',
                    onTap: () => Navigator.pushNamed(
                        context, AppRoutes.salary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notification settings
            _buildSectionHeader('알림 설정'),
            const SizedBox(height: 8),
            Container(
              decoration: AppTheme.glassCard,
              child: Column(
                children: [
                  _buildSwitchTile(
                    icon: Icons.bedtime_rounded,
                    title: '스마트 수면 알림',
                    subtitle: '근무 타입에 맞춘 취침·카페인 마감 알림',
                    value: _sleepReminder,
                    onChanged: (v) => _saveSleepReminder(v),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildSwitchTile(
                    icon: Icons.work_rounded,
                    title: '근무 시작 알림',
                    subtitle: '출근 전 미리 알림',
                    value: _shiftReminder,
                    onChanged: (v) => _saveShiftReminder(v),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildSwitchTile(
                    icon: Icons.favorite_rounded,
                    title: '건강 가이드 알림',
                    subtitle: '맞춤 건강 팁 알림',
                    value: _healthTips,
                    onChanged: (v) => _saveHealthTips(v),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildSwitchTile(
                    icon: Icons.format_quote_rounded,
                    title: '오늘의 한 마디',
                    subtitle: '교대근무자를 위한 동기부여 메시지',
                    value: _motivationEnabled,
                    onChanged: (v) => _saveMotivation(enabled: v),
                  ),
                  if (_motivationEnabled) ...[
                    const Divider(height: 1, indent: 56),
                    InkWell(
                      onTap: _pickMotivationTime,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.access_time_rounded,
                                  color: AppTheme.primary, size: 18),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                '알림 시간',
                                style: TextStyle(
                                    color: AppTheme.textPrimary, fontSize: 14),
                              ),
                            ),
                            Text(
                              '${_motivationHour.toString().padLeft(2, '0')}:'
                              '${_motivationMinute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppTheme.textTertiary, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickCommuteMinutes,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.glassCard,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.directions_walk_rounded,
                          color: AppTheme.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '이동 시간',
                            style: TextStyle(
                                color: AppTheme.textPrimary, fontSize: 14),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '근무지까지 걸리는 시간',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$_reminderMinutes분',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.textTertiary, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Health data sync
            _buildSectionHeader('건강 데이터 연동'),
            const SizedBox(height: 8),
            _buildHealthSyncSection(),

            const SizedBox(height: 24),

            // Data management
            _buildSectionHeader('데이터 관리'),
            const SizedBox(height: 8),
            Container(
              decoration: AppTheme.glassCard,
              child: Column(
                children: [
                  _buildActionTile(
                    icon: Icons.download_rounded,
                    title: '데이터 내보내기',
                    subtitle: '근무/수면/에너지 기록을 CSV로 내보내기',
                    onTap: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('CSV 파일 생성 중...')),
                      );
                      try {
                        await ExportService.instance.exportAllDataAsCsv();
                      } catch (_) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('내보내기 중 오류가 발생했습니다')),
                          );
                        }
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildActionTile(
                    icon: Icons.upload_rounded,
                    title: '데이터 가져오기',
                    subtitle: '내보낸 CSV 파일에서 데이터 복원',
                    onTap: () async {
                      try {
                        final counts =
                            await ExportService.instance.importFromCsv();
                        if (counts.isEmpty) return;
                        if (mounted) {
                          final shifts = counts['shifts'] ?? 0;
                          final sleep = counts['sleep'] ?? 0;
                          final energy = counts['energy'] ?? 0;
                          final total = shifts + sleep + energy;
                          final msg = total == 0
                              ? '가져올 새 데이터가 없습니다 (이미 존재하는 데이터)'
                              : '가져오기 완료: 근무 $shifts개, 수면 $sleep개, 에너지 $energy개';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg)),
                          );
                          // Reload providers
                          final now = DateTime.now();
                          ref.read(scheduleProvider.notifier)
                              .loadShiftsForMonth(now.year, now.month);
                          ref.read(sleepProvider.notifier).loadRecords();
                        }
                      } catch (_) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('가져오기 중 오류가 발생했습니다')),
                          );
                        }
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildActionTile(
                    icon: Icons.delete_outline_rounded,
                    title: '데이터 초기화',
                    subtitle: '모든 기록을 삭제합니다',
                    isDestructive: true,
                    onTap: () => _showResetDialog(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // About developer
            _buildSectionHeader('만든 사람'),
            const SizedBox(height: 8),
            Container(
              decoration: AppTheme.glassCard,
              child: InkWell(
                onTap: () => _launchDeveloperPage(),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.code_rounded,
                          color: AppTheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '개발자 소개',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'GitHub에서 프로젝트를 확인하세요',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.open_in_new_rounded,
                        color: AppTheme.textTertiary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // App info
            _buildSectionHeader('앱 정보'),
            const SizedBox(height: 8),
            Container(
              decoration: AppTheme.glassCard,
              child: Column(
                children: [
                  _buildInfoTile('버전', '1.0.4'),
                  const Divider(height: 1, indent: 16),
                  _buildActionTile(
                    icon: Icons.star_outline_rounded,
                    title: '앱 평가하기',
                    onTap: () async {
                      final uri = Uri.parse(
                          'https://apps.apple.com/app/id6759284358?action=write-review');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildActionTile(
                    icon: Icons.mail_outline_rounded,
                    title: '의견 보내기',
                    onTap: () async {
                      final uri = Uri.parse(
                          'https://github.com/chuwg/change-work/issues');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildActionTile(
                    icon: Icons.description_outlined,
                    title: '개인정보처리방침',
                    onTap: () async {
                      final uri = Uri.parse(
                          'https://chuwg.github.io/change-work/privacy.html');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthSyncSection() {
    final healthSync = ref.watch(healthSyncProvider);
    return Container(
      decoration: AppTheme.glassCard,
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.watch_rounded,
            title: '건강 데이터 동기화',
            subtitle: 'Apple Health / Health Connect에서 데이터 가져오기',
            value: healthSync.syncEnabled,
            onChanged: (v) {
              ref.read(healthSyncProvider.notifier).toggleSync(v);
            },
          ),
          if (healthSync.syncEnabled) ...[
            const Divider(height: 1, indent: 56),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      color: AppTheme.textTertiary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      healthSync.lastSyncAt != null
                          ? '마지막 동기화: ${DateFormat('MM/dd HH:mm').format(healthSync.lastSyncAt!)}'
                          : '아직 동기화되지 않음',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, indent: 56),
            _buildActionTile(
              icon: Icons.sync_rounded,
              title: healthSync.isSyncing ? '동기화 중...' : '지금 동기화',
              subtitle: '수면, 걸음 수, 심박수 데이터 가져오기',
              onTap: healthSync.isSyncing
                  ? () {}
                  : () {
                      ref.read(healthSyncProvider.notifier).syncNow();
                    },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 14),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? AppTheme.error : AppTheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDestructive
                          ? AppTheme.error
                          : AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style:
                const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _launchDeveloperPage() async {
    const url = 'https://github.com/chuwg/change-work';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크를 열 수 없습니다')),
        );
      }
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          '데이터 초기화',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          '모든 근무 스케줄과 수면 기록이 삭제됩니다. 이 작업은 되돌릴 수 없습니다.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseService.instance.deleteAllData();
              ref.read(sleepProvider.notifier).loadRecords();
              final now = DateTime.now();
              ref.read(scheduleProvider.notifier).loadShiftsForMonth(now.year, now.month);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('모든 데이터가 초기화되었습니다')),
                );
              }
            },
            child: const Text(
              '초기화',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
