import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/health_tip.dart';
import '../utils/constants.dart';

class HealthTipCard extends StatelessWidget {
  final HealthTip tip;
  final bool expanded;

  const HealthTipCard({
    super.key,
    required this.tip,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(tip.category);
    final icon = _getCategoryIcon(tip.category);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDarkElevated.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      tip.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (tip.timing != null)
                      Text(
                        tip.timing!,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getCategoryLabel(tip.category),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: 12),
            Text(
              tip.description,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case AppConstants.tipSleep:
        return const Color(0xFF7E57C2);
      case AppConstants.tipMeal:
        return const Color(0xFFFFB74D);
      case AppConstants.tipExercise:
        return const Color(0xFF66BB6A);
      case AppConstants.tipCaffeine:
        return const Color(0xFF8D6E63);
      case AppConstants.tipLight:
        return const Color(0xFF4FC3F7);
      case AppConstants.tipEnergy:
        return AppTheme.primary;
      default:
        return AppTheme.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case AppConstants.tipSleep:
        return Icons.bedtime_rounded;
      case AppConstants.tipMeal:
        return Icons.restaurant_rounded;
      case AppConstants.tipExercise:
        return Icons.fitness_center_rounded;
      case AppConstants.tipCaffeine:
        return Icons.coffee_rounded;
      case AppConstants.tipLight:
        return Icons.light_mode_rounded;
      case AppConstants.tipEnergy:
        return Icons.bolt_rounded;
      default:
        return Icons.tips_and_updates_rounded;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case AppConstants.tipSleep:
        return '수면';
      case AppConstants.tipMeal:
        return '식사';
      case AppConstants.tipExercise:
        return '운동';
      case AppConstants.tipCaffeine:
        return '카페인';
      case AppConstants.tipLight:
        return '빛';
      case AppConstants.tipEnergy:
        return '에너지';
      default:
        return '팁';
    }
  }
}
