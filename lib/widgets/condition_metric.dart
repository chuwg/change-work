import 'package:flutter/material.dart';
import '../config/theme.dart';

/// One figure in the condition score card's metric row (수면 / 에너지 / 걸음 / 심박).
///
/// Sizes itself down rather than overflowing: four of these sit beside the
/// score ring, which leaves roughly 60dp each on a narrow phone — not enough
/// for a value like "12.3천" at the nominal font size.
class ConditionMetric extends StatelessWidget {
  final IconData icon;
  final String label;

  /// Already formatted for display, or "--" when there is no reading.
  final String value;
  final Color color;

  const ConditionMetric({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
