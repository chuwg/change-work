import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../providers/schedule_provider.dart';
import '../../services/notification_plan.dart';
import '../../services/notification_scheduler.dart';
import '../../services/notification_service.dart';

/// "알림이 안 와요"를 사용자가 스스로 진단하는 화면.
///
/// Shows the OS-level permission state, whether exact alarms are allowed, and
/// the exact list the scheduler would queue — built from the same
/// [NotificationPlanner] the scheduler uses, so what is listed here is what
/// actually gets scheduled.
class NotificationStatusScreen extends ConsumerStatefulWidget {
  const NotificationStatusScreen({super.key});

  @override
  ConsumerState<NotificationStatusScreen> createState() =>
      _NotificationStatusScreenState();
}

class _NotificationStatusScreenState
    extends ConsumerState<NotificationStatusScreen> {
  NotificationStatus? _status;
  List<PlannedNotification> _plan = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final status = await NotificationService.instance.checkStatus();
    List<PlannedNotification> plan = const [];
    try {
      plan = await NotificationScheduler.buildPlan(ref.read(scheduleProvider));
    } catch (_) {
      // DB unavailable — keep the permission section useful anyway.
    }
    if (!mounted) return;
    setState(() {
      _status = status;
      _plan = plan;
      _loading = false;
    });
  }

  Future<void> _openSystemSettings() async {
    if (Platform.isIOS) {
      await launchUrl(Uri.parse('app-settings:'));
    } else {
      // Android 13+ shows the runtime prompt; if it was permanently denied
      // this is a no-op and the user has to go through system settings.
      await NotificationService.instance.requestPermissions();
    }
    await _load();
  }

  Future<void> _requestExactAlarms() async {
    await NotificationService.instance.requestExactAlarms();
    await _load();
  }

  Future<void> _sendTest() async {
    await NotificationService.instance.sendTestNotification();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('테스트 알림을 보냈습니다')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        title: const Text(
          '알림 상태',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._buildWarnings(),
                _sectionHeader('권한'),
                const SizedBox(height: 8),
                Container(
                  decoration: AppTheme.glassCard,
                  child: Column(
                    children: [
                      _statusRow(
                        icon: Icons.notifications_active_rounded,
                        label: '알림 허용',
                        ok: _status?.notificationsEnabled,
                      ),
                      if (_status?.exactAlarmsAllowed != null) ...[
                        const Divider(height: 1, indent: 56),
                        _statusRow(
                          icon: Icons.alarm_rounded,
                          label: '정확한 시간에 알림',
                          ok: _status!.exactAlarmsAllowed,
                          hint: _status!.exactAlarmsAllowed == true
                              ? null
                              : '허용하지 않으면 최대 10분까지 늦게 도착할 수 있어요',
                        ),
                      ],
                      const Divider(height: 1, indent: 56),
                      _statusRow(
                        icon: Icons.inventory_2_rounded,
                        label: 'OS에 예약된 알림',
                        value: '${_status?.pendingCount ?? 0}개',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: AppTheme.glassCard,
                  child: _actionRow(
                    icon: Icons.send_rounded,
                    label: '테스트 알림 보내기',
                    sublabel: '지금 즉시 알림이 오는지 확인합니다',
                    onTap: _sendTest,
                  ),
                ),
                const SizedBox(height: 24),
                _sectionHeader('예정된 알림 (${_plan.length}개)'),
                const SizedBox(height: 8),
                if (_plan.isEmpty)
                  Container(
                    decoration: AppTheme.glassCard,
                    padding: const EdgeInsets.all(20),
                    child: const Text(
                      '예정된 알림이 없습니다.\n근무를 등록하고 알림 설정을 켜보세요.',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  )
                else
                  Container(
                    decoration: AppTheme.glassCard,
                    child: Column(
                      children: [
                        for (int i = 0; i < _plan.length; i++) ...[
                          if (i > 0) const Divider(height: 1, indent: 16),
                          _planRow(_plan[i]),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  List<Widget> _buildWarnings() {
    final warnings = <Widget>[];

    if (_status?.notificationsEnabled == false) {
      warnings.add(_warningCard(
        icon: Icons.notifications_off_rounded,
        color: AppTheme.error,
        title: '알림이 차단되어 있습니다',
        body: '근무·취침 알림이 전혀 도착하지 않습니다. 시스템 설정에서 알림을 허용해주세요.',
        actionLabel: '설정 열기',
        onAction: _openSystemSettings,
      ));
    }

    if (_status?.exactAlarmsAllowed == false) {
      warnings.add(_warningCard(
        icon: Icons.alarm_off_rounded,
        color: AppTheme.warning,
        title: '정확한 알람이 꺼져 있습니다',
        body: '알림은 오지만 최대 10분까지 늦을 수 있어요. 출발 알림을 정시에 받으려면 허용해주세요.',
        actionLabel: '허용하기',
        onAction: _requestExactAlarms,
      ));
    }

    if (warnings.isEmpty) return const [];
    return [...warnings, const SizedBox(height: 8)];
  }

  Widget _warningCard({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onAction,
              child: Text(actionLabel, style: TextStyle(color: color)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _statusRow({
    required IconData icon,
    required String label,
    bool? ok,
    String? value,
    String? hint,
  }) {
    final Color tint;
    final String text;
    if (value != null) {
      tint = AppTheme.textSecondary;
      text = value;
    } else if (ok == null) {
      tint = AppTheme.textTertiary;
      text = '확인 불가';
    } else if (ok) {
      tint = AppTheme.success;
      text = '허용됨';
    } else {
      tint = AppTheme.error;
      text = '꺼짐';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 14),
                ),
                if (hint != null)
                  Text(
                    hint,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
              ],
            ),
          ),
          Text(
            text,
            style: TextStyle(
                color: tint, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String label,
    required String sublabel,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 14)),
                  Text(sublabel,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _planRow(PlannedNotification planned) {
    final color = _kindColor(planned.kind);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              planned.kind.label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatWhen(planned.time),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  planned.body,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _kindColor(NotificationKind kind) {
    switch (kind) {
      case NotificationKind.shiftStart:
        return AppTheme.primary;
      case NotificationKind.bedtime:
        return AppTheme.shiftNight;
      case NotificationKind.caffeineCutoff:
        return AppTheme.warning;
      case NotificationKind.preShiftNap:
        return AppTheme.info;
    }
  }

  String _formatWhen(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    final diff = day.difference(today).inDays;
    final clock = DateFormat('HH:mm').format(time);
    if (diff == 0) return '오늘 $clock';
    if (diff == 1) return '내일 $clock';
    return '${DateFormat('M월 d일 (E)', 'ko_KR').format(time)} $clock';
  }
}
