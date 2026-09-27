// SecondClock + SecondClockScope + CountdownDigits: one aligned timer for
// every countdown on a page, only while someone listens and the page is on
// stage; a countdown beyond its window or at zero lets go of the clock;
// reduced motion still ticks; screen readers hear a change once a minute.
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:easy_localization/src/localization.dart';
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/motion/second_clock.dart';
import 'package:hero_mart/src/core/motion/second_clock_scope.dart';
import 'package:hero_mart/src/core/widgets/countdown_digit_box.dart';
import 'package:hero_mart/src/core/widgets/countdown_digits.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/rebuild_probe.dart';

/// The card a countdown sits in (the probe checks it never rebuilds).
class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: children);
}

Widget _host(
  WidgetTester tester,
  Widget child, {
  bool tickers = true,
  bool reduced = false,
}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
      child: Scaffold(
        body: TickerMode(
          enabled: tickers,
          child: SecondClockScope(
            clock: () => tester.binding.clock.now(),
            child: Center(child: child),
          ),
        ),
      ),
    ),
  ),
);

SecondClock _clockOf(WidgetTester tester) =>
    tester.state<SecondClockScopeState>(find.byType(SecondClockScope)).clock;

/// The three boxes of the only countdown on screen, "hh:mm:ss".
String _digits(WidgetTester tester) => tester
    .widgetList<CountdownDigitBox>(find.byType(CountdownDigitBox))
    .map((box) => box.digits)
    .join(':');

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    // The app's own copy, so the `core.countdown_label` key is checked too.
    final raw = await rootBundle.loadString('assets/i18n/en.json');
    Localization.load(
      const Locale('en'),
      translations: Translations(json.decode(raw) as Map<String, dynamic>),
    );
  });

  testWidgets('CT-C1 one timer for many countdowns, aligned to the second', (
    tester,
  ) async {
    final now = tester.binding.clock.now();
    await tester.pumpWidget(
      _host(
        tester,
        _Card(
          children: [
            for (var h = 1; h <= 3; h++)
              CountdownDigits(endsAt: now.add(Duration(hours: h))),
          ],
        ),
      ),
    );
    expect(_clockOf(tester).debugIsRunning, isTrue);

    final probe = RebuildProbe<Widget, Type>((widget) => widget.runtimeType)
      ..start();
    addTearDown(probe.stop);
    await tester.pump(const Duration(seconds: 1));

    expect(probe.of(CountdownDigits), 3);
    expect(probe.of(_Card), 0);
    expect(find.text('59'), findsNWidgets(6)); // minutes and seconds, ×3
  });

  testWidgets('CT-C2 beyond the 24 h window: a date, no listener', (
    tester,
  ) async {
    final now = tester.binding.clock.now();
    final endsAt = now.add(const Duration(days: 3));
    expect(CountdownDigits.countsDown(endsAt, now), isFalse);
    expect(
      CountdownDigits.countsDown(now.add(const Duration(hours: 5)), now),
      isTrue,
    );
    expect(CountdownDigits.countsDown(now, now), isFalse);
    expect(CountdownDigits.countsDown(null, now), isFalse);

    // The host's pattern: a countdown inside the window, a date beyond it.
    await tester.pumpWidget(
      _host(
        tester,
        CountdownDigits.countsDown(endsAt, now)
            ? CountdownDigits(endsAt: endsAt)
            : const Text('a date'),
      ),
    );
    expect(find.byType(CountdownDigits), findsNothing);
    expect(_clockOf(tester).debugIsRunning, isFalse);

    // Even mounted directly, a far countdown does not hold the clock.
    await tester.pumpWidget(_host(tester, CountdownDigits(endsAt: endsAt)));
    expect(_clockOf(tester).debugIsRunning, isFalse);
  });

  testWidgets('CT-C3 TickerMode off stops the clock; back on shows the right '
      'second at once', (tester) async {
    final endsAt = tester.binding.clock.now().add(const Duration(minutes: 10));
    Widget host({required bool tickers}) =>
        _host(tester, CountdownDigits(endsAt: endsAt), tickers: tickers);

    await tester.pumpWidget(host(tickers: false));
    expect(_clockOf(tester).debugIsRunning, isFalse);
    expect(_digits(tester), '00:10:00');

    await tester.pump(const Duration(seconds: 5));
    expect(_digits(tester), '00:10:00');

    await tester.pumpWidget(host(tickers: true));
    expect(_digits(tester), '00:09:55');
    expect(_clockOf(tester).debugIsRunning, isTrue);
  });

  testWidgets('CT-C4 a countdown at zero lets go', (tester) async {
    var ended = 0;
    final endsAt = tester.binding.clock.now().add(const Duration(seconds: 2));
    await tester.pumpWidget(
      _host(tester, CountdownDigits(endsAt: endsAt, onEnded: () => ended++)),
    );
    expect(_digits(tester), '00:00:02');

    await tester.pump(const Duration(seconds: 3));
    expect(ended, 1);
    expect(_clockOf(tester).debugIsRunning, isFalse);
    expect(find.byType(CountdownDigitBox), findsNothing);
  });

  testWidgets('CT-C5 reduced motion still ticks', (tester) async {
    final endsAt = tester.binding.clock.now().add(const Duration(hours: 2));
    await tester.pumpWidget(
      _host(tester, CountdownDigits(endsAt: endsAt), reduced: true),
    );
    expect(_digits(tester), '02:00:00');

    await tester.pump(const Duration(seconds: 1));
    expect(_digits(tester), '01:59:59');
  });

  testWidgets('CT-C6 the label changes once a minute', (tester) async {
    final semantics = tester.ensureSemantics();
    final endsAt = tester.binding.clock.now().add(
      const Duration(hours: 6, minutes: 36, seconds: 36),
    );
    await tester.pumpWidget(_host(tester, CountdownDigits(endsAt: endsAt)));
    String label() => tester.getSemantics(find.byType(CountdownDigits)).label;

    expect(label(), 'Ends in 6 h 36 min');
    await tester.pump(const Duration(seconds: 1));
    expect(label(), 'Ends in 6 h 36 min');
    expect(_digits(tester), '06:36:35');

    await tester.pump(const Duration(seconds: 60));
    expect(label(), 'Ends in 6 h 35 min');
    semantics.dispose();
  });

  testWidgets('the digits read left to right in Arabic too', (tester) async {
    final endsAt = tester.binding.clock.now().add(const Duration(hours: 6));
    await tester.pumpWidget(
      _host(
        tester,
        Directionality(
          textDirection: TextDirection.rtl,
          child: CountdownDigits(endsAt: endsAt),
        ),
      ),
    );
    final hours = tester.getTopLeft(find.text('06')).dx;
    final seconds = tester.getTopLeft(find.text('00').last).dx;
    expect(hours, lessThan(seconds));
  });

  testWidgets('a minute-period clock ticks on the minute and not before', (
    tester,
  ) async {
    // Start 20 s into a minute.
    await tester.pump(const Duration(seconds: 20));
    final clock = SecondClock(
      clock: () => tester.binding.clock.now(),
      period: const Duration(minutes: 1),
    );
    final seen = <DateTime>[];
    void listener() => seen.add(clock.now);
    final start = clock.now;
    expect(start.second, 0);

    clock.addListener(listener);
    expect(clock.debugIsRunning, isTrue);

    await tester.pump(const Duration(seconds: 39));
    expect(seen, isEmpty);

    await tester.pump(const Duration(seconds: 1));
    expect(seen, [start.add(const Duration(minutes: 1))]);

    await tester.pump(const Duration(seconds: 59));
    expect(seen, hasLength(1));
    await tester.pump(const Duration(seconds: 1));
    expect(seen, hasLength(2));

    clock.removeListener(listener);
    expect(clock.debugIsRunning, isFalse);
    clock.dispose();
  });

  testWidgets('a disabled clock rests and reads the real time', (tester) async {
    final clock = SecondClock(clock: () => tester.binding.clock.now());
    var ticks = 0;
    clock
      ..addListener(() => ticks++)
      ..enabled = false;
    expect(clock.debugIsRunning, isFalse);

    await tester.pump(const Duration(seconds: 3));
    expect(ticks, 0);
    expect(clock.now, tester.binding.clock.now());

    clock.enabled = true;
    expect(ticks, 1);
    expect(clock.debugIsRunning, isTrue);

    // Disposing cancels the pending tick.
    clock.dispose();
  });
}
