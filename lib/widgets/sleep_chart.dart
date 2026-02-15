import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/theme.dart';
import '../models/sleep_record.dart';
import '../utils/helpers.dart';

class SleepBarChart extends StatelessWidget {
  final List<SleepRecord> records;

  const SleepBarChart({
    super.key,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(
        child: Text(
          '수면 기록이 없습니다\n수면을 기록해보세요!',
          textAlign: TextAlign.center,
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
        maxY: 12,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex >= records.length) return null;
              final record = records[groupIndex];
              return BarTooltipItem(
                '${record.durationHours.toStringAsFixed(1)}시간\n'
                '${AppHelpers.getSleepQualityLabel(record.quality)}',
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
              reservedSize: 30,
              interval: 3,
              getTitlesWidget: (value, meta) {
                if (value % 3 != 0) return const SizedBox();
                return Text(
                  '${value.toInt()}h',
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
                if (index >= records.length) return const SizedBox();
                final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
                final weekday = weekdays[records[index].date.weekday - 1];
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
          horizontalInterval: 3,
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
              y: 7,
              color: AppTheme.success.withValues(alpha: 0.3),
              strokeWidth: 1,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: const TextStyle(
                  color: AppTheme.success,
                  fontSize: 9,
                ),
                labelResolver: (_) => '권장 7h',
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return records.asMap().entries.map((entry) {
      final index = entry.key;
      final record = entry.value;
      final hours = record.durationHours.clamp(0, 12).toDouble();
      final quality = record.quality;

      Color barColor;
      if (quality >= 4) {
        barColor = AppTheme.success;
      } else if (quality == 3) {
        barColor = AppTheme.warning;
      } else {
        barColor = AppTheme.error;
      }

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: hours,
            width: records.length > 14 ? 8 : 16,
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

class SleepQualityLineChart extends StatelessWidget {
  final List<SleepRecord> records;

  const SleepQualityLineChart({
    super.key,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(
        child: Text(
          '데이터가 없습니다',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 5,
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
                final labels = ['', '최악', '나쁨', '보통', '좋음', '최고'];
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
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
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
            spots: records.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                entry.value.quality.toDouble(),
              );
            }).toList(),
            isCurved: true,
            color: AppTheme.primary,
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                final quality = spot.y.toInt();
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppHelpers.getSleepQualityColor(quality),
                  strokeWidth: 0,
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
      ),
    );
  }
}
