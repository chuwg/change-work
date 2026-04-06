import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';
import '../../providers/sleep_provider.dart';
import '../../providers/energy_provider.dart';
import '../../providers/schedule_provider.dart';
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

    final weeklySleep = sleep.last7Days;
    final weeklyEnergy = energy.last7Days;

    // Calculate weekly stats
    final avgSleepHours = weeklySleep.isEmpty
        ? 0.0
        : weeklySleep.fold<double>(0, (s, r) => s + r.durationHours) /
            weeklySleep.length;
    final avgSleepQuality = weeklySleep.isEmpty
        ? 0.0
        : weeklySleep.fold<int>(0, (s, r) => s + r.quality) /
            weeklySleep.length;
    final avgEnergy = weeklyEnergy.isEmpty
        ? 0.0
        : weeklyEnergy.fold<int>(0, (s, r) => s + r.energyLevel) /
            weeklyEnergy.length;

    // Shift type counts this week
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
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

    // Sleep debt (7h * days - actual)
    final sleepDebt = weeklySleep.isEmpty
        ? 0.0
        : (7.0 * weeklySleep.length) -
            weeklySleep.fold<double>(0, (s, r) => s + r.durationHours);

    // Best/worst sleep day
    final bestSleep = weeklySleep.isNotEmpty
        ? (weeklySleep.toList()
              ..sort(
                  (a, b) => b.durationHours.compareTo(a.durationHours)))
            .first
        : null;
    final worstSleep = weeklySleep.isNotEmpty
        ? (weeklySleep.toList()
              ..sort(
                  (a, b) => a.durationHours.compareTo(b.durationHours)))
            .first
        : null;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '주간 리포트',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
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
                  _getOverallGrade(avgSleepHours, avgEnergy, sleepDebt),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getOverallMessage(avgSleepHours, avgEnergy, sleepDebt),
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
                _buildShiftCount('주간', dayCount, AppHelpers.getShiftColor('day')),
                _buildShiftCount('오후', eveningCount, AppHelpers.getShiftColor('evening')),
                _buildShiftCount('야간', nightCount, AppHelpers.getShiftColor('night')),
                _buildShiftCount('휴무', offCount, AppHelpers.getShiftColor('off')),
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
                        sleepDebt <= 3
                            ? AppTheme.success
                            : AppTheme.error,
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
                        barGroups: _buildSleepBars(weeklySleep, weekStart),
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
                                const days = ['월', '화', '수', '목', '금', '토', '일'];
                                final idx = value.toInt();
                                if (idx < 0 || idx >= 7) return const Text('');
                                return Text(
                                  days[idx],
                                  style: const TextStyle(
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
                          '최고: ${_weekdayName(bestSleep.date)} ${bestSleep.durationHours.toStringAsFixed(1)}h',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMiniInsight(
                          Icons.arrow_downward_rounded,
                          AppTheme.error,
                          '최저: ${_weekdayName(worstSleep.date)} ${worstSleep.durationHours.toStringAsFixed(1)}h',
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
                        avgEnergy >= 3
                            ? AppTheme.success
                            : AppTheme.warning,
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
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${e.value.toStringAsFixed(1)}/5',
                            style: const TextStyle(
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
            avgSleepHours: avgSleepHours,
            sleepDebt: sleepDebt,
            avgEnergy: avgEnergy,
            nightCount: nightCount,
            weeklySleep: weeklySleep,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
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
          style: const TextStyle(
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
          style: const TextStyle(
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
      List sleepRecords, DateTime weekStart) {
    final bars = <BarChartGroupData>[];
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final record = sleepRecords.cast<dynamic>().where((r) {
        final d = r.date as DateTime;
        return d.year == date.year &&
            d.month == date.month &&
            d.day == date.day;
      }).toList();
      final hours =
          record.isNotEmpty ? (record.first.durationHours as double) : 0.0;
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
        ),
      );
    }
    return bars;
  }

  List<Widget> _buildInsights({
    required double avgSleepHours,
    required double sleepDebt,
    required double avgEnergy,
    required int nightCount,
    required List weeklySleep,
  }) {
    final insights = <Widget>[];

    if (sleepDebt > 5) {
      insights.add(_insightCard(
        Icons.warning_rounded,
        AppTheme.error,
        '수면 부채 경고',
        '이번 주 수면 부채가 ${sleepDebt.toStringAsFixed(1)}시간이에요. 휴무일에 충분한 수면으로 회복하세요.',
      ));
    } else if (sleepDebt > 2) {
      insights.add(_insightCard(
        Icons.info_rounded,
        AppTheme.warning,
        '수면 부채 주의',
        '약간의 수면 부채(${sleepDebt.toStringAsFixed(1)}h)가 있어요. 오늘 30분 일찍 잠들어 보세요.',
      ));
    }

    if (nightCount >= 3) {
      insights.add(_insightCard(
        Icons.nightlight_round,
        const Color(0xFF8B7EC8),
        '야간근무 집중 주간',
        '야간 $nightCount일, 낮잠과 카페인 타이밍에 주의하세요. 휴무 전날은 점진적으로 수면 시간을 조정하세요.',
      ));
    }

    if (avgEnergy > 0 && avgEnergy < 2.5) {
      insights.add(_insightCard(
        Icons.battery_1_bar_rounded,
        AppTheme.error,
        '에너지 저하 경고',
        '이번 주 평균 에너지가 낮아요. 수면 패턴과 식사 시간을 점검해보세요.',
      ));
    }

    if (avgSleepHours >= 7 && avgEnergy >= 3.5) {
      insights.add(_insightCard(
        Icons.thumb_up_rounded,
        AppTheme.success,
        '좋은 한 주였어요!',
        '수면과 에너지 모두 양호합니다. 이 패턴을 유지하세요!',
      ));
    }

    if (insights.isEmpty) {
      insights.add(_insightCard(
        Icons.lightbulb_rounded,
        AppTheme.primary,
        '데이터를 더 쌓아보세요',
        '수면과 에너지를 꾸준히 기록하면 더 정확한 분석을 받을 수 있어요.',
      ));
    }

    return insights;
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
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(
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

  String _getOverallGrade(
      double avgSleep, double avgEnergy, double sleepDebt) {
    double score = 0;
    if (avgSleep >= 7) score += 40;
    else if (avgSleep >= 6) score += 25;
    else if (avgSleep > 0) score += 10;

    if (avgEnergy >= 3.5) score += 35;
    else if (avgEnergy >= 2.5) score += 20;
    else if (avgEnergy > 0) score += 10;

    if (sleepDebt <= 2) score += 25;
    else if (sleepDebt <= 5) score += 15;
    else score += 5;

    if (score >= 85) return 'A+';
    if (score >= 75) return 'A';
    if (score >= 60) return 'B+';
    if (score >= 45) return 'B';
    if (score >= 30) return 'C';
    return 'D';
  }

  String _getOverallMessage(
      double avgSleep, double avgEnergy, double sleepDebt) {
    final grade = _getOverallGrade(avgSleep, avgEnergy, sleepDebt);
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
