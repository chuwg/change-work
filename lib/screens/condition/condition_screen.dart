import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/sleep_provider.dart';
import '../../providers/energy_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/health_sync_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/health_tip_card.dart';
import '../../widgets/sleep_chart.dart';

class ConditionScreen extends ConsumerStatefulWidget {
  const ConditionScreen({super.key});

  @override
  ConsumerState<ConditionScreen> createState() => _ConditionScreenState();
}

class _ConditionScreenState extends ConsumerState<ConditionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      await ref.read(sleepProvider.notifier).loadRecords();
      await ref.read(energyProvider.notifier).loadRecords();
      await ref.read(healthProvider.notifier).refreshHealthData();
      // Auto-sync from HealthKit when enabled
      final healthSync = ref.read(healthSyncProvider);
      if (healthSync.syncEnabled && !healthSync.isSyncing) {
        ref.read(healthSyncProvider.notifier).syncNow();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final sleep = ref.watch(sleepProvider);
    final energy = ref.watch(energyProvider);
    final health = ref.watch(healthProvider);
    final healthSync = ref.watch(healthSyncProvider);
    final schedule = ref.watch(scheduleProvider);

    // Compute condition score
    final conditionScore = _computeConditionScore(sleep, energy, healthSync);

    // Data-driven tips only (priority 0 and 1)
    final insightTips =
        health.currentTips.where((t) => t.priority <= 1).toList();

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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '컨디션',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          if (healthSync.syncEnabled && healthSync.isSyncing)
                            const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          IconButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/circadian'),
                            icon: const Icon(Icons.access_time_rounded,
                                color: AppTheme.textSecondary, size: 22),
                            tooltip: '서카디안 리듬',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Today's Condition Score
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _buildConditionScoreCard(
                      conditionScore, sleep, energy, healthSync, health),
                ),
              ),

              // Yesterday's Sleep Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _buildSleepCard(sleep, healthSync),
                ),
              ),

              // Today's Energy Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _buildEnergyCard(energy, schedule),
                ),
              ),

              // Health Sync CTA (if not enabled)
              if (!healthSync.syncEnabled)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _buildHealthSyncCTA(),
                  ),
                ),

              // Insights (data-driven tips)
              if (insightTips.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Text(
                      '오늘의 인사이트',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 4),
                        child: HealthTipCard(
                          tip: insightTips[index],
                          expanded: true,
                        ),
                      );
                    },
                    childCount: insightTips.length.clamp(0, 4),
                  ),
                ),
              ],

              // Weekly Trend
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildWeeklyTrend(sleep, energy),
                ),
              ),

              // Quick Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.bedtime_rounded,
                          label: '수면 기록',
                          color: const Color(0xFF7E57C2),
                          onTap: () =>
                              Navigator.pushNamed(context, '/sleep-tracker'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.bolt_rounded,
                          label: '에너지 기록',
                          color: AppTheme.primary,
                          onTap: () =>
                              Navigator.pushNamed(context, '/energy-tracker'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.favorite_rounded,
                          label: '건강 가이드',
                          color: const Color(0xFFE07B7B),
                          onTap: () =>
                              Navigator.pushNamed(context, '/health-coach'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  // --- Condition Score Card ---
  Widget _buildConditionScoreCard(
    int score,
    SleepState sleep,
    EnergyState energy,
    HealthSyncState healthSync,
    HealthState health,
  ) {
    final scoreColor = score >= 80
        ? AppTheme.success
        : score >= 60
            ? AppTheme.warning
            : AppTheme.error;
    final scoreLabel = score >= 80
        ? '좋음'
        : score >= 60
            ? '보통'
            : '주의';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scoreColor.withValues(alpha: 0.15),
            scoreColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scoreColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Score circle
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 6,
                  backgroundColor: scoreColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(scoreColor),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    Text(
                      scoreLabel,
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Metrics row
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(
                  icon: Icons.bedtime_rounded,
                  label: '수면',
                  value: sleep.todayRecord != null
                      ? '${sleep.todayRecord!.durationHours.toStringAsFixed(1)}h'
                      : sleep.averageSleepHours > 0
                          ? '${sleep.averageSleepHours.toStringAsFixed(1)}h'
                          : '--',
                  color: const Color(0xFF7E57C2),
                ),
                _buildMetric(
                  icon: Icons.bolt_rounded,
                  label: '에너지',
                  value: energy.todayAverageEnergy > 0
                      ? '${energy.todayAverageEnergy.toStringAsFixed(1)}'
                      : '--',
                  color: AppTheme.primary,
                ),
                _buildMetric(
                  icon: Icons.directions_walk_rounded,
                  label: '걸음',
                  value: healthSync.todaySteps != null
                      ? _formatSteps(healthSync.todaySteps!)
                      : '--',
                  color: const Color(0xFF4CAF50),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  // --- Sleep Card ---
  Widget _buildSleepCard(SleepState sleep, HealthSyncState healthSync) {
    final record = sleep.todayRecord;
    final hasHealthSync = healthSync.syncEnabled;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bedtime_rounded,
                      color: Color(0xFF7E57C2), size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    '오늘의 수면',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (record?.source == 'healthkit' ||
                      record?.source == 'health_connect')
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.watch_rounded,
                                size: 10,
                                color:
                                    AppTheme.primary.withValues(alpha: 0.7)),
                            const SizedBox(width: 3),
                            Text(
                              '자동',
                              style: TextStyle(
                                color:
                                    AppTheme.primary.withValues(alpha: 0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, '/sleep-stats'),
                child: const Text(
                  '통계',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (record != null) ...[
            Row(
              children: [
                Text(
                  AppHelpers.formatDuration(record.duration),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: [
                      _buildSleepStat(
                          '취침', AppHelpers.formatTime(record.bedTime)),
                      const SizedBox(width: 16),
                      _buildSleepStat(
                          '기상', AppHelpers.formatTime(record.wakeTime)),
                      const SizedBox(width: 16),
                      _buildSleepStat('품질',
                          AppHelpers.getSleepQualityLabel(record.quality)),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '아직 기록이 없어요',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (!hasHealthSync)
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/sleep-tracker'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('기록하기'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  )
                else
                  const Text(
                    '동기화 대기 중',
                    style: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSleepStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textTertiary, fontSize: 10),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // --- Energy Card ---
  Widget _buildEnergyCard(EnergyState energy, ScheduleState schedule) {
    final latest = energy.latestToday;
    final avg = energy.todayAverageEnergy;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: AppTheme.primary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '오늘의 에너지',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, '/energy-stats'),
                child: const Text(
                  '통계',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (latest != null) ...[
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppHelpers.getEnergyColor(latest.energyLevel)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    AppHelpers.getEnergyIcon(latest.energyLevel),
                    color: AppHelpers.getEnergyColor(latest.energyLevel),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppHelpers.getEnergyLabel(latest.energyLevel),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${AppHelpers.formatTime(latest.timestamp)} 기록 '
                        '${energy.todayRecords.length > 1 ? "· 평균 ${avg.toStringAsFixed(1)}/5" : ""}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildQuickEnergyInput(schedule),
              ],
            ),
          ] else ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '오늘의 에너지를 기록해보세요',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
                _buildQuickEnergyInput(schedule),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickEnergyInput(ScheduleState schedule) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final level = i + 1;
        return GestureDetector(
          onTap: () {
            final todayShift = schedule.todayShift;
            ref.read(energyProvider.notifier).addEnergyRecord(
                  energyLevel: level,
                  shiftType: todayShift?.type,
                  source: 'quick',
                );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppHelpers.getEnergyColor(level)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$level',
                  style: TextStyle(
                    color: AppHelpers.getEnergyColor(level),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // --- Health Sync CTA ---
  Widget _buildHealthSyncCTA() {
    return GestureDetector(
      onTap: () async {
        await ref.read(healthSyncProvider.notifier).toggleSync(true);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.watch_rounded,
                  color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '건강 데이터 자동 연동',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    Platform.isIOS
                        ? 'Apple Watch에서 수면 데이터를 자동으로 가져옵니다'
                        : 'Health Connect에서 수면 데이터를 자동으로 가져옵니다',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  // --- Weekly Trend ---
  Widget _buildWeeklyTrend(SleepState sleep, EnergyState energy) {
    final hasData = sleep.last7Days.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '주간 수면 추이',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (hasData)
            SizedBox(
              height: 160,
              child: SleepBarChart(records: sleep.last7Days),
            )
          else
            const SizedBox(
              height: 80,
              child: Center(
                child: Text(
                  '수면 데이터가 쌓이면 주간 추이를 보여드립니다',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- Quick Action Button ---
  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---
  int _computeConditionScore(
    SleepState sleep,
    EnergyState energy,
    HealthSyncState healthSync,
  ) {
    double score = 50;
    int factors = 0;

    // Sleep factor (40% weight)
    if (sleep.todayRecord != null) {
      final hours = sleep.todayRecord!.durationHours;
      final quality = sleep.todayRecord!.quality;
      double sleepScore;
      if (hours >= 7 && hours <= 9) {
        sleepScore = 90;
      } else if (hours >= 6) {
        sleepScore = 70;
      } else if (hours >= 5) {
        sleepScore = 50;
      } else {
        sleepScore = 30;
      }
      sleepScore += (quality - 3) * 5;
      score = sleepScore * 0.4;
      factors++;
    } else if (sleep.averageSleepHours > 0) {
      final avgScore = sleep.averageSleepHours >= 7 ? 75.0 : 50.0;
      score = avgScore * 0.4;
      factors++;
    }

    // Energy factor (35% weight)
    if (energy.todayAverageEnergy > 0) {
      final energyScore = (energy.todayAverageEnergy / 5) * 100;
      score += energyScore * 0.35;
      factors++;
    }

    // Activity factor (25% weight)
    if (healthSync.todaySteps != null && healthSync.todaySteps! > 0) {
      final steps = healthSync.todaySteps!;
      double activityScore;
      if (steps >= 8000) {
        activityScore = 90;
      } else if (steps >= 5000) {
        activityScore = 70;
      } else if (steps >= 3000) {
        activityScore = 50;
      } else {
        activityScore = 30;
      }
      score += activityScore * 0.25;
      factors++;
    }

    if (factors == 0) return 50;
    // Normalize if not all factors are present
    if (factors < 3) {
      score = score / (factors == 1 ? 0.4 : factors == 2 ? 0.75 : 1.0);
    }

    return score.round().clamp(0, 100);
  }

  String _formatSteps(int steps) {
    if (steps >= 10000) {
      return '${(steps / 10000).toStringAsFixed(1)}만';
    }
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}천';
    }
    return steps.toString();
  }
}
