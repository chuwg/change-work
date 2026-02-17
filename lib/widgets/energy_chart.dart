import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/theme.dart';
import '../models/energy_record.dart';
import '../utils/helpers.dart';

class EnergyDailyLineChart extends StatelessWidget {
  final List<EnergyRecord> records;

  const EnergyDailyLineChart({
    super.key,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(
        child: Text(
          '오늘 에너지 기록이 없습니다\n에너지를 기록해보세요!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 6,
        minX: 0,
        maxX: 23,
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final labels = ['', '탈진', '피곤', '보통', '좋음', '최고', ''];
                final index = value.toInt();
                if (index < 1 || index > 5) return const SizedBox();
                return Text(
                  labels[index],
                  style: const TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 6,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                if (hour % 6 != 0) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '$hour시',
                    style: const TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.textTertiary.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: records.map((r) {
              return FlSpot(
                r.timestamp.hour + r.timestamp.minute / 60.0,
                r.energyLevel.toDouble(),
              );
            }).toList(),
            isCurved: true,
            color: AppTheme.primary,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                final level = spot.y.toInt();
                return FlDotCirclePainter(
                  radius: 5,
                  color: AppHelpers.getEnergyColor(level),
                  strokeWidth: 2,
                  strokeColor: AppTheme.surfaceDark,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.15),
                  AppTheme.primary.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 3,
              color: AppTheme.warning.withValues(alpha: 0.3),
              strokeWidth: 1,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: const TextStyle(
                  color: AppTheme.warning,
                  fontSize: 9,
                ),
                labelResolver: (_) => '보통',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EnergyWeeklyBarChart extends StatelessWidget {
  final List<MapEntry<DateTime, double>> dailyAverages;

  const EnergyWeeklyBarChart({
    super.key,
    required this.dailyAverages,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyAverages.isEmpty) {
      return const Center(
        child: Text(
          '에너지 기록이 없습니다',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 5,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex >= dailyAverages.length) return null;
              final avg = dailyAverages[groupIndex].value;
              return BarTooltipItem(
                '${avg.toStringAsFixed(1)}\n${AppHelpers.getEnergyLabel(avg.round())}',
                const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value < 1 || value > 5 || value != value.roundToDouble()) {
                  return const SizedBox();
                }
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= dailyAverages.length) return const SizedBox();
                final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
                final weekday =
                    weekdays[dailyAverages[index].key.weekday - 1];
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    weekday,
                    style: const TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.textTertiary.withValues(alpha: 0.1),
              strokeWidth: 1,
              dashArray: [4, 4],
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: _buildBarGroups(),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 3,
              color: AppTheme.warning.withValues(alpha: 0.3),
              strokeWidth: 1,
              dashArray: [6, 4],
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return dailyAverages.asMap().entries.map((entry) {
      final index = entry.key;
      final avg = entry.value.value;
      final level = avg.round().clamp(1, 5);
      final barColor = AppHelpers.getEnergyColor(level);

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: avg.clamp(0, 5),
            width: dailyAverages.length > 14 ? 8 : 16,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
            gradient: LinearGradient(
              colors: [
                barColor.withValues(alpha: 0.4),
                barColor,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ],
      );
    }).toList();
  }
}
