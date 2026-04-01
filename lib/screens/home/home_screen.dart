import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/sleep_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/energy_provider.dart';
import '../../providers/salary_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../../widgets/shift_card.dart';
import '../../widgets/health_tip_card.dart';
import '../../widgets/salary_summary_card.dart';
import '../../providers/health_sync_provider.dart';
import '../../providers/tab_provider.dart';
import '../../services/notification_service.dart';
import '../../config/routes.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      final now = DateTime.now();
      await ref
          .read(scheduleProvider.notifier)
          .loadShiftsForMonth(now.year, now.month);
      await ref.read(sleepProvider.notifier).loadRecords();
      await ref.read(energyProvider.notifier).loadRecords();
      await ref.read(healthProvider.notifier).refreshHealthData();
      await ref.read(salaryProvider.notifier).loadSettings();
      await ref
          .read(salaryProvider.notifier)
          .calculateForMonth(now.year, now.month);

      // Reschedule shift reminder with latest schedule data
      await _rescheduleShiftReminder();
      // Reschedule smart sleep/caffeine/pre-shift notifications
      await _rescheduleSmartNotifications();
      // Reschedule motivation notification with new random quote
      await _rescheduleMotivationNotification();
      // Schedule weekly report notification (every Sunday 20:00)
      await NotificationService.instance.scheduleWeeklyReport(id: 6000);

      // Auto-sync sleep from HealthKit/Health Connect if enabled
      // Run in background to not block UI
      ref.read(healthSyncProvider.notifier).autoSync();
    } catch (_) {
      // DB not available on web — load health tips only
      await ref.read(healthProvider.notifier).refreshHealthData();
    }
  }

  Future<void> _rescheduleMotivationNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled =
          prefs.getBool(AppConstants.motivationEnabledKey) ?? false;
      if (!enabled) return;
      final hour = prefs.getInt(AppConstants.motivationHourKey) ?? 7;
      final minute = prefs.getInt(AppConstants.motivationMinuteKey) ?? 0;
      await NotificationService.instance.scheduleDailyMotivation(
        id: 3000,
        body: NotificationService.randomMotivationQuote(),
        hour: hour,
        minute: minute,
      );
    } catch (_) {}
  }

  Future<void> _rescheduleShiftReminder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(AppConstants.shiftReminderKey) ?? true;
      final minutesBefore =
          prefs.getInt(AppConstants.reminderMinutesKey) ?? 60;
      final schedule = ref.read(scheduleProvider);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Cancel all previously scheduled shift reminders (slots 0-6)
      for (int slot = 0; slot < 7; slot++) {
        await NotificationService.instance.cancelNotification(2000 + slot);
      }

      if (!enabled) return;

      // Schedule up to 7 upcoming shifts in advance
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

        // scheduleShiftReminder internally skips if reminder time is past
        await NotificationService.instance.scheduleShiftReminder(
          id: 2000 + slot,
          shiftType: shift.type,
          shiftStart: shiftStart,
          minutesBefore: minutesBefore,
        );
        slot++;
      }
    } catch (_) {}
  }

  Future<void> _rescheduleSmartNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sleepEnabled = prefs.getBool(AppConstants.sleepReminderKey) ?? true;
      if (!sleepEnabled) {
        // Cancel all smart sleep/caffeine/pre-shift slots
        for (int i = 0; i < 7; i++) {
          await NotificationService.instance.cancelNotification(1100 + i);
          await NotificationService.instance.cancelNotification(4000 + i);
          await NotificationService.instance.cancelNotification(5000 + i);
        }
        return;
      }

      final schedule = ref.read(scheduleProvider);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (int i = 0; i < 7; i++) {
        final date = today.add(Duration(days: i));
        final tomorrow = date.add(const Duration(days: 1));
        final tomorrowShift = schedule.getShiftForDate(tomorrow);
        final tomorrowType = tomorrowShift?.type ?? 'off';

        // Smart sleep reminder
        final bedtime =
            await NotificationService.instance.scheduleSmartSleepReminder(
          id: 1100 + i,
          tomorrowShiftType: tomorrowType,
          date: date,
          shiftStartTime: tomorrowShift?.startTime,
        );

        // Caffeine cutoff (6h before bedtime)
        if (bedtime != null) {
          await NotificationService.instance.scheduleCaffeineCutoff(
            id: 5000 + i,
            bedtime: bedtime,
          );
        }

        // Pre-shift alert (noon before night shift)
        await NotificationService.instance.schedulePreShiftAlert(
          id: 4000 + i,
          tomorrowShiftType: tomorrowType,
          today: date,
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(scheduleProvider);
    final sleep = ref.watch(sleepProvider);
    final health = ref.watch(healthProvider);
    final energy = ref.watch(energyProvider);
    final healthSync = ref.watch(healthSyncProvider);
    final todayShift = schedule.todayShift;
    final now = DateTime.now();

    // Energy: use actual or estimate from sleep
    final hasEnergyToday = energy.todayAverageEnergy > 0;
    final todaySleep = sleep.todayRecord;
    final isEnergyEstimated = !hasEnergyToday && todaySleep != null;
    final energyLevel = isEnergyEstimated
        ? _estimateEnergy(todaySleep!.durationHours, todaySleep.quality)
        : (energy.latestToday?.energyLevel ?? energy.todayAverageEnergy.round());
    final hasEnergy = isEnergyEstimated || hasEnergyToday;

    // Data-driven tips only (priority ≤ 1), max 2
    final dataTips = health.currentTips
        .where((t) => t.priority <= 1)
        .take(2)
        .toList();

    // Show salary card only after 20th of month
    final showSalary = now.day >= 20;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.primary,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppHelpers.getGreeting(),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Change',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Today's Shift Card
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: TodayShiftCard(
                    shift: todayShift,
                    daysUntilOff: schedule.daysUntilNextOff,
                  ),
                ),
              ),

              // Compact Metrics Row (sleep | energy | rhythm)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDarkElevated.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Sleep
                        Expanded(
                          child: _buildMetricItem(
                            icon: Icons.bedtime_rounded,
                            color: sleep.averageSleepHours >= 7
                                ? AppTheme.success
                                : AppTheme.warning,
                            label: '수면',
                            value: sleep.averageSleepHours > 0
                                ? '${sleep.averageSleepHours.toStringAsFixed(1)}h'
                                : '--',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        // Energy
                        Expanded(
                          child: _buildMetricItem(
                            icon: Icons.bolt_rounded,
                            color: hasEnergy
                                ? AppHelpers.getEnergyColor(energyLevel.clamp(1, 5))
                                : AppTheme.textTertiary,
                            label: isEnergyEstimated ? '에너지 추정' : '에너지',
                            value: hasEnergy
                                ? AppHelpers.getEnergyLabel(energyLevel.clamp(1, 5))
                                : '--',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        // Circadian rhythm score
                        Expanded(
                          child: _buildMetricItem(
                            icon: Icons.schedule_rounded,
                            color: health.circadianScore >= 80
                                ? AppTheme.success
                                : health.circadianScore >= 60
                                    ? AppTheme.warning
                                    : AppTheme.error,
                            label: '리듬',
                            value: '${health.circadianScore.toInt()}점',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Quick Energy Input (show when no energy logged today)
              if (!hasEnergyToday)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt_rounded,
                              color: AppTheme.primary, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            '지금 에너지는?',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          ...List.generate(5, (i) {
                            final level = i + 1;
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: GestureDetector(
                                onTap: () async {
                                  final scheduleState = ref.read(scheduleProvider);
                                  final shiftType = scheduleState.todayShift?.type;
                                  await ref.read(energyProvider.notifier).addEnergyRecord(
                                    energyLevel: level,
                                    shiftType: shiftType,
                                  );
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppHelpers.getEnergyColor(level)
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$level',
                                      style: TextStyle(
                                        color: AppHelpers.getEnergyColor(level),
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),

              // Activity Data (when sync enabled)
              if (healthSync.syncEnabled)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDarkElevated.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildMetricItem(
                              icon: Icons.directions_walk_rounded,
                              color: const Color(0xFF4CAF50),
                              label: '걸음',
                              value: healthSync.todaySteps != null
                                  ? _formatNumber(healthSync.todaySteps!)
                                  : '--',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          Expanded(
                            child: _buildMetricItem(
                              icon: Icons.favorite_rounded,
                              color: const Color(0xFFE57373),
                              label: '심박수',
                              value: healthSync.lastHeartRate != null
                                  ? '${healthSync.lastHeartRate!.round()}'
                                  : '--',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Upcoming Shifts
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '이번 주 근무',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(tabIndexProvider.notifier).state = 1;
                        },
                        child: const Text('전체보기'),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      final date =
                          DateTime.now().add(Duration(days: index));
                      final shift = schedule.getShiftForDate(date);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ShiftDayChip(
                          date: date,
                          shift: shift,
                          isToday: index == 0,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Weekly Report Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.weeklyReport),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.assessment_rounded,
                                color: AppTheme.primary, size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '주간 리포트',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '수면·에너지·근무 패턴 분석',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppTheme.primary, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Salary Summary Card (only near month-end)
              if (showSalary)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: SalarySummaryCard(),
                  ),
                ),

              // Data-driven Health Tips (max 2, priority ≤ 1)
              if (dataTips.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.tips_and_updates_rounded,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '맞춤 건강 팁',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (dataTips.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 4),
                        child: HealthTipCard(tip: dataTips[index]),
                      );
                    },
                    childCount: dataTips.length,
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  /// Estimate energy level (1-5) from sleep data
  int _estimateEnergy(double sleepHours, int quality) {
    final hoursScore = sleepHours >= 8
        ? 5.0
        : sleepHours >= 7
            ? 4.0
            : sleepHours >= 6
                ? 3.0
                : sleepHours >= 5
                    ? 2.0
                    : 1.0;
    return (hoursScore * 0.6 + quality * 0.4).round().clamp(1, 5);
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}
