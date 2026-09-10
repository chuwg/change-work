import 'package:flutter_test/flutter_test.dart';

import 'package:change/providers/health_sync_provider.dart';

/// copyWith used the `value ?? this.value` idiom, which cannot express
/// "set this back to null". A failed HealthKit read therefore kept the previous
/// reading on screen, and turning sync off left the step count behind.
void main() {
  const populated = HealthSyncState(
    isAuthorized: true,
    syncEnabled: true,
    todaySteps: 8200,
    lastHeartRate: 72,
  );

  test('omitted fields are left untouched', () {
    final next = populated.copyWith(isSyncing: true);

    expect(next.isSyncing, isTrue);
    expect(next.todaySteps, 8200);
    expect(next.lastHeartRate, 72);
  });

  test('an explicit null actually clears the reading', () {
    final next = populated.copyWith(todaySteps: null, lastHeartRate: null);

    expect(next.todaySteps, isNull);
    expect(next.lastHeartRate, isNull);
  });

  test('turning sync off clears the readings it was showing', () {
    final next = populated.copyWith(
      syncEnabled: false,
      todaySteps: null,
      lastHeartRate: null,
    );

    expect(next.syncEnabled, isFalse);
    expect(next.todaySteps, isNull,
        reason: 'a stale step count must not outlive the sync being disabled');
  });

  test('zero steps is a real reading, not an absence', () {
    final next = populated.copyWith(todaySteps: 0);

    expect(next.todaySteps, 0);
    expect(next.todaySteps, isNotNull);
  });

  test('lastSyncAt clears only when explicitly asked', () {
    final synced = populated.copyWith(lastSyncAt: DateTime(2026, 9, 10, 8));
    expect(synced.copyWith(isSyncing: true).lastSyncAt, isNotNull);
    expect(synced.copyWith(clearLastSync: true).lastSyncAt, isNull);
  });
}
