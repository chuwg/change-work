import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../config/theme.dart';
import '../../models/shift.dart';
import '../../models/shift_pattern.dart';
import '../../providers/schedule_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../../services/export_service.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMonth());
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
                  Text(
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
                        onPressed: () => _exportMonth(schedule),
                        icon: Icon(
                          Icons.share_rounded,
                          color: AppTheme.primary,
                          size: 22,
                        ),
                        tooltip: '스케줄 공유',
                      ),
                      IconButton(
                        onPressed: _showPatternSelector,
                        icon: Icon(
                          Icons.auto_awesome_rounded,
                          color: AppTheme.primary,
                        ),
                        tooltip: '패턴 적용',
                      ),
                      IconButton(
                        onPressed: _showAddShiftSheet,
                        icon: Icon(
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
              // Without this the grid stretches to fill the height and the day
              // blocks render as tall capsules.
              rowHeight: 54,
              daysOfWeekHeight: 22,
              headerStyle: HeaderStyle(
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
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle:
                    TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                weekendStyle: TextStyle(color: AppTheme.accent, fontSize: 12),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: TextStyle(color: AppTheme.textPrimary),
                weekendTextStyle: TextStyle(color: AppTheme.accent),
                // Day cells are drawn by calendarBuilders below, so the
                // built-in circles would only sit behind them.
                cellMargin: const EdgeInsets.all(3),
              ),
              calendarBuilders: CalendarBuilders(
                // The shift used to be a 6dp dot under the date, which is far
                // too small to tell four colours apart at a glance. Each day is
                // now a filled block in its shift colour.
                defaultBuilder: (context, date, _) =>
                    _buildDayCell(schedule, date),
                outsideBuilder: (context, date, _) =>
                    _buildDayCell(schedule, date, outside: true),
                todayBuilder: (context, date, _) =>
                    _buildDayCell(schedule, date, isToday: true),
                selectedBuilder: (context, date, _) =>
                    _buildDayCell(schedule, date, isSelected: true),
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

  /// A single calendar day, filled with its shift colour.
  ///
  /// Today and the selected day are marked with a ring rather than a different
  /// fill, so the shift colour stays readable in every state.
  Widget _buildDayCell(
    ScheduleState schedule,
    DateTime date, {
    bool isToday = false,
    bool isSelected = false,
    bool outside = false,
  }) {
    final shift = schedule.getShiftForDate(date);
    final color = shift != null ? AppHelpers.getShiftColor(shift.type) : null;
    final opacity = outside ? 0.25 : 0.85;

    return Container(
      margin: const EdgeInsets.all(2),
      // Fill the column: with loose constraints the container would shrink to
      // the width of the day number and render as a narrow capsule.
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: color?.withValues(alpha: opacity) ??
            AppTheme.textTertiary.withValues(alpha: outside ? 0.05 : 0.10),
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: AppTheme.textPrimary, width: 2)
            : isToday
                ? Border.all(color: AppTheme.primary, width: 2)
                : null,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    // Dark text on the saturated fills; the palette is light enough
                    // that white would wash out.
                    color: color != null && !outside
                        ? const Color(0xFF241F1B)
                        : AppTheme.textSecondary
                            .withValues(alpha: outside ? 0.5 : 1),
                    fontSize: 14,
                    fontWeight: isToday || isSelected
                        ? FontWeight.bold
                        : FontWeight.w600,
                    height: 1.1,
                  ),
                ),
                if (shift != null && !outside)
                  Text(
                    AppHelpers.getShiftShortLabel(shift.type),
                    style: const TextStyle(
                      color: Color(0xFF241F1B),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
              ],
            ),
          ),
          // Swapped days get a corner mark so a month of trades is visible
          // at a glance; a plain note gets a smaller dot.
          if (shift != null && !outside && (shift.isSwapped || shift.hasNote))
            Positioned(
              top: 2,
              right: 3,
              child: shift.isSwapped
                  ? const Icon(Icons.swap_horiz_rounded,
                      size: 11, color: Color(0xFF241F1B))
                  : Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF241F1B),
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDayDetail(ScheduleState schedule) {
    if (_selectedDay == null) {
      return Center(
        child: Text(
          '날짜를 선택하세요',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    final shift = schedule.getShiftForDate(_selectedDay!);

    // Scrollable: with the memo card the detail can outgrow the space left
    // under a six-week month on a small phone.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppHelpers.formatDate(_selectedDay!),
            style: TextStyle(
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
                          AppHelpers.getShiftDisplayName(shift.type),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
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
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showEditShiftSheet(shift),
                    icon: Icon(
                      Icons.edit_rounded,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildMemoCard(shift),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassCard,
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      color: AppTheme.textTertiary,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
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

  /// Swap partner and note for the selected day, tappable to edit.
  Widget _buildMemoCard(Shift shift) {
    final empty = !shift.isSwapped && !shift.hasNote;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showMemoSheet(shift),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: AppTheme.glassCard,
        child: empty
            ? Row(
                children: [
                  Icon(Icons.swap_horiz_rounded,
                      color: AppTheme.textTertiary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '근무 교환·메모 추가',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (shift.isSwapped)
                    Row(
                      children: [
                        Icon(Icons.swap_horiz_rounded,
                            color: AppTheme.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${shift.swapWith}과(와) 교환',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (shift.isSwapped && shift.hasNote)
                    const SizedBox(height: 6),
                  if (shift.hasNote)
                    Text(
                      shift.note!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                ],
              ),
      ),
    );
  }

  Future<void> _showMemoSheet(Shift shift) async {
    final swapController = TextEditingController(text: shift.swapWith ?? '');
    final noteController = TextEditingController(text: shift.note ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        InputDecoration field(String label, String hint, IconData icon) =>
            InputDecoration(
              labelText: label,
              hintText: hint,
              prefixIcon: Icon(icon, size: 20),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            );
        return Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, 20 + MediaQuery.viewInsetsOf(ctx).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppHelpers.formatDate(shift.date)} 교환·메모',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: swapController,
                textInputAction: TextInputAction.next,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration:
                    field('교환한 사람', '예: 김간호사', Icons.swap_horiz_rounded),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                minLines: 1,
                maxLines: 3,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration:
                    field('메모', '예: 다음 주 화요일에 갚기로 함', Icons.notes_rounded),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (shift.isSwapped || shift.hasNote)
                    TextButton(
                      onPressed: () {
                        swapController.clear();
                        noteController.clear();
                        Navigator.pop(ctx, true);
                      },
                      child:
                          Text('지우기', style: TextStyle(color: AppTheme.error)),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('저장'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (saved == true) {
      await ref.read(scheduleProvider.notifier).updateMemo(
            shift.date,
            swapWith: swapController.text,
            note: noteController.text,
          );
    }
    swapController.dispose();
    noteController.dispose();
  }

  /// Anchor for the iPad share popover. iPhone ignores it, but on iPad the
  /// share sheet refuses to open without one.
  Rect _shareOrigin() {
    final size = MediaQuery.sizeOf(context);
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 1,
      height: 1,
    );
  }

  Future<void> _exportMonth(ScheduleState schedule) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('이미지 생성 중...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      await ExportService.instance.exportAndShareMonth(
        year: _focusedDay.year,
        month: _focusedDay.month,
        shifts: schedule.shifts,
        origin: _shareOrigin(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('내보내기 실패: $e')),
        );
      }
    }
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
              Text(
                '교대 패턴 선택',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
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
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                  subtitle: Text(
                    pattern.description ?? '',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  trailing: Icon(
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
            ref.read(scheduleProvider.notifier).addShift(_selectedDay!, type);
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
              Text(
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
                  ref.read(scheduleProvider.notifier).removeShift(shift.date);
                },
                icon: Icon(Icons.delete_outline_rounded, color: AppTheme.error),
                label: Text(
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
