import 'package:change/models/shift.dart';
import 'package:change/services/calendar_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

Shift _shift(String type,
        {String? start, String? end, String? note, String? swap}) =>
    Shift(
      id: type,
      date: DateTime(2026, 9, 18),
      type: type,
      startTime: start,
      endTime: end,
      note: note,
      swapWith: swap,
    );

void main() {
  test('working shifts become timed events with the stored times', () {
    final e = CalendarEventBuilder.build(
        [_shift('night', start: '21:30', end: '07:00')]).single;
    expect(e.date, '2026-09-18');
    expect(e.title, '야간 근무');
    expect(e.start, '21:30');
    expect(e.end, '07:00');
  });

  test('a shift without stored times falls back to the default times', () {
    final e = CalendarEventBuilder.build([_shift('day')]).single;
    expect(e.start, '06:00');
    expect(e.end, '14:00');
  });

  test('off days are all-day "휴무" events, not dropped', () {
    final e = CalendarEventBuilder.build([_shift('off')]).single;
    expect(e.title, '휴무');
    expect(e.start, isNull);
    expect(e.end, isNull);
  });

  test('the shift note is carried over, empty notes are not', () {
    expect(
      CalendarEventBuilder.build([_shift('day', note: '김OO과 교대')]).single.note,
      '김OO과 교대',
    );
    expect(CalendarEventBuilder.build([_shift('day', note: '')]).single.note,
        isNull);
  });

  test('a swap goes into the event note, ahead of the memo', () {
    final e = CalendarEventBuilder.build(
        [_shift('night', swap: '김간호사', note: '화요일에 갚기')]).single;
    expect(e.note, '김간호사과(와) 근무 교환\n화요일에 갚기');
  });
}
