import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/health_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/health_tip_card.dart';
import '../../widgets/circadian_mini_clock.dart';

class HealthCoachScreen extends ConsumerStatefulWidget {
  const HealthCoachScreen({super.key});

  @override
  ConsumerState<HealthCoachScreen> createState() => _HealthCoachScreenState();
}

class _HealthCoachScreenState extends ConsumerState<HealthCoachScreen> {
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try { ref.read(healthProvider.notifier).refreshHealthData(); } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final health = ref.watch(healthProvider);
    final schedule = ref.watch(scheduleProvider);
    final todayShift = schedule.todayShift;

    final filteredTips = _selectedCategory == 'all'
        ? health.currentTips
        : health.currentTips
            .where((t) => t.category == _selectedCategory)
            .toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '건강 코치',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      todayShift != null
                          ? '오늘 ${AppHelpers.getShiftLabel(todayShift.type)} 근무 기준 맞춤 가이드'
                          : '근무 스케줄을 등록하면 맞춤 가이드를 제공합니다',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Circadian rhythm card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, '/circadian'),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.healthCardGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '서카디안 리듬',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getPhaseLabel(health.currentPhase),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '건강 점수 ${health.circadianScore.toInt()}점',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CircadianMiniClock(
                          phase: health.currentPhase,
                          score: health.circadianScore,
                          size: 80,
                          showLabel: false,
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white54,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Category filter
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildCategoryChip('all', '전체'),
                    _buildCategoryChip(AppConstants.tipSleep, '수면'),
                    _buildCategoryChip(AppConstants.tipMeal, '식사'),
                    _buildCategoryChip(AppConstants.tipExercise, '운동'),
                    _buildCategoryChip(AppConstants.tipCaffeine, '카페인'),
                    _buildCategoryChip(AppConstants.tipLight, '빛 관리'),
                    _buildCategoryChip(AppConstants.tipEnergy, '에너지'),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Tips list
            if (filteredTips.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          color: AppTheme.textTertiary,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '근무 스케줄을 등록하면\n맞춤 건강 가이드를 제공합니다',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      child: HealthTipCard(
                        tip: filteredTips[index],
                        expanded: true,
                      ),
                    );
                  },
                  childCount: filteredTips.length,
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          setState(() => _selectedCategory = category);
        },
        selectedColor: AppTheme.primary.withValues(alpha: 0.3),
        checkmarkColor: AppTheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
          fontSize: 13,
        ),
      ),
    );
  }

  String _getPhaseLabel(CircadianPhase phase) {
    switch (phase) {
      case CircadianPhase.alert:
        return '각성 상태';
      case CircadianPhase.active:
        return '최고 활동 시간';
      case CircadianPhase.drowsy:
        return '졸림 구간';
      case CircadianPhase.sleep:
        return '수면 권장';
      case CircadianPhase.deepSleep:
        return '깊은 수면';
      case CircadianPhase.waking:
        return '기상 시간';
    }
  }
}
