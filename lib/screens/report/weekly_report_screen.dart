import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';
import '../../providers/sleep_provider.dart';
import '../../providers/energy_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../services/weekly_report.dart';
import '../../models/energy_record.dart';
import '../../services/pattern_insights.dart';
import '../../providers/health_sync_provider.dart';
import '../../utils/helpers.dart';

class WeeklyReportScreen extends ConsumerWidget {
  const WeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleep = ref.watch(sleepProvider);
    final energy = ref.watch(energyProvider);
    final schedule = ref.watch(scheduleProvider);
    final healthSync = ref.watch(healthSyncProvider);

    // Per *day*, not per record: sleep is stored one row per session and a
    // split-sleep day would otherwise count twice — including in the sleep
    // debt target, which told well-rested shift workers they were behind.
    final weeklySleep = sleep.last7DaysByDay;
    final weeklyEnergy = energy.last7Days;

    final stats = WeeklyStats.from(
      sleepDays: weeklySleep,
      energy: weeklyEnergy,
    );
    final avgSleepHours = stats.avgSleepHours;
    final avgSleepQuality = stats.avgSleepQuality;
    final avgEnergy = stats.avgEnergy;
    final sleepDebt = stats.sleepDebt;
    final bestSleep = stats.bestSleepDay;
    final worstSleep = stats.worstSleepDay;

