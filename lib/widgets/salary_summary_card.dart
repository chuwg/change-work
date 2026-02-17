import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../providers/salary_provider.dart';
import '../utils/helpers.dart';

class SalarySummaryCard extends ConsumerWidget {
  const SalarySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salary = ref.watch(salaryProvider);
    final calc = salary.calculation;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.salary),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppTheme.salaryCardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppTheme.salaryGreen,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  '이번 달 예상 급여',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white38,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              calc != null
                  ? AppHelpers.formatKRW(calc.totalGross)
                  : salary.isConfigured
                      ? '--'
                      : '설정 필요',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (calc != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  _miniStat('기본급', AppHelpers.formatKRW(calc.basePay)),
                  const SizedBox(width: 16),
                  _miniStat('수당', AppHelpers.formatKRW(calc.totalAllowances)),
                  const SizedBox(width: 16),
                  _miniStat('${calc.workingDays}일 근무', ''),
                ],
              ),
            ],
            if (!salary.isConfigured) ...[
              const SizedBox(height: 6),
              const Text(
                '급여를 설정하면 예상 급여를 보여드려요',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
