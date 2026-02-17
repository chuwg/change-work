import 'package:flutter/material.dart';
import '../models/shift.dart';
import '../config/theme.dart';
import '../utils/helpers.dart';

class ExportCalendarWidget extends StatelessWidget {
  final int year;
  final int month;
  final Map<DateTime, Shift> shifts;

  const ExportCalendarWidget({
    super.key,
    required this.year,
    required this.month,
    required this.shifts,
  });

  static const _weekdays = ['일', '월', '화', '수', '목', '금', '토'];
  static const _shiftShortLabels = {
    'day': '주',
    'evening': '오',
    'night': '야',
    'off': '휴',
  };

  @override
  Widget build(BuildContext context) {
    final weeks = _buildWeeks();

    return Container(
      width: 1080,
      height: 1350,
      color: AppTheme.bgDark,
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 36),

          // Weekday row
          _buildWeekdayRow(),
          const SizedBox(height: 12),

          // Calendar grid
          Expanded(child: _buildGrid(weeks)),

          const SizedBox(height: 24),

          // Legend
          _buildLegend(),

          const SizedBox(height: 16),

          // Branding
          _buildBranding(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$year년 ${month}월',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 48,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(width: 16),
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            '근무 스케줄',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 28,
              fontWeight: FontWeight.w400,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayRow() {
    return Row(
      children: _weekdays.map((day) {
        final isWeekend = day == '일' || day == '토';
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                color: isWeekend ? AppTheme.accent : AppTheme.textSecondary,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGrid(List<List<int?>> weeks) {
    return Column(
      children: weeks.map((week) {
        return Expanded(
          child: Row(
            children: week.map((day) {
              if (day == null) {
                return const Expanded(child: SizedBox());
              }
              return Expanded(child: _buildDayCell(day));
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayCell(int day) {
    final date = DateTime(year, month, day);
    final shift = _getShift(date);
    final shiftColor = shift != null
        ? AppHelpers.getShiftColor(shift.type)
        : Colors.transparent;
    final shortLabel = shift != null
        ? (_shiftShortLabels[shift.type] ?? '')
        : '';

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: shift != null
            ? shiftColor.withValues(alpha: 0.12)
            : AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          ),
          if (shift != null) ...[
            const SizedBox(height: 4),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: shiftColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  shortLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegend() {
    final items = [
      ('주간', AppTheme.shiftDay),
      ('오후', AppTheme.shiftEvening),
      ('야간', AppTheme.shiftNight),
      ('휴무', AppTheme.shiftOff),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: item.$2,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.$1,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 20,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBranding() {
    return Center(
      child: Text(
        'Change — 스마트 교대근무 관리',
        style: TextStyle(
          color: AppTheme.textTertiary.withValues(alpha: 0.6),
          fontSize: 18,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Shift? _getShift(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return shifts[key];
  }

  List<List<int?>> _buildWeeks() {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun

    final weeks = <List<int?>>[];
    var currentDay = 1;

    for (int w = 0; w < 6; w++) {
      final week = <int?>[];
      for (int d = 0; d < 7; d++) {
        if (w == 0 && d < startWeekday) {
          week.add(null);
        } else if (currentDay > daysInMonth) {
          week.add(null);
        } else {
          week.add(currentDay);
          currentDay++;
        }
      }
      weeks.add(week);
      if (currentDay > daysInMonth) break;
    }

    return weeks;
  }
}
