import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../config/theme.dart';
import '../providers/health_provider.dart';

class CircadianMiniClock extends StatelessWidget {
  final CircadianPhase phase;
  final double score;
  final double size;
  final bool showLabel;

  const CircadianMiniClock({
    super.key,
    required this.phase,
    required this.score,
    this.size = 0,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final clockSize = size > 0 ? size : double.infinity;

    if (!showLabel) {
      return SizedBox(
        width: clockSize,
        height: clockSize,
        child: CustomPaint(
          painter: _MiniClockPainter(phase: phase, score: score),
          child: Center(
            child: Text(
              '${score.toInt()}',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDarkElevated.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getPhaseIcon(),
                color: _getPhaseColor(),
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                '리듬 점수',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${score.toInt()}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(width: 2),
              const Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Text(
                  '점',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getPhaseLabel(),
            style: TextStyle(
              color: _getPhaseColor(),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPhaseIcon() {
    switch (phase) {
      case CircadianPhase.alert:
        return Icons.bolt_rounded;
      case CircadianPhase.active:
        return Icons.trending_up_rounded;
      case CircadianPhase.drowsy:
        return Icons.nights_stay_rounded;
      case CircadianPhase.sleep:
      case CircadianPhase.deepSleep:
        return Icons.bedtime_rounded;
      case CircadianPhase.waking:
        return Icons.wb_sunny_rounded;
    }
  }

  Color _getPhaseColor() {
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

  String _getPhaseLabel() {
    switch (phase) {
      case CircadianPhase.alert:
        return '각성 상태';
      case CircadianPhase.active:
        return '최고 활동';
      case CircadianPhase.drowsy:
        return '졸림 구간';
      case CircadianPhase.sleep:
      case CircadianPhase.deepSleep:
        return '수면 시간';
      case CircadianPhase.waking:
        return '기상 시간';
    }
  }
}

class _MiniClockPainter extends CustomPainter {
  final CircadianPhase phase;
  final double score;

  _MiniClockPainter({required this.phase, required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Background arc
    final bgPaint = Paint()
      ..color = AppTheme.surfaceDarkElevated
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Score arc
    final scoreAngle = (score / 100) * 2 * math.pi;
    final scorePaint = Paint()
      ..color = _getScoreColor()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      scoreAngle,
      false,
      scorePaint,
    );
  }

  Color _getScoreColor() {
    if (score >= 80) return AppTheme.success;
    if (score >= 60) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