    // Shift type counts this week
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    int dayCount = 0, eveningCount = 0, nightCount = 0, offCount = 0;
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final shift = schedule.getShiftForDate(date);
      if (shift == null || shift.type == 'off') {
        offCount++;
      } else if (shift.type == 'day') {
        dayCount++;
      } else if (shift.type == 'evening') {
        eveningCount++;
      } else if (shift.type == 'night') {
        nightCount++;
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '주간 리포트',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Period header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '${_formatDate(weekStart)} ~ ${_formatDate(weekStart.add(const Duration(days: 6)))}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  stats.grade,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _messageForGrade(stats.grade),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Shift summary
          _buildSectionTitle('근무 패턴'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.glassCard,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildShiftCount(
                    '주간', dayCount, AppHelpers.getShiftColor('day')),
                _buildShiftCount(
                    '오후', eveningCount, AppHelpers.getShiftColor('evening')),
                _buildShiftCount(
                    '야간', nightCount, AppHelpers.getShiftColor('night')),
                _buildShiftCount(
                    '휴무', offCount, AppHelpers.getShiftColor('off')),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Sleep summary
          _buildSectionTitle('수면 분석'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.glassCard,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        '평균 수면',
                        avgSleepHours > 0
                            ? '${avgSleepHours.toStringAsFixed(1)}시간'
                            : '--',
                        avgSleepHours >= 7
                            ? AppTheme.success
                            : AppTheme.warning,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        '평균 질',
                        avgSleepQuality > 0
                            ? '${avgSleepQuality.toStringAsFixed(1)}/5'
                            : '--',
                        avgSleepQuality >= 3.5
                            ? AppTheme.success
                            : AppTheme.warning,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        '수면 부채',
                        sleepDebt > 0
                            ? '${sleepDebt.toStringAsFixed(1)}h'
                            : '없음',
                        sleepDebt <= 3 ? AppTheme.success : AppTheme.error,
                      ),
                    ),
                  ],
                ),
                if (weeklySleep.isNotEmpty) ...[
                  const Divider(color: Colors.white12, height: 24),
                  // Sleep chart
                  SizedBox(
                    height: 150,
                    child: BarChart(
                      BarChartData(
                        barGroups: _buildSleepBars(stats, weekStart),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const days = [
                                  '월',
                                  '화',
                                  '수',
                                  '목',
                                  '금',
                                  '토',
                                  '일'
                                ];
                                final idx = value.toInt();
                                if (idx < 0 || idx >= 7) return const Text('');
                                return Text(
                                  days[idx],
                                  style: TextStyle(
                                    color: AppTheme.textTertiary,
                                    fontSize: 11,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barTouchData: BarTouchData(enabled: false),
                      ),
                    ),
                  ),
                ],
                if (bestSleep != null && worstSleep != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMiniInsight(
                          Icons.arrow_upward_rounded,
                          AppTheme.success,
                          '최고: ${_weekdayName(bestSleep.date)} ${bestSleep.totalHours.toStringAsFixed(1)}h',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMiniInsight(
                          Icons.arrow_downward_rounded,
                          AppTheme.error,
                          '최저: ${_weekdayName(worstSleep.date)} ${worstSleep.totalHours.toStringAsFixed(1)}h',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Energy summary
          _buildSectionTitle('에너지 분석'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.glassCard,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        '평균 에너지',
                        avgEnergy > 0
                            ? '${avgEnergy.toStringAsFixed(1)}/5'
                            : '--',
                        avgEnergy >= 3 ? AppTheme.success : AppTheme.warning,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        '기록 횟수',
                        '${weeklyEnergy.length}회',
                        AppTheme.primary,
                      ),
                    ),
                    if (healthSync.syncEnabled)
                      Expanded(
                        child: _buildStatItem(
                          '걸음 수',
                          healthSync.todaySteps != null
                              ? '${_formatNumber(healthSync.todaySteps!)}'
                              : '--',
                          const Color(0xFF4CAF50),
                        ),
                      ),
                  ],
                ),
                // Shift-specific energy insight
                if (energy.avgByShiftType.isNotEmpty) ...[
                  const Divider(color: Colors.white12, height: 24),
                  ...energy.avgByShiftType.entries.map((e) {
                    final label = AppHelpers.getShiftLabel(e.key);
                    final color = AppHelpers.getShiftColor(e.key);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$label 평균 에너지',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${e.value.toStringAsFixed(1)}/5',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Personalized insights
          _buildSectionTitle('이번 주 인사이트'),
          const SizedBox(height: 8),
          ..._buildInsights(
            stats: stats,
            schedule: schedule,
            energy: weeklyEnergy,
            avgEnergy: avgEnergy,
            nightCount: nightCount,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildShiftCount(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniInsight(IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildSleepBars(
      WeeklyStats stats, DateTime weekStart) {
    final bars = <BarChartGroupData>[];
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      // The day's total — previously this took the first matching record, so a
      // split-sleep day was drawn as whichever session came back first.
      final hours = stats.hoursOn(date);
      final color = hours >= 7
          ? AppTheme.success
          : hours >= 5
              ? AppTheme.warning
              : hours > 0
                  ? AppTheme.error
                  : AppTheme.textTertiary.withValues(alpha: 0.3);
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: hours > 0 ? hours : 0.3,
              color: color,
              width: 20,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
        ),
      );
    }
    return bars;
  }

  List<Widget> _buildInsights({
    required WeeklyStats stats,
    required ScheduleState schedule,
    required List<EnergyRecord> energy,
    required double avgEnergy,
    required int nightCount,
  }) {
    // Compare the week against the shifts that produced it rather than
    // restating the weekly average back at the user.
    final found = PatternInsights.weekly(
      sleepDays: stats.sleepDays,
      shiftFor: schedule.getShiftForDate,
      energy: energy,
      sleepDebt: stats.sleepDebt,
    );

    final cards = <Widget>[
      for (final insight in found)
        _insightCard(
          switch (insight.tone) {
            InsightTone.good => Icons.check_circle_rounded,
            InsightTone.caution => Icons.info_rounded,
            InsightTone.warn => Icons.warning_amber_rounded,
          },
          switch (insight.tone) {
            InsightTone.good => AppTheme.success,
            InsightTone.caution => AppTheme.info,
            InsightTone.warn => AppTheme.warning,
          },
          insight.title,
          insight.body,
        ),
    ];

    if (nightCount >= 3) {
      cards.add(_insightCard(
        Icons.nightlight_round,
        AppTheme.shiftNight,
        '야간근무 집중 주간',
        '야간 $nightCount일이에요. 근무 전 90분 이내 낮잠과 '
            '근무 시작 전에만 카페인을 쓰는 원칙을 지켜보세요.',
      ));
    }

    if (avgEnergy > 0 && avgEnergy < 2.5) {
      cards.add(_insightCard(
        Icons.battery_alert_rounded,
        AppTheme.error,
        '에너지가 계속 낮아요',
        '이번 주 평균 ${avgEnergy.toStringAsFixed(1)}점이에요. '
            '수면 시간보다 수면 시각이 흔들리는 것이 원인인 경우가 많습니다.',
      ));
    }

    if (cards.isEmpty) {
      cards.add(_insightCard(
        Icons.insights_rounded,
        AppTheme.textTertiary,
        '아직 분석할 데이터가 부족해요',
        '수면과 에너지가 며칠 더 쌓이면 근무 유형별로 비교해드릴게요.',
      ));
    }

    return cards;
  }

  Widget _insightCard(
      IconData icon, Color color, String title, String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDarkElevated.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _messageForGrade(String grade) {
    switch (grade) {
      case 'A+':
        return '완벽한 한 주! 건강 관리의 달인이시네요';
      case 'A':
        return '아주 잘 관리하고 있어요!';
      case 'B+':
        return '괜찮은 한 주, 조금만 더 신경 쓰면 완벽해요';
      case 'B':
        return '보통이에요. 수면을 조금 더 챙겨보세요';
      case 'C':
        return '이번 주는 힘들었나 봐요. 다음 주는 더 잘할 수 있어요';
      default:
        return '데이터를 더 기록하면 정확한 분석을 드릴 수 있어요';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  String _weekdayName(DateTime date) {
    const names = ['월', '화', '수', '목', '금', '토', '일'];
    return names[date.weekday - 1];
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}
