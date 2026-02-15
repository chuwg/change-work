import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/sleep_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/sleep_chart.dart';

class SleepStatsScreen extends ConsumerWidget {
  const SleepStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleep = ref.watch(sleepProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('수면 통계'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '평균 수면',
                    '${sleep.averageSleepHours.toStringAsFixed(1)}h',
                    Icons.bedtime_rounded,
                    AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '평균 품질',
                    sleep.averageQuality.toStringAsFixed(1),
                    Icons.star_rounded,
                    AppTheme.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '기록 수',
                    '${sleep.records.length}',
                    Icons.edit_note_rounded,
                    AppTheme.success,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 30-day chart
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '30일 수면 추이',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 220,
                    child: SleepBarChart(records: sleep.last30Days),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quality distribution
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '수면 품질 분포',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(5, (i) {
                    final q = 5 - i;
                    final count = sleep.records
                        .where((r) => r.quality == q)
                        .length;
                    final percentage = sleep.records.isEmpty
                        ? 0.0
                        : count / sleep.records.length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            child: Text(
                              AppHelpers.getSleepQualityLabel(q),
                              style: TextStyle(
                                color:
                                    AppHelpers.getSleepQualityColor(q),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage,
                                backgroundColor:
                                    AppHelpers.getSleepQualityColor(q)
                                        .withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation(
                                    AppHelpers.getSleepQualityColor(q)),
                                minHeight: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 30,
                            child: Text(
                              '$count',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Shift-based analysis
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '근무 유형별 수면 분석',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '각 근무 유형별 평균 수면 시간과 품질을 보여줍니다',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (sleep.avgByShiftType.isNotEmpty)
                    ...sleep.avgByShiftType.entries.map((entry) {
                      final color = AppHelpers.getShiftColor(entry.key);
                      final isGood = entry.value >= 7;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                AppHelpers.getShiftIcon(entry.key),
                                color: color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppHelpers.getShiftLabel(entry.key),
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '평균 ${entry.value.toStringAsFixed(1)}시간',
                                    style: TextStyle(
                                      color: isGood
                                          ? AppTheme.success
                                          : AppTheme.warning,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isGood
                                  ? Icons.check_circle_rounded
                                  : Icons.warning_rounded,
                              color: isGood
                                  ? AppTheme.success
                                  : AppTheme.warning,
                              size: 20,
                            ),
                          ],
                        ),
                      );
                    })
                  else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          '수면 기록이 쌓이면 분석 결과를 보여드립니다',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
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

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard,
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
