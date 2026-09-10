import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:change/widgets/condition_metric.dart';

/// The condition card puts four metrics beside a 72dp score ring. On the
/// narrowest phone that leaves each one about 60dp, which a value like
/// "12.3천" does not fit at the nominal font size — it has to scale down
/// rather than overflow.
void main() {
  /// Width left for the metric row on a 320dp-wide screen:
  /// 320 − 40 (screen padding) − 40 (card padding) − 72 (ring) − 20 (gap).
  const narrowRowWidth = 148.0;

  Widget harness(double width, List<ConditionMetric> metrics) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: Row(
              children: [
                for (final m in metrics) Expanded(child: m),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<ConditionMetric> metrics({
    String sleep = '7.5h',
    String energy = '3.8',
    String steps = '8.2천',
    String heart = '72',
  }) =>
      [
        ConditionMetric(
            icon: Icons.bedtime_rounded,
            label: '수면',
            value: sleep,
            color: const Color(0xFF7E57C2)),
        ConditionMetric(
            icon: Icons.bolt_rounded,
            label: '에너지',
            value: energy,
            color: const Color(0xFFE8985A)),
        ConditionMetric(
            icon: Icons.directions_walk_rounded,
            label: '걸음',
            value: steps,
            color: const Color(0xFF4CAF50)),
        ConditionMetric(
            icon: Icons.favorite_rounded,
            label: '심박',
            value: heart,
            color: const Color(0xFFE57373)),
      ];

  testWidgets('four metrics fit the narrowest phone without overflowing',
      (tester) async {
    await tester.pumpWidget(harness(narrowRowWidth, metrics()));
    expect(tester.takeException(), isNull);

    for (final label in ['수면', '에너지', '걸음', '심박']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('72'), findsOneWidget, reason: 'heart rate is shown');
  });

  testWidgets('the longest realistic values still do not overflow',
      (tester) async {
    await tester.pumpWidget(harness(
      narrowRowWidth,
      metrics(sleep: '12.5h', energy: '5.0', steps: '12.3천', heart: '188'),
    ));
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing readings render as -- rather than a stale zero',
      (tester) async {
    await tester.pumpWidget(harness(
      narrowRowWidth,
      metrics(steps: '--', heart: '--'),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('--'), findsNWidgets(2));
  });
}
