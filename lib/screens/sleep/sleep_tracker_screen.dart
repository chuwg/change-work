import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/sleep_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/sleep_chart.dart';

class SleepTrackerScreen extends ConsumerStatefulWidget {
  const SleepTrackerScreen({super.key});

  @override
  ConsumerState<SleepTrackerScreen> createState() =>
      _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends ConsumerState<SleepTrackerScreen> {
  @override
  void initState() {
    super.initState();
    try { ref.read(sleepProvider.notifier).loadRecords(); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final sleep = ref.watch(sleepProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '수면 트래커',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.pushNamed(
                          context, '/sleep-stats'),
                      icon: const Icon(Icons.bar_chart_rounded, size: 18),
                      label: const Text('통계'),
                    ),
                  ],
                ),
              ),
            ),

            // Today's Sleep Summary
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.sleepCardGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '오늘의 수면',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Icon(
                            Icons.nightlight_round,
                            color: AppTheme.primaryLight,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (sleep.todayRecord != null) ...[
                        Text(
                          AppHelpers.formatDuration(
                              sleep.todayRecord!.duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildSleepStat(
                              '취침',
                              AppHelpers.formatTime(
                                  sleep.todayRecord!.bedTime),
                            ),
                            const SizedBox(width: 24),
                            _buildSleepStat(
                              '기상',
                              AppHelpers.formatTime(
                                  sleep.todayRecord!.wakeTime),
                            ),
                            const SizedBox(width: 24),
                            _buildSleepStat(
                              '품질',
                              AppHelpers.getSleepQualityLabel(
                                  sleep.todayRecord!.quality),
                            ),
                          ],
                        ),
                      ] else ...[
                        const Text(
                          '아직 기록이 없어요',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showAddSleepRecord(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('수면 기록하기'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white24,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Weekly Chart
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.glassCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '주간 수면 시간',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: SleepBarChart(records: sleep.last7Days),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Shift-based sleep analysis
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.glassCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '근무별 평균 수면',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (sleep.avgByShiftType.isNotEmpty)
                        ...sleep.avgByShiftType.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildShiftSleepBar(
                              AppHelpers.getShiftLabel(entry.key),
                              entry.value,
                              AppHelpers.getShiftColor(entry.key),
                            ),
                          );
                        })
                      else
                        const Center(
                          child: Text(
                            '데이터를 모으는 중입니다...',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Recent records
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: const Text(
                  '최근 기록',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= sleep.records.length) return null;
                  final record = sleep.records[index];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.glassCard,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  AppHelpers.getSleepQualityColor(record.quality)
                                      .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${record.quality}',
                                style: TextStyle(
                                  color: AppHelpers.getSleepQualityColor(
                                      record.quality),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppHelpers.formatDate(record.date),
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${AppHelpers.formatTime(record.bedTime)} - ${AppHelpers.formatTime(record.wakeTime)}',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (record.source == 'healthkit' ||
                                  record.source == 'health_connect')
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Icon(
                                    Icons.watch_rounded,
                                    size: 14,
                                    color: AppTheme.primary.withValues(alpha: 0.7),
                                  ),
                                ),
                              Text(
                                AppHelpers.formatDuration(record.duration),
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: sleep.records.length.clamp(0, 10),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSleepRecord(context),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSleepStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildShiftSleepBar(String label, double hours, Color color) {
    final percentage = (hours / 10).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13),
            ),
            Text(
              '${hours.toStringAsFixed(1)}시간',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  void _showAddSleepRecord(BuildContext context) {
    DateTime bedTime = DateTime.now().subtract(const Duration(hours: 7));
    DateTime wakeTime = DateTime.now();
    int quality = 3;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '수면 기록',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bed time picker
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.bedtime_rounded,
                        color: AppTheme.primary),
                    title: const Text('취침 시간',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    trailing: TextButton(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(bedTime),
                        );
                        if (time != null) {
                          setSheetState(() {
                            bedTime = DateTime(
                              bedTime.year,
                              bedTime.month,
                              bedTime.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      },
                      child: Text(
                        AppHelpers.formatTime(bedTime),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Wake time picker
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.wb_sunny_rounded,
                        color: AppTheme.shiftDay),
                    title: const Text('기상 시간',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    trailing: TextButton(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(wakeTime),
                        );
                        if (time != null) {
                          setSheetState(() {
                            wakeTime = DateTime(
                              wakeTime.year,
                              wakeTime.month,
                              wakeTime.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      },
                      child: Text(
                        AppHelpers.formatTime(wakeTime),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Quality selector
                  const SizedBox(height: 8),
                  const Text(
                    '수면 품질',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (i) {
                      final q = i + 1;
                      final isSelected = quality == q;
                      return GestureDetector(
                        onTap: () => setSheetState(() => quality = q),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppHelpers.getSleepQualityColor(q)
                                : AppHelpers.getSleepQualityColor(q)
                                    .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              AppHelpers.getSleepQualityLabel(q),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppHelpers.getSleepQualityColor(q),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final schedule = ref.read(scheduleProvider);
                        final todayShift = schedule.todayShift;
                        ref.read(sleepProvider.notifier).addSleepRecord(
                              date: DateTime.now(),
                              bedTime: bedTime,
                              wakeTime: wakeTime,
                              quality: quality,
                              shiftType: todayShift?.type,
                            );
                        Navigator.pop(context);
                      },
                      child: const Text('저장'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
