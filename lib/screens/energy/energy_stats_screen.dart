import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/energy_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/energy_chart.dart';

class EnergyStatsScreen extends ConsumerWidget {
  const EnergyStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final energy = ref.watch(energyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('에너지 통계'),
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
                    '평균 에너지',
                    energy.averageEnergy > 0
                        ? energy.averageEnergy.toStringAsFixed(1)
                        : '--',
                    Icons.bolt_rounded,
                    AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '기록 수',
                    '${energy.records.length}',
                    Icons.edit_note_rounded,
                    AppTheme.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '오늘 기록',
                    '${energy.todayRecords.length}',
                    Icons.today_rounded,
                    AppTheme.warning,
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
                    '30일 에너지 추이',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 220,
                    child: EnergyWeeklyBarChart(
                      dailyAverages: _getLast30DaysAverages(energy),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Energy level distribution
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '에너지 레벨 분포',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(5, (i) {
                    final level = 5 - i;
                    final count = energy.records
                        .where((r) => r.energyLevel == level)
                        .length;
                    final percentage = energy.records.isEmpty
                        ? 0.0
                        : count / energy.records.length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            child: Text(
                              AppHelpers.getEnergyLabel(level),
                              style: TextStyle(
                                color: AppHelpers.getEnergyColor(level),
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
                                    AppHelpers.getEnergyColor(level)
                                        .withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation(
                                    AppHelpers.getEnergyColor(level)),
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
                    '근무 유형별 에너지 분석',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '각 근무 유형별 평균 에너지 레벨을 보여줍니다',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (energy.avgByShiftType.isNotEmpty)
                    ...energy.avgByShiftType.entries.map((entry) {
                      final color = AppHelpers.getShiftColor(entry.key);
                      final isGood = entry.value >= 3;
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppHelpers.getShiftLabel(entry.key),
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '평균 ${entry.value.toStringAsFixed(1)} / 5',
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
                          '에너지 기록이 쌓이면 분석 결과를 보여드립니다',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Time of day analysis
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '시간대별 에너지 분석',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (energy.records.isNotEmpty)
                    ..._buildTimeOfDayAnalysis(energy)
                  else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          '데이터를 모으는 중입니다...',
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

  List<MapEntry<DateTime, double>> _getLast30DaysAverages(EnergyState energy) {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    return energy.dailyAverages
        .where((e) => e.key.isAfter(monthAgo))
        .toList();
  }

  List<Widget> _buildTimeOfDayAnalysis(EnergyState energy) {
    final timeGroups = <String, List<int>>{
      'dawn': [],
      'morning': [],
      'afternoon': [],
      'evening': [],
    };

    for (final record in energy.records) {
      timeGroups[record.timeOfDay]?.add(record.energyLevel);
    }

    final labels = {
      'dawn': '새벽 (0-6시)',
      'morning': '오전 (6-12시)',
      'afternoon': '오후 (12-18시)',
      'evening': '저녁 (18-24시)',
    };

    final icons = {
      'dawn': Icons.dark_mode_rounded,
      'morning': Icons.wb_sunny_rounded,
      'afternoon': Icons.wb_cloudy_rounded,
      'evening': Icons.nightlight_round,
    };

    return timeGroups.entries.where((e) => e.value.isNotEmpty).map((entry) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      final percentage = (avg / 5).clamp(0.0, 1.0);
      final color = AppHelpers.getEnergyColor(avg.round().clamp(1, 5));

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icons[entry.key], color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  labels[entry.key] ?? entry.key,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  '${avg.toStringAsFixed(1)} / 5 (${entry.value.length}회)',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
          ],
        ),
      );
    }).toList();
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
