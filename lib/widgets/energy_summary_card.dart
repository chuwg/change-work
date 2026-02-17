import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../utils/helpers.dart';

class EnergySummaryCard extends StatelessWidget {
  final double averageEnergy;
  final int? latestLevel;
  final DateTime? latestTime;
  final VoidCallback? onQuickLog;

  const EnergySummaryCard({
    super.key,
    required this.averageEnergy,
    this.latestLevel,
    this.latestTime,
    this.onQuickLog,
  });

  @override
  Widget build(BuildContext context) {
    final displayLevel = latestLevel ?? averageEnergy.round();
    final hasData = latestLevel != null || averageEnergy > 0;
    final color = hasData
        ? AppHelpers.getEnergyColor(displayLevel.clamp(1, 5))
        : AppTheme.textTertiary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDarkElevated.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bolt_rounded,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  '에너지',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              if (onQuickLog != null)
                GestureDetector(
                  onTap: onQuickLog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '기록',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hasData
                    ? AppHelpers.getEnergyLabel(displayLevel.clamp(1, 5))
                    : '--',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              if (latestTime != null) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    AppHelpers.formatTime(latestTime!),
                    style: const TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Energy level dots
          Row(
            children: List.generate(5, (i) {
              final level = i + 1;
              final filled = hasData && level <= displayLevel.clamp(1, 5);
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: filled
                        ? AppHelpers.getEnergyColor(level)
                        : AppTheme.textTertiary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
