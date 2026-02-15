import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/shift_pattern.dart';
import '../../providers/schedule_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback? onComplete;

  const OnboardingScreen({super.key, this.onComplete});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _selectedPatternId;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i <= _currentPage
                            ? AppTheme.primary
                            : AppTheme.surfaceDarkElevated,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) =>
                    setState(() => _currentPage = page),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomePage(),
                  _buildPatternPage(),
                  _buildReadyPage(),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text('이전'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: _currentPage == 0 ? 1 : 1,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_currentPage < 2) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          // Apply selected pattern (default to 2-shift if none selected)
                          final patternId = _selectedPatternId ?? 'preset_2shift';
                          final pattern = ShiftPattern.presets.firstWhere(
                            (p) => p.id == patternId,
                          );
                          await ref
                              .read(scheduleProvider.notifier)
                              .applyPattern(pattern, DateTime.now(), 3);

                          if (widget.onComplete != null) {
                            widget.onComplete!();
                          } else {
                            if (mounted) {
                              Navigator.pushReplacementNamed(context, '/');
                            }
                          }
                        }
                      },
                      child: Text(
                          _currentPage == 2 ? '시작하기' : '다음'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: Colors.white,
              size: 60,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Change에 오신 걸 환영해요',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '교대근무자를 위한 스마트 스케줄 관리와\n건강 코치가 당신의 건강을 지켜드립니다',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFeatureIcon(Icons.calendar_month_rounded, '스케줄 관리'),
              const SizedBox(width: 24),
              _buildFeatureIcon(Icons.bedtime_rounded, '수면 트래킹'),
              const SizedBox(width: 24),
              _buildFeatureIcon(Icons.favorite_rounded, '건강 코치'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.surfaceDarkElevated,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPatternPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '근무 패턴을 선택하세요',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '나중에 설정에서 변경할 수 있어요',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: ShiftPattern.presets.length,
              itemBuilder: (context, index) {
                final pattern = ShiftPattern.presets[index];
                final isSelected = _selectedPatternId == pattern.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedPatternId = pattern.id),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withValues(alpha: 0.1)
                            : AppTheme.surfaceDarkElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  pattern.name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : AppTheme.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.primary,
                                  size: 20,
                                ),
                            ],
                          ),
                          if (pattern.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              pattern.description!,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          // Pattern preview
                          Wrap(
                            spacing: 4,
                            children: pattern.pattern.map((type) {
                              final color = _getPatternColor(type);
                              return Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    _getPatternLabel(type),
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppTheme.success,
              size: 48,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '준비 완료!',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Change가 당신의 교대근무 생활을\n더 건강하게 만들어 드리겠습니다',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassCard,
            child: const Column(
              children: [
                _FeatureRow(
                  icon: Icons.auto_awesome_rounded,
                  title: '스케줄 자동 생성',
                  description: '선택한 패턴으로 3개월치 스케줄이 자동 생성됩니다',
                ),
                SizedBox(height: 16),
                _FeatureRow(
                  icon: Icons.bedtime_rounded,
                  title: '수면 품질 추적',
                  description: '매일 수면을 기록하고 패턴을 분석합니다',
                ),
                SizedBox(height: 16),
                _FeatureRow(
                  icon: Icons.psychology_rounded,
                  title: '건강 코치',
                  description: '근무 패턴에 맞는 맞춤 건강 가이드를 제공합니다',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPatternColor(String type) {
    switch (type) {
      case 'day':
        return AppTheme.shiftDay;
      case 'evening':
        return AppTheme.shiftEvening;
      case 'night':
        return AppTheme.shiftNight;
      case 'off':
        return AppTheme.shiftOff;
      default:
        return AppTheme.textTertiary;
    }
  }

  String _getPatternLabel(String type) {
    switch (type) {
      case 'day':
        return '주';
      case 'evening':
        return '오';
      case 'night':
        return '야';
      case 'off':
        return '휴';
      default:
        return '?';
    }
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
