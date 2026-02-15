import 'package:flutter/material.dart';
import '../config/theme.dart';

class SleepSummaryCard extends StatelessWidget {
  final double averageHours;
  final double averageQuality;

  const SleepSummaryCard({
    super.key,
    required this.averageHours,
    required this.averageQuality,
  });

  @override
  Widget build(BuildContext context) {
    final isGoodSleep = averageHours >= 7;

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
                Icons.bedtime_rounded,
                color: isGoodSleep ? AppTheme.success : AppTheme.warning,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                '평균 수면',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                averageHours > 0 ? averageHours.toStringAsFixed(1) : '--',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(width: 2),
              const Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Text(
                  '시간',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Quality stars
          Row(
            children: List.generate(5, (i) {
              final filled = i < averageQuality.round();
              return Icon(
                filled ? Icons.star_rounded : Icons.star_outline_rounded,
                color: filled
                    ? const Color(0xFFE8B94A)
                    : AppTheme.textTertiary,
                size: 14,
              );
            }),
          ),
        ],
      ),
    );
  }
}
