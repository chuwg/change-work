import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/salary_settings.dart';
import '../../providers/salary_provider.dart';
import '../../utils/constants.dart';

class SalarySettingsScreen extends ConsumerStatefulWidget {
  const SalarySettingsScreen({super.key});

  @override
  ConsumerState<SalarySettingsScreen> createState() =>
      _SalarySettingsScreenState();
}

class _SalarySettingsScreenState extends ConsumerState<SalarySettingsScreen> {
  late String _payType;
  late TextEditingController _hourlyController;
  late TextEditingController _monthlyController;
  late TextEditingController _nightMultController;
  late TextEditingController _weekendMultController;
  late TextEditingController _overtimeMultController;
  late List<FixedAllowance> _fixedAllowances;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(salaryProvider).settings;
    _payType = settings.payType;
    _hourlyController =
        TextEditingController(text: settings.hourlyRate.toStringAsFixed(0));
    _monthlyController =
        TextEditingController(text: settings.monthlySalary.toStringAsFixed(0));
    _nightMultController =
        TextEditingController(text: settings.nightMultiplier.toString());
    _weekendMultController =
        TextEditingController(text: settings.weekendMultiplier.toString());
    _overtimeMultController =
        TextEditingController(text: settings.overtimeMultiplier.toString());
    _fixedAllowances = List.from(settings.fixedAllowances);
  }

  @override
  void dispose() {
    _hourlyController.dispose();
    _monthlyController.dispose();
    _nightMultController.dispose();
    _weekendMultController.dispose();
    _overtimeMultController.dispose();
    super.dispose();
  }

  void _save() {
    final settings = SalarySettings(
      payType: _payType,
      hourlyRate: double.tryParse(_hourlyController.text) ?? 9860.0,
      monthlySalary: double.tryParse(_monthlyController.text) ?? 2500000.0,
      nightMultiplier: double.tryParse(_nightMultController.text) ??
          AppConstants.defaultNightMultiplier,
      weekendMultiplier: double.tryParse(_weekendMultController.text) ??
          AppConstants.defaultWeekendMultiplier,
      overtimeMultiplier: double.tryParse(_overtimeMultController.text) ??
          AppConstants.defaultOvertimeMultiplier,
      fixedAllowances: _fixedAllowances,
    );
    ref.read(salaryProvider.notifier).saveSettings(settings);
    Navigator.pop(context);
  }

  void _showAddAllowanceSheet() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    bool perShift = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDarkElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '고정 수당 추가',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: '수당 이름 (예: 식대)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: '금액 (원)',
                  suffixText: '원',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '근무일 당 지급',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  Switch(
                    value: perShift,
                    onChanged: (v) => setSheetState(() => perShift = v),
                  ),
                ],
              ),
              Text(
                perShift ? '근무일 수 × 금액으로 계산됩니다' : '월 고정 금액으로 계산됩니다',
                style: const TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final amount =
                        double.tryParse(amountController.text) ?? 0;
                    if (name.isEmpty || amount <= 0) return;
                    setState(() {
                      _fixedAllowances.add(FixedAllowance(
                        name: name,
                        amount: amount,
                        perShift: perShift,
                      ));
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('추가'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('급여 설정'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              '저장',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Pay type section
          _buildSectionLabel('급여 유형'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildPayTypeChip(
                  AppConstants.payTypeHourly,
                  '시급제',
                  Icons.access_time_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPayTypeChip(
                  AppConstants.payTypeMonthly,
                  '월급제',
                  Icons.calendar_month_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Base pay section
          _buildSectionLabel(
              _payType == AppConstants.payTypeHourly ? '시급' : '월급'),
          const SizedBox(height: 8),
          TextField(
            controller: _payType == AppConstants.payTypeHourly
                ? _hourlyController
                : _monthlyController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              suffixText: '원',
              suffixStyle: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
              hintText: _payType == AppConstants.payTypeHourly
                  ? '9,860'
                  : '2,500,000',
            ),
          ),

          const SizedBox(height: 24),

          // Multiplier section
          _buildSectionLabel('수당 배율'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.glassCard,
            child: Column(
              children: [
                _buildMultiplierRow(
                  '야간 수당',
                  Icons.nightlight_round,
                  AppTheme.shiftNight,
                  _nightMultController,
                ),
                const SizedBox(height: 16),
                _buildMultiplierRow(
                  '주말 수당',
                  Icons.weekend_rounded,
                  AppTheme.shiftOff,
                  _weekendMultController,
                ),
                const SizedBox(height: 16),
                _buildMultiplierRow(
                  '연장 수당',
                  Icons.more_time_rounded,
                  AppTheme.info,
                  _overtimeMultController,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '기본급 대비 배율 (예: 1.5 = 기본급의 150%)',
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
          ),

          const SizedBox(height: 24),

          // Fixed allowances section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionLabel('고정 수당'),
              TextButton.icon(
                onPressed: _showAddAllowanceSheet,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('추가'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_fixedAllowances.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.glassCard,
              child: const Center(
                child: Text(
                  '식대, 교통비 등 고정 수당을 추가해보세요',
                  style: TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ...List.generate(_fixedAllowances.length, (i) {
              final a = _fixedAllowances[i];
              return Dismissible(
                key: ValueKey('$i-${a.name}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_rounded,
                      color: AppTheme.error),
                ),
                onDismissed: (_) {
                  setState(() => _fixedAllowances.removeAt(i));
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: AppTheme.glassCard,
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color:
                              AppTheme.salaryGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.payments_rounded,
                          color: AppTheme.salaryGreen,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.name,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              a.perShift ? '근무일 당' : '월 고정',
                              style: const TextStyle(
                                color: AppTheme.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${a.amount.toStringAsFixed(0)}원',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildPayTypeChip(String type, String label, IconData icon) {
    final selected = _payType == type;
    return GestureDetector(
      onTap: () => setState(() => _payType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : AppTheme.surfaceDarkElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppTheme.primary.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? AppTheme.primary : AppTheme.textTertiary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color:
                    selected ? AppTheme.primary : AppTheme.textSecondary,
                fontSize: 15,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiplierRow(
    String label,
    IconData icon,
    Color color,
    TextEditingController controller,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
            ),
          ),
        ),
        SizedBox(
          width: 80,
          child: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              suffixText: 'x',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}
