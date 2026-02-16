import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/health_tip.dart';
import '../services/ai_health_service.dart';
import '../services/database_service.dart';
import 'schedule_provider.dart';
import 'sleep_provider.dart';

class HealthState {
  final List<HealthTip> currentTips;
  final CircadianPhase currentPhase;
  final List<CircadianPhase> todayPhases;
  final double circadianScore;
  final bool isLoading;
  final ShiftSchedule? currentSchedule;

  const HealthState({
    this.currentTips = const [],
    this.currentPhase = CircadianPhase.alert,
    this.todayPhases = const [],
    this.circadianScore = 0.0,
    this.isLoading = false,
    this.currentSchedule,
  });

  HealthState copyWith({
    List<HealthTip>? currentTips,
    CircadianPhase? currentPhase,
    List<CircadianPhase>? todayPhases,
    double? circadianScore,
    bool? isLoading,
    ShiftSchedule? currentSchedule,
  }) {
    return HealthState(
      currentTips: currentTips ?? this.currentTips,
      currentPhase: currentPhase ?? this.currentPhase,
      todayPhases: todayPhases ?? this.todayPhases,
      circadianScore: circadianScore ?? this.circadianScore,
      isLoading: isLoading ?? this.isLoading,
      currentSchedule: currentSchedule ?? this.currentSchedule,
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

    // Always use the latest custom shift times from settings,
    // not the stored shift times (which may be outdated).
    ShiftSchedule? schedule;
    if (todayShift != null && shiftType != 'off') {
      final latestTimes = await ScheduleNotifier.getShiftTimes(shiftType);
      if (latestTimes != null &&
          latestTimes['start'] != null &&
          latestTimes['end'] != null) {
        schedule = ShiftSchedule.fromTimeStrings(
            shiftType, latestTimes['start']!, latestTimes['end']!);
      } else if (todayShift.startTime != null &&
          todayShift.endTime != null) {
        schedule = ShiftSchedule.fromTimeStrings(
            shiftType, todayShift.startTime!, todayShift.endTime!);
      }
    }

    // Get user profile for age-based recommendations
    final profile = await DatabaseService.instance.getUserProfile();
    final userAge = profile?.age;

    // Generate tips with actual shift schedule
    final tips = _healthService.generateTips(
      currentShiftType: shiftType,
      averageSleepHours: sleepState.averageSleepHours,
      averageSleepQuality: sleepState.averageQuality,
      schedule: schedule,
      userAge: userAge,
    );

    // Calculate circadian phase with actual schedule
    final phase = _healthService.getCurrentCircadianPhase(
      shiftType: shiftType,
      schedule: schedule,
    );
    final score = _healthService.calculateCircadianScore(
      shiftType: shiftType,
      sleepRecords: sleepState.last7Days,
    );

    state = state.copyWith(
      currentTips: tips,
      currentPhase: phase,
      circadianScore: score,
      isLoading: false,
      currentSchedule: schedule,
    );
  }
}

final healthProvider =
    StateNotifierProvider<HealthNotifier, HealthState>((ref) {
  return HealthNotifier(AiHealthService(), ref);
});
