import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/shift.dart';
import '../utils/helpers.dart';

class TodayShiftCard extends StatelessWidget {
  final Shift? shift;
  final int daysUntilOff;

  const TodayShiftCard({
    super.key,
    this.shift,
    this.daysUntilOff = -1,
  });

  @override
  Widget build(BuildContext context) {
    final shiftType = shift?.type ?? '';
    final color = AppHelpers.getShiftColor(shiftType);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '오늘의 근무',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              if (daysUntilOff > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.shiftOff.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '휴무까지 $daysUntilOff일',
                    style: const TextStyle(
                      color: AppTheme.shiftOff,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  AppHelpers.getShiftIcon(shiftType),
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shift != null
                          ? '${AppHelpers.getShiftLabel(shiftType)} 근무'
                          : '등록된 근무 없음',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (shift?.startTime != null && shift?.endTime != null)
                      Text(
                        '${shift!.startTime} - ${shift!.endTime}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ShiftDayChip extends StatelessWidget {
  final DateTime date;
  final Shift? shift;
  final bool isToday;

  const ShiftDayChip({
    super.key,
    required this.date,
    this.shift,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    final shiftType = shift?.type ?? '';
    final color =
        shift != null ? AppHelpers.getShiftColor(shiftType) : AppTheme.textTertiary;

    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];

    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isToday
            ? AppTheme.primary.withValues(alpha: 0.15)
            : AppTheme.surfaceDarkElevated.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: isToday
            ? Border.all(color: AppTheme.primary.withValues(alpha: 0.4))
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            weekday,
            style: TextStyle(
              color: isToday ? AppTheme.primary : AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${date.day}',
            style: TextStyle(
              color: isToday ? AppTheme.primary : AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 32,
            height: 20,
            decoration: BoxDecoration(
              color: shift != null
                  ? color.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                shift != null ? AppHelpers.getShiftLabel(shiftType) : '-',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
