import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/health_tip.dart';
import '../services/ai_health_service.dart';
import 'schedule_provider.dart';
import 'sleep_provider.dart';

class HealthState {
  final List<HealthTip> currentTips;
  final CircadianPhase currentPhase;
  final List<CircadianPhase> todayPhases;
  final double circadianScore;
  final bool isLoading;

  const HealthState({
    this.currentTips = const [],
    this.currentPhase = CircadianPhase.alert,
    this.todayPhases = const [],
    this.circadianScore = 0.0,
    this.isLoading = false,
  });

  HealthState copyWith({
    List<HealthTip>? currentTips,
    CircadianPhase? currentPhase,
    List<CircadianPhase>? todayPhases,
    double? circadianScore,
    bool? isLoading,
  }) {
    return HealthState(
      currentTips: currentTips ?? this.currentTips,
      currentPhase: currentPhase ?? this.currentPhase,
      todayPhases: todayPhases ?? this.todayPhases,
      circadianScore: circadianScore ?? this.circadianScore,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

enum CircadianPhase {
  alert,
  active,
  drowsy,
  sleep,
  deepSleep,
  waking,
}

class HealthNotifier extends StateNotifier<HealthState> {
  final AiHealthService _healthService;
  final Ref _ref;

  HealthNotifier(this._healthService, this._ref) : super(const HealthState());

  Future<void> refreshHealthData() async {
    state = state.copyWith(isLoading: true);

    final scheduleState = _ref.read(scheduleProvider);
    final sleepState = _ref.read(sleepProvider);

    final todayShift = scheduleState.todayShift;
    final shiftType = todayShift?.type ?? 'day';

    // Generate AI health tips based on shift pattern and sleep data
    final tips = _healthService.generateTips(
      currentShiftType: shiftType,
      averageSleepHours: sleepState.averageSleepHours,
      averageSleepQuality: sleepState.averageQuality,
    );

    // Calculate current circadian phase
    final phase = _healthService.getCurrentCircadianPhase(shiftType);
    final score = _healthService.calculateCircadianScore(
      shiftType: shiftType,
      sleepRecords: sleepState.last7Days,
    );

    state = state.copyWith(
      currentTips: tips,
      currentPhase: phase,
      circadianScore: score,
      isLoading: false,
    );
  }
}

final healthProvider =
    StateNotifierProvider<HealthNotifier, HealthState>((ref) {
  return HealthNotifier(AiHealthService(), ref);
});
