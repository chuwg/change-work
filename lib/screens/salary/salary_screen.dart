import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../models/salary_calculation.dart';
import '../../providers/salary_provider.dart';
import '../../utils/helpers.dart';

class SalaryScreen extends ConsumerStatefulWidget {
  const SalaryScreen({super.key});

  @override
  ConsumerState<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends ConsumerState<SalaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(salaryProvider.notifier);
      await notifier.loadSettings();
      final state = ref.read(salaryProvider);
      await notifier.calculateForMonth(
          state.selectedYear, state.selectedMonth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final salary = ref.watch(salaryProvider);
    final calc = salary.calculation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('급여 계산기'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, size: 22),
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.salarySettings);
              if (mounted) {
                final s = ref.read(salaryProvider);
                ref
                    .read(salaryProvider.notifier)
                    .calculateForMonth(s.selectedYear, s.selectedMonth);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month navigator
            _buildMonthNavigator(salary),
            const SizedBox(height: 16),

            if (!salary.isConfigured) ...[
              _buildEmptyState(),
            ] else if (salary.isLoading) ...[
              const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
            ] else if (calc != null) ...[
              _buildSummaryCards(calc),
              const SizedBox(height: 16),
              _buildWorkSummary(calc),
              const SizedBox(height: 16),
              _buildPayBreakdown(calc),
              const SizedBox(height: 16),
              _buildShiftTypeBreakdown(calc),
              if (calc.settings.fixedAllowances.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildFixedAllowances(calc),
              ],
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthNavigator(SalaryState salary) {
    final now = DateTime.now();
    final isCurrentMonth = salary.selectedYear == now.year &&
        salary.selectedMonth == now.month;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () =>
              ref.read(salaryProvider.notifier).goToPreviousMonth(),
        ),
        Text(
          '${salary.selectedYear}년 ${salary.selectedMonth}월',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.chevron_right_rounded,
            color: isCurrentMonth
                ? AppTheme.textTertiary
                : AppTheme.textPrimary,
          ),
          onPressed:
              isCurrentMonth
                  ? null
                  : () =>
                      ref.read(salaryProvider.notifier).goToNextMonth(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: AppTheme.glassCard,
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppTheme.textTertiary,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              '급여 설정을 먼저 해주세요',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '시급 또는 월급을 설정하면\n근무 일정에 맞는 예상 급여를 계산합니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.salarySettings),
              child: const Text('설정하기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(SalaryCalculation calc) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '총 급여',
            AppHelpers.formatKRW(calc.totalGross),
            Icons.account_balance_wallet_rounded,
            AppTheme.salaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '기본급',
            AppHelpers.formatKRW(calc.basePay),
            Icons.payments_rounded,
            AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '수당 합계',
            AppHelpers.formatKRW(calc.totalAllowances),
            Icons.add_circle_outline_rounded,
            AppTheme.info,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.glassCard,
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkSummary(SalaryCalculation calc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '근무 현황',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                    '근무일수', '${calc.workingDays}일'),
              ),
              Expanded(
                child: _buildInfoItem(
                    '총 근무시간', '${calc.totalWorkHours.toStringAsFixed(1)}h'),
              ),
              Expanded(
                child:
                    _buildInfoItem('야간 근무', '${calc.nightShifts}회'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child:
                    _buildInfoItem('주말 근무', '${calc.weekendDays}일'),
              ),
              Expanded(
                child: _buildInfoItem(
                    '야간 시간', '${calc.totalNightHours.toStringAsFixed(1)}h'),
              ),
              Expanded(
                child: _buildInfoItem(
                    '연장 시간', '${calc.overtimeHours.toStringAsFixed(1)}h'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPayBreakdown(SalaryCalculation calc) {
    final items = <_PayItem>[
      _PayItem('기본급', calc.basePay, AppTheme.primary),
      if (calc.nightPremium > 0)
        _PayItem('야간 수당', calc.nightPremium, AppTheme.shiftNight),
      if (calc.weekendPremium > 0)
        _PayItem('주말 수당', calc.weekendPremium, AppTheme.shiftOff),
      if (calc.overtimePay > 0)
        _PayItem('연장 수당', calc.overtimePay, AppTheme.info),
      if (calc.fixedAllowancesTotal > 0)
        _PayItem('고정 수당', calc.fixedAllowancesTotal, AppTheme.salaryGreen),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '급여 구성',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: items.map((item) {
                  final fraction =
                      calc.totalGross > 0 ? item.amount / calc.totalGross : 0.0;
                  return Expanded(
                    flex: (fraction * 1000).round().clamp(1, 1000),
                    child: Container(color: item.color),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Line items
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      AppHelpers.formatKRWFull(item.amount),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )),

          const Divider(height: 20),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '합계',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                AppHelpers.formatKRWFull(calc.totalGross),
                style: const TextStyle(
                  color: AppTheme.salaryGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShiftTypeBreakdown(SalaryCalculation calc) {
    if (calc.shiftBreakdowns.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '근무 유형별 내역',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...calc.shiftBreakdowns.map((b) {
            final color = AppHelpers.getShiftColor(b.shiftType);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      AppHelpers.getShiftIcon(b.shiftType),
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppHelpers.getShiftLabel(b.shiftType)} ${b.count}회',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${b.totalHours.toStringAsFixed(1)}시간 (야간 ${b.nightHours.toStringAsFixed(1)}h)',
                          style: const TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    AppHelpers.formatKRWFull(b.total),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFixedAllowances(SalaryCalculation calc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '고정 수당 내역',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...calc.settings.fixedAllowances.map((a) {
            final total =
                a.perShift ? a.amount * calc.workingDays : a.amount;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      a.name,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (a.perShift)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        '${a.amount.toStringAsFixed(0)}원 x ${calc.workingDays}일',
                        style: const TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  Text(
                    AppHelpers.formatKRWFull(total),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PayItem {
  final String label;
  final double amount;
  final Color color;
  const _PayItem(this.label, this.amount, this.color);
}
