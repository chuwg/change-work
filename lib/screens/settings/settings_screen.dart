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

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _sleepReminder = true;
  bool _shiftReminder = true;
  bool _healthTips = true;
  int _reminderMinutes = 60;
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
      _reminderMinutes = prefs.getInt(AppConstants.reminderMinutesKey) ?? 60;
    });
  }

  Future<void> _saveSleepReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.sleepReminderKey, value);
    setState(() => _sleepReminder = value);

    if (value) {
      // Schedule sleep reminder for tonight at 22:00
      final now = DateTime.now();
      var scheduledTime = DateTime(now.year, now.month, now.day, 22, 0);
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
      await NotificationService.instance.scheduleSleepReminder(
        id: 1000,
        title: '취침 시간이에요',
        body: '충분한 수면을 위해 잠자리에 드세요 🌙',
        scheduledTime: scheduledTime,
      );
    } else {
      await NotificationService.instance.cancelNotification(1000);
    }
  }

  Future<void> _saveShiftReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.shiftReminderKey, value);
    setState(() => _shiftReminder = value);

    if (value) {
      final schedule = ref.read(scheduleProvider);
      final nextShift = schedule.nextShift;
      if (nextShift != null && nextShift.startTime != null) {
        final parts = nextShift.startTime!.split(':');
        final shiftStart = DateTime(
          nextShift.date.year,
          nextShift.date.month,
          nextShift.date.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
        await NotificationService.instance.scheduleShiftReminder(
          id: 2000,
          shiftType: nextShift.type,
          shiftStart: shiftStart,
          minutesBefore: _reminderMinutes,
        );
      }
    } else {
      await NotificationService.instance.cancelNotification(2000);
    }
  }

  Future<void> _saveHealthTips(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.healthTipsKey, value);
    setState(() => _healthTips = value);
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
                    title: '수면 리마인더',
                    subtitle: '취침 시간에 맞춰 알림',
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
                ],
              ),
            ),

            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassCard,
              child: Row(
                children: [
                  const Icon(Icons.timer_rounded,
                      color: AppTheme.primary, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '출근 전 알림 시간',
                      style: TextStyle(
                          color: AppTheme.textPrimary, fontSize: 14),
                    ),
                  ),
                  DropdownButton<int>(
                    value: _reminderMinutes,
                    dropdownColor: AppTheme.surfaceDarkElevated,
                    underline: const SizedBox(),
                    style: const TextStyle(
                        color: AppTheme.primary, fontSize: 14),
                    items: const [
                      DropdownMenuItem(value: 30, child: Text('30분 전')),
                      DropdownMenuItem(value: 60, child: Text('1시간 전')),
                      DropdownMenuItem(value: 90, child: Text('1시간 30분 전')),
                      DropdownMenuItem(value: 120, child: Text('2시간 전')),
                    ],
                    onChanged: (v) {
                      if (v != null) _saveReminderMinutes(v);
                    },
                  ),
                ],
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
                    subtitle: '수면/근무 기록을 CSV로 내보내기',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('데이터 내보내기 준비 중...')),
                      );
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
                  _buildInfoTile('버전', '1.0.0'),
                  const Divider(height: 1, indent: 16),
                  _buildActionTile(
                    icon: Icons.star_outline_rounded,
                    title: '앱 평가하기',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildActionTile(
                    icon: Icons.mail_outline_rounded,
                    title: '의견 보내기',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildActionTile(
                    icon: Icons.description_outlined,
                    title: '개인정보처리방침',
                    onTap: () {},
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
