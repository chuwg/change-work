import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../config/theme.dart';
import '../../providers/health_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../services/ai_health_service.dart';

class CircadianScreen extends ConsumerWidget {
  const CircadianScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(healthProvider);
    final schedule = ref.watch(scheduleProvider);
    final shiftType = schedule.todayShift?.type ?? 'day';
    final healthService = AiHealthService();

    // Use actual shift schedule from health state, fallback to default
    final shiftSchedule =
        health.currentSchedule ?? ShiftSchedule.defaultForType(shiftType);

    final recommendedTimes = healthService.getRecommendedSleepTimes(
      shiftType: shiftType,
      schedule: shiftSchedule,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('서카디안 리듬'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circadian Clock
            Center(
              child: SizedBox(
                width: 280,
                height: 280,
                child: CustomPaint(
                  painter: CircadianClockPainter(
                    currentPhase: health.currentPhase,
                    shiftSchedule: shiftSchedule,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPhaseIcon(health.currentPhase),
                          color: _getPhaseColor(health.currentPhase),
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getPhaseLabel(health.currentPhase),
                          style: TextStyle(
                            color: _getPhaseColor(health.currentPhase),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${health.circadianScore.toInt()}점',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Score card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '서카디안 건강 점수',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: health.circadianScore / 100,
                      backgroundColor: AppTheme.surfaceDarkElevated,
                      valueColor: AlwaysStoppedAnimation(
                        _getScoreColor(health.circadianScore),
                      ),
                      minHeight: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getScoreMessage(health.circadianScore),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Recommended times
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '권장 시간표',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${shiftSchedule.startTimeStr}~${shiftSchedule.endTimeStr}',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '실제 근무 시간 기반 맞춤 가이드',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTimeRow(
                    Icons.bedtime_rounded,
                    '취침',
                    recommendedTimes['bedTime'] ?? '--:--',
                    AppTheme.shiftNight,
                  ),
                  const SizedBox(height: 12),
                  _buildTimeRow(
                    Icons.wb_sunny_rounded,
                    '기상',
                    recommendedTimes['wakeTime'] ?? '--:--',
                    AppTheme.shiftDay,
                  ),
                  if (recommendedTimes.containsKey('napTime')) ...[
                    const SizedBox(height: 12),
                    _buildTimeRow(
                      Icons.airline_seat_flat_rounded,
                      '낮잠',
                      recommendedTimes['napTime']!,
                      AppTheme.primary,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildTimeRow(
                    Icons.coffee_rounded,
                    '카페인 컷오프',
                    shiftSchedule.caffeineCutoffStr,
                    AppTheme.warning,
                  ),
                  const SizedBox(height: 12),
                  _buildTimeRow(
                    Icons.restaurant_rounded,
                    '마지막 식사',
                    shiftSchedule.lastMealStr,
                    AppTheme.shiftEvening,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Phase timeline - dynamically generated
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '24시간 리듬 가이드',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._buildDynamicPhaseTimeline(healthService, shiftType,
                      shiftSchedule),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow(
      IconData icon, String label, String time, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 14),
        ),
        const Spacer(),
        Text(
          time,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Build phase timeline dynamically from the service's generatePhaseTimeline.
  List<Widget> _buildDynamicPhaseTimeline(
      AiHealthService service, String shiftType, ShiftSchedule schedule) {
    final hourPhases = service.generatePhaseTimeline(
      shiftType: shiftType,
      schedule: schedule,
    );

    // Merge consecutive hours with the same phase into ranges
    final merged = <_PhaseInfo>[];
    int rangeStart = 0;
    CircadianPhase currentPhase =
        hourPhases[0]['phase'] as CircadianPhase;

    for (int i = 1; i <= 24; i++) {
      final phase =
          i < 24 ? hourPhases[i]['phase'] as CircadianPhase : currentPhase;
      if (i == 24 || phase != currentPhase) {
        merged.add(_PhaseInfo(
          '${rangeStart.toString().padLeft(2, '0')}:00-${i == 24 ? '00' : i.toString().padLeft(2, '0')}:00',
          _getPhaseLabel(currentPhase),
          currentPhase,
        ));
        rangeStart = i;
        currentPhase = phase;
      }
    }

    return merged.map((p) {
      final color = _getPhaseColor(p.phase);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 100,
              child: Text(
                p.timeRange,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              _getPhaseIcon(p.phase),
              color: color,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                p.label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  IconData _getPhaseIcon(CircadianPhase phase) {
    switch (phase) {
      case CircadianPhase.alert:
        return Icons.bolt_rounded;
      case CircadianPhase.active:
        return Icons.trending_up_rounded;
      case CircadianPhase.drowsy:
        return Icons.nights_stay_rounded;
      case CircadianPhase.sleep:
        return Icons.bedtime_rounded;
      case CircadianPhase.deepSleep:
        return Icons.bedtime_rounded;
      case CircadianPhase.waking:
        return Icons.wb_sunny_rounded;
    }
  }

  String _getPhaseLabel(CircadianPhase phase) {
    switch (phase) {
      case CircadianPhase.alert:
        return '각성 상태';
      case CircadianPhase.active:
        return '최고 활동';
      case CircadianPhase.drowsy:
        return '졸림';
      case CircadianPhase.sleep:
        return '수면';
      case CircadianPhase.deepSleep:
        return '깊은 수면';
      case CircadianPhase.waking:
        return '기상';
    }
  }

  Color _getPhaseColor(CircadianPhase phase) {
    switch (phase) {
      case CircadianPhase.alert:
        return AppTheme.circadianAlert;
      case CircadianPhase.active:
        return AppTheme.success;
      case CircadianPhase.drowsy:
        return AppTheme.circadianDrowsy;
      case CircadianPhase.sleep:
      case CircadianPhase.deepSleep:
        return AppTheme.circadianSleep;
      case CircadianPhase.waking:
        return AppTheme.circadianWaking;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppTheme.success;
    if (score >= 60) return AppTheme.warning;
    return AppTheme.error;
  }

  String _getScoreMessage(double score) {
    if (score >= 80) return '서카디안 리듬이 잘 유지되고 있어요!';
    if (score >= 60) return '조금 더 규칙적인 수면 패턴을 유지해보세요.';
    if (score >= 40) return '수면 패턴이 불규칙합니다. 건강 가이드를 확인하세요.';
    return '서카디안 리듬 회복이 필요합니다. 건강 코치를 참고하세요.';
  }
}

class _PhaseInfo {
  final String timeRange;
  final String label;
  final CircadianPhase phase;

  _PhaseInfo(this.timeRange, this.label, this.phase);
}

class CircadianClockPainter extends CustomPainter {
  final CircadianPhase currentPhase;
  final ShiftSchedule shiftSchedule;

  CircadianClockPainter({
    required this.currentPhase,
    required this.shiftSchedule,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Background circle
    final bgPaint = Paint()
      ..color = AppTheme.surfaceDarkElevated
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Phase segments - dynamically generated from schedule
    final segments = _buildDynamicSegments();
    for (final segment in segments) {
      final paint = Paint()
        ..color = segment.color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 8),
        segment.startAngle - math.pi / 2,
        segment.sweepAngle,
        false,
        paint,
      );
    }

    // Current time indicator
    final now = DateTime.now();
    final hourAngle =
        (now.hour + now.minute / 60) / 24 * 2 * math.pi - math.pi / 2;

    final indicatorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final indicatorEnd = Offset(
      center.dx + (radius - 8) * math.cos(hourAngle),
      center.dy + (radius - 8) * math.sin(hourAngle),
    );

    canvas.drawCircle(indicatorEnd, 6, indicatorPaint);

    // Hour markers
    final markerPaint = Paint()
      ..color = AppTheme.textTertiary
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 24; i++) {
      final angle = i / 24 * 2 * math.pi - math.pi / 2;
      final isMain = i % 6 == 0;
      final markerRadius = isMain ? 3.0 : 1.5;
      final markerDist = radius + 10;

      final pos = Offset(
        center.dx + markerDist * math.cos(angle),
        center.dy + markerDist * math.sin(angle),
      );

      canvas.drawCircle(pos, markerRadius, markerPaint);
    }

    // Hour labels
    for (int i = 0; i < 24; i += 6) {
      final angle = i / 24 * 2 * math.pi - math.pi / 2;
      final labelDist = radius + 24;
      final pos = Offset(
        center.dx + labelDist * math.cos(angle),
        center.dy + labelDist * math.sin(angle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: i.toString().padLeft(2, '0'),
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2,
            pos.dy - textPainter.height / 2),
      );
    }
  }

  /// Build clock segments dynamically from the shift schedule.
  List<_ClockSegment> _buildDynamicSegments() {
    final service = AiHealthService();
    final hourPhases = service.generatePhaseTimeline(
      shiftType: shiftSchedule.type,
      schedule: shiftSchedule,
    );

    // Merge consecutive hours with same phase
    final segments = <_ClockSegment>[];
    int rangeStart = 0;
    CircadianPhase currentPhase =
        hourPhases[0]['phase'] as CircadianPhase;

    for (int i = 1; i <= 24; i++) {
      final phase =
          i < 24 ? hourPhases[i]['phase'] as CircadianPhase : currentPhase;
      if (i == 24 || phase != currentPhase) {
        final startAngle = rangeStart / 24 * 2 * math.pi;
        final sweepAngle = (i - rangeStart) / 24 * 2 * math.pi;
        segments.add(_ClockSegment(
          startAngle,
          sweepAngle,
          _phaseColor(currentPhase),
        ));
        rangeStart = i;
        currentPhase = phase;
      }
    }

    return segments;
  }

  Color _phaseColor(CircadianPhase phase) {
    switch (phase) {
      case CircadianPhase.alert:
        return AppTheme.circadianAlert;
      case CircadianPhase.active:
        return AppTheme.success;
      case CircadianPhase.drowsy:
        return AppTheme.circadianDrowsy;
      case CircadianPhase.sleep:
      case CircadianPhase.deepSleep:
        return AppTheme.circadianSleep;
      case CircadianPhase.waking:
        return AppTheme.circadianWaking;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ClockSegment {
  final double startAngle;
  final double sweepAngle;
  final Color color;

  _ClockSegment(this.startAngle, this.sweepAngle, this.color);
}
