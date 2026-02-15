import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../config/theme.dart';
import '../../models/shift.dart';
import '../../models/shift_pattern.dart';
import '../../providers/schedule_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadMonth();
  }

  void _loadMonth() {
    try {
      ref
          .read(scheduleProvider.notifier)
          .loadShiftsForMonth(_focusedDay.year, _focusedDay.month);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(scheduleProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '근무 캘린더',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _showPatternSelector,
                        icon: const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppTheme.primary,
                        ),
                        tooltip: '패턴 적용',
                      ),
                      IconButton(
                        onPressed: _showAddShiftSheet,
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppTheme.primary,
                        ),
                        tooltip: '근무 추가',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegend('주간', AppTheme.shiftDay),
                  const SizedBox(width: 16),
                  _buildLegend('오후', AppTheme.shiftEvening),
                  const SizedBox(width: 16),
                  _buildLegend('야간', AppTheme.shiftNight),
                  const SizedBox(width: 16),
                  _buildLegend('휴무', AppTheme.shiftOff),
                ],
              ),
            ),

            // Calendar
            TableCalendar(
              firstDay: DateTime(2020, 1, 1),
              lastDay: DateTime(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  _selectedDay != null &&
                  AppHelpers.isSameDay(_selectedDay!, day),
              calendarFormat: _calendarFormat,
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
                _loadMonth();
              },
              locale: 'ko_KR',
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                leftChevronIcon:
                    Icon(Icons.chevron_left, color: AppTheme.textSecondary),
                rightChevronIcon:
                    Icon(Icons.chevron_right, color: AppTheme.textSecondary),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle:
                    TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                weekendStyle:
                    TextStyle(color: AppTheme.accent, fontSize: 12),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle:
                    const TextStyle(color: AppTheme.textPrimary),
                weekendTextStyle: const TextStyle(color: AppTheme.accent),
                todayDecoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                todayTextStyle:
                    const TextStyle(color: AppTheme.textPrimary),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  final shift = schedule.getShiftForDate(date);
                  if (shift == null) return null;
                  return Positioned(
                    bottom: 4,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppHelpers.getShiftColor(shift.type),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // Selected day detail
            Expanded(
              child: _buildSelectedDayDetail(schedule),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDayDetail(ScheduleState schedule) {
    if (_selectedDay == null) {
      return const Center(
        child: Text(
          '날짜를 선택하세요',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    final shift = schedule.getShiftForDate(_selectedDay!);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppHelpers.formatDate(_selectedDay!),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          if (shift != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassCard,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppHelpers.getShiftColor(shift.type)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      AppHelpers.getShiftIcon(shift.type),
                      color: AppHelpers.getShiftColor(shift.type),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppHelpers.getShiftLabel(shift.type)} 근무',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (shift.startTime != null &&
                            shift.endTime != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${shift.startTime} - ${shift.endTime}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        _showEditShiftSheet(shift),
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassCard,
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.event_available_rounded,
                      color: AppTheme.textTertiary,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '등록된 근무가 없습니다',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _showAddShiftSheet,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('근무 추가'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPatternSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '교대 패턴 선택',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '패턴을 선택하면 3개월치 스케줄이 자동 생성됩니다',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              ...ShiftPattern.presets.map((pattern) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    pattern.name,
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                  subtitle: Text(
                    pattern.description ?? '',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textTertiary,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _applyPattern(pattern);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _applyPattern(ShiftPattern pattern) async {
    final startDate = _selectedDay ?? DateTime.now();
    await ref
        .read(scheduleProvider.notifier)
        .applyPattern(pattern, startDate, 3);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${pattern.name} 패턴이 적용되었습니다'),
        ),
      );
    }
  }

  void _showAddShiftSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedDay != null
                    ? '${AppHelpers.formatDate(_selectedDay!)} 근무 추가'
                    : '근무 추가',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildShiftTypeButton(AppConstants.shiftDay, '주간'),
                  const SizedBox(width: 12),
                  _buildShiftTypeButton(AppConstants.shiftEvening, '오후'),
                  const SizedBox(width: 12),
                  _buildShiftTypeButton(AppConstants.shiftNight, '야간'),
                  const SizedBox(width: 12),
                  _buildShiftTypeButton(AppConstants.shiftOff, '휴무'),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShiftTypeButton(String type, String label) {
    final color = AppHelpers.getShiftColor(type);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
          if (_selectedDay != null) {
            ref
                .read(scheduleProvider.notifier)
                .addShift(_selectedDay!, type);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(
                AppHelpers.getShiftIcon(type),
                color: color,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditShiftSheet(Shift shift) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '근무 수정',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildShiftTypeButton(AppConstants.shiftDay, '주간'),
                  const SizedBox(width: 12),
                  _buildShiftTypeButton(AppConstants.shiftEvening, '오후'),
                  const SizedBox(width: 12),
                  _buildShiftTypeButton(AppConstants.shiftNight, '야간'),
                  const SizedBox(width: 12),
                  _buildShiftTypeButton(AppConstants.shiftOff, '휴무'),
                ],
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ref
                      .read(scheduleProvider.notifier)
                      .removeShift(shift.date);
                },
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppTheme.error),
                label: const Text(
                  '근무 삭제',
                  style: TextStyle(color: AppTheme.error),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
