// DeferredValue sequences a state change: the first value at once, a change
// only after its delay (the newest one wins, a change back cancels it), and
// no wait at all under reduced motion.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/motion/deferred_value.dart';

void main() {
  const delay = Duration(milliseconds: 300);

  Future<void> pump(
    WidgetTester tester,
    ValueNotifier<int> value, {
    bool reduceMotion = false,
  }) => tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: ValueListenableBuilder<int>(
          valueListenable: value,
          builder: (_, current, _) => DeferredValue<int>(
            value: current,
            delay: delay,
            builder: (_, shown) => Text('shown:$shown'),
          ),
        ),
      ),
    ),
  );

  testWidgets('the first value at once, a change after its delay', (
    tester,
  ) async {
    final value = ValueNotifier<int>(1);
    addTearDown(value.dispose);
    await pump(tester, value);
    expect(find.text('shown:1'), findsOneWidget);

    value.value = 2;
    await tester.pump();
    expect(find.text('shown:1'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 299));
    expect(find.text('shown:1'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('shown:2'), findsOneWidget);
  });

  testWidgets('the newest change wins; a change back cancels the wait', (
    tester,
  ) async {
    final value = ValueNotifier<int>(1);
    addTearDown(value.dispose);
    await pump(tester, value);

    // Each change lands with the frame that follows it (`pump()`).
    value.value = 2;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    value.value = 3;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('shown:1'), findsOneWidget); // the wait restarted
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('shown:3'), findsOneWidget);

    value.value = 4;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    value.value = 3;
    await tester.pump();
    await tester.pump(delay);
    expect(find.text('shown:3'), findsOneWidget);
  });

  testWidgets('reduced motion: no wait', (tester) async {
    final value = ValueNotifier<int>(1);
    addTearDown(value.dispose);
    await pump(tester, value, reduceMotion: true);

    value.value = 2;
    await tester.pump();
    expect(find.text('shown:2'), findsOneWidget);
  });

  testWidgets('disposed while waiting leaves no timer behind', (tester) async {
    final value = ValueNotifier<int>(1);
    addTearDown(value.dispose);
    await pump(tester, value);
    value.value = 2;
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    // The test binding fails the test on a pending timer.
  });
}
