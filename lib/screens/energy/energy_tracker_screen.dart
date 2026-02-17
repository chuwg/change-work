import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/energy_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/energy_chart.dart';

class EnergyTrackerScreen extends ConsumerStatefulWidget {
  const EnergyTrackerScreen({super.key});

  @override
  ConsumerState<EnergyTrackerScreen> createState() =>
      _EnergyTrackerScreenState();
}

class _EnergyTrackerScreenState extends ConsumerState<EnergyTrackerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        ref.read(energyProvider.notifier).loadRecords();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final energy = ref.watch(energyProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '에너지 트래커',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/energy-stats'),
                      icon: const Icon(Icons.bar_chart_rounded, size: 18),
                      label: const Text('통계'),
                    ),
                  ],
                ),
              ),
            ),

            // Today's Energy Summary
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.energyCardGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '오늘의 에너지',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Icon(
                            Icons.bolt_rounded,
                            color: AppTheme.primaryLight,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (energy.todayRecords.isNotEmpty) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppHelpers.getEnergyLabel(
                                  energy.latestToday!.energyLevel),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '(${energy.todayRecords.length}회 기록)',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildEnergyStat(
                              '최근',
                              AppHelpers.formatTime(
                                  energy.latestToday!.timestamp),
                            ),
                            const SizedBox(width: 24),
                            _buildEnergyStat(
                              '오늘 평균',
                              energy.todayAverageEnergy.toStringAsFixed(1),
                            ),
                            if (energy.latestToday?.activity != null) ...[
                              const SizedBox(width: 24),
                              _buildEnergyStat(
                                '활동',
                                AppHelpers.getActivityLabel(
                                    energy.latestToday!.activity!),
                              ),
                            ],
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
                          onPressed: () => _showAddEnergyRecord(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('에너지 기록하기'),
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

            // Daily Timeline Chart
            if (energy.todayRecords.isNotEmpty)
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
                          '오늘의 에너지 변화',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: EnergyDailyLineChart(
                              records: energy.todayRecords),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Weekly Chart
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
                        '주간 평균 에너지',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: EnergyWeeklyBarChart(
                          dailyAverages: _getWeeklyAverages(energy),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Shift-based analysis
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
                        '근무별 평균 에너지',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (energy.avgByShiftType.isNotEmpty)
                        ...energy.avgByShiftType.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildShiftEnergyBar(
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
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
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
                  if (index >= energy.records.length) return null;
                  final record = energy.records[index];
                  return Dismissible(
                    key: Key(record.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: AppTheme.error.withValues(alpha: 0.3),
                      child: const Icon(Icons.delete_rounded,
                          color: AppTheme.error),
                    ),
                    onDismissed: (_) {
                      ref
                          .read(energyProvider.notifier)
                          .deleteEnergyRecord(record.id);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.glassCard,
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppHelpers.getEnergyColor(
                                        record.energyLevel)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Icon(
                                  AppHelpers.getEnergyIcon(record.energyLevel),
                                  color: AppHelpers.getEnergyColor(
                                      record.energyLevel),
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${AppHelpers.formatDate(record.date)} ${AppHelpers.formatTime(record.timestamp)}',
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      if (record.activity != null)
                                        Text(
                                          AppHelpers.getActivityLabel(
                                              record.activity!),
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      if (record.activity != null &&
                                          record.mood != null)
                                        const Text(
                                          ' · ',
                                          style: TextStyle(
                                            color: AppTheme.textTertiary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      if (record.mood != null)
                                        Text(
                                          AppHelpers.getMoodLabel(record.mood!),
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              AppHelpers.getEnergyLabel(record.energyLevel),
                              style: TextStyle(
                                color: AppHelpers.getEnergyColor(
                                    record.energyLevel),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: energy.records.length.clamp(0, 15),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEnergyRecord(context),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  List<MapEntry<DateTime, double>> _getWeeklyAverages(EnergyState energy) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return energy.dailyAverages
        .where((e) => e.key.isAfter(weekAgo))
        .toList();
  }

  Widget _buildEnergyStat(String label, String value) {
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

  Widget _buildShiftEnergyBar(String label, double avg, Color color) {
    final percentage = (avg / 5).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            Text(
              '${avg.toStringAsFixed(1)} / 5',
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

  void _showAddEnergyRecord(BuildContext context) {
    int energyLevel = 3;
    String? selectedActivity;
    String? selectedMood;
    final noteController = TextEditingController();

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
                    '에너지 기록',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Energy level selector
                  const Text(
                    '에너지 레벨',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (i) {
                      final level = i + 1;
                      final isSelected = energyLevel == level;
                      return GestureDetector(
                        onTap: () =>
                            setSheetState(() => energyLevel = level),
                        child: Column(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppHelpers.getEnergyColor(level)
                                    : AppHelpers.getEnergyColor(level)
                                        .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Icon(
                                  AppHelpers.getEnergyIcon(level),
                                  color: isSelected
                                      ? Colors.white
                                      : AppHelpers.getEnergyColor(level),
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppHelpers.getEnergyLabel(level),
                              style: TextStyle(
                                color: isSelected
                                    ? AppHelpers.getEnergyColor(level)
                                    : AppTheme.textTertiary,
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  // Activity selector
                  const Text(
                    '활동',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.energyActivities.map((activity) {
                      final isSelected = selectedActivity == activity;
                      return GestureDetector(
                        onTap: () => setSheetState(() {
                          selectedActivity =
                              isSelected ? null : activity;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary.withValues(alpha: 0.2)
                                : AppTheme.surfaceDarkElevated,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                AppHelpers.getActivityIcon(activity),
                                size: 14,
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppHelpers.getActivityLabel(activity),
                                style: TextStyle(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Mood selector
                  const Text(
                    '기분',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.energyMoods.map((mood) {
                      final isSelected = selectedMood == mood;
                      return GestureDetector(
                        onTap: () => setSheetState(() {
                          selectedMood = isSelected ? null : mood;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary.withValues(alpha: 0.2)
                                : AppTheme.surfaceDarkElevated,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                AppHelpers.getMoodIcon(mood),
                                size: 14,
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppHelpers.getMoodLabel(mood),
                                style: TextStyle(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Note field
                  TextField(
                    controller: noteController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: '메모 (선택사항)',
                      prefixIcon: Icon(Icons.note_rounded,
                          color: AppTheme.textTertiary),
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final schedule = ref.read(scheduleProvider);
                        final todayShift = schedule.todayShift;
                        ref.read(energyProvider.notifier).addEnergyRecord(
                              energyLevel: energyLevel,
                              shiftType: todayShift?.type,
                              activity: selectedActivity,
                              mood: selectedMood,
                              note: noteController.text.isEmpty
                                  ? null
                                  : noteController.text,
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
