import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/sleep_provider.dart';
import '../../providers/health_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/shift_card.dart';
import '../../widgets/health_tip_card.dart';
import '../../widgets/sleep_summary_card.dart';
import '../../widgets/circadian_mini_clock.dart';
import '../../providers/health_sync_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final now = DateTime.now();
      await ref
          .read(scheduleProvider.notifier)
          .loadShiftsForMonth(now.year, now.month);
      await ref.read(sleepProvider.notifier).loadRecords();
      await ref.read(healthProvider.notifier).refreshHealthData();
    } catch (_) {
      // DB not available on web — load health tips only
      await ref.read(healthProvider.notifier).refreshHealthData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(scheduleProvider);
    final sleep = ref.watch(sleepProvider);
    final health = ref.watch(healthProvider);
    final healthSync = ref.watch(healthSyncProvider);
    final todayShift = schedule.todayShift;

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

              // Quick Stats Row
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: SleepSummaryCard(
                          averageHours: sleep.averageSleepHours,
                          averageQuality: sleep.averageQuality,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CircadianMiniClock(
                          phase: health.currentPhase,
                          score: health.circadianScore,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Activity Data (when sync enabled)
              if (healthSync.syncEnabled)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildActivityMiniCard(
                            icon: Icons.directions_walk_rounded,
                            label: '걸음 수',
                            value: healthSync.todaySteps != null
                                ? '${_formatNumber(healthSync.todaySteps!)}걸음'
                                : '--',
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActivityMiniCard(
                            icon: Icons.favorite_rounded,
                            label: '심박수',
                            value: healthSync.lastHeartRate != null
                                ? '${healthSync.lastHeartRate!.round()} BPM'
                                : '--',
                            color: const Color(0xFFE57373),
                          ),
                        ),
                      ],
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
                          // Navigate to calendar tab
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

              // Health Tips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '건강 코치',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '가이드',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= health.currentTips.length) return null;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      child: HealthTipCard(tip: health.currentTips[index]),
                    );
                  },
                  childCount: health.currentTips.length.clamp(0, 4),
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

  Widget _buildActivityMiniCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.glassCard,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}
