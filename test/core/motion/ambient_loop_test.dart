// B1-02: every decorative loop runs on one engine (AmbientLoop) behind one
// on-screen gate — at most AppMotion.ambientBudget per appearance, never off
// screen, on a hidden tab (TickerMode), in the background, under reduced
// motion or with a screen reader; a new appearance gets a fresh budget.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/motion/ambient_loop.dart';
import 'package:hero_mart/src/core/motion/float_loop.dart';
import 'package:hero_mart/src/core/motion/idle_loop.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/motion/play_when_on_screen.dart';

const Duration _frame = Duration(milliseconds: 16);
const Duration _lap = Duration(milliseconds: 1000);

Widget _host(
  Widget child, {
  bool reduced = false,
  bool screenReader = false,
  bool tickers = true,
}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: reduced,
        accessibleNavigation: screenReader,
      ),
      child: TickerMode(
        enabled: tickers,
        child: Scaffold(body: child),
      ),
    ),
  ),
);

/// A loop that records the value of every frame it builds.
Widget _loop(
  List<double> seen, {
  Duration period = _lap,
  bool replay = true,
  Duration rest = Duration.zero,
}) => AmbientLoop.value(
  period: period,
  rest: rest,
  replay: replay,
  valueBuilder: (context, t, child) {
    seen.add(t);
    return child;
  },
  child: const SizedBox.square(dimension: 80),
);

/// The loop at the top of a long page, to scroll it away and back.
Widget _feed(List<double> seen, ScrollController feed) => SingleChildScrollView(
  controller: feed,
  child: Column(children: [_loop(seen), const SizedBox(height: 3000)]),
);

/// Pumps [duration] as real frames (every 16 ms), the way a device draws:
/// a lap ends on the frame after its last one.
Future<void> _frames(WidgetTester tester, Duration duration) async {
  for (var left = duration; left > Duration.zero; left -= _frame) {
    await tester.pump(left < _frame ? left : _frame);
  }
}

void main() {
  group('the budget', () {
    testWidgets('whole laps run within ambientBudget, then nothing ticks', (
      tester,
    ) async {
      final seen = <double>[];
      await tester.pumpWidget(_host(_loop(seen)));
      expect(tester.hasRunningAnimations, isTrue);

      await _frames(tester, AppMotion.ambientBudget - _lap ~/ 2);
      expect(tester.hasRunningAnimations, isTrue, reason: 'inside the budget');

      await _frames(tester, _lap);
      await tester.pump(_frame);
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.binding.hasScheduledFrame, isFalse);
      // Every lap ends on the resting pose (1 = 0 for a cyclic loop).
      final rested = seen.last;
      await tester.pump(AppMotion.ambientBudget * 2);
      expect(seen.last, rested);
    });

    testWidgets('a lap longer than the budget lands at the deadline', (
      tester,
    ) async {
      final seen = <double>[];
      await tester.pumpWidget(
        _host(_loop(seen, period: AppMotion.ambientBudget * 2)),
      );
      await _frames(tester, AppMotion.ambientBudget);
      await tester.pump(AppMotion.medium);
      await tester.pump(_frame);
      expect(tester.hasRunningAnimations, isFalse);
      expect(seen.last, 1, reason: 'landed on the end of its lap');
    });

    testWidgets('rests between laps draw no frames and count to the budget', (
      tester,
    ) async {
      final seen = <double>[];
      const rest = Duration(milliseconds: 1500);
      await tester.pumpWidget(_host(_loop(seen, rest: rest)));
      await tester.pump(_lap);
      await tester.pump(_frame);
      expect(tester.binding.hasScheduledFrame, isFalse, reason: 'resting');

      // Laps at 0, 2.5 s; a third would end at 6 s: past the budget.
      await tester.pump(rest);
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pump(_lap);
      await tester.pump(_frame);
      await tester.pump(rest + _lap);
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('a counted loop (replay: false) never plays again', (
      tester,
    ) async {
      final seen = <double>[];
      await tester.pumpWidget(_host(_loop(seen, replay: false)));
      await _frames(tester, AppMotion.ambientBudget);
      await tester.pump(_frame);

      await tester.pumpWidget(
        _host(_loop(seen, replay: false), tickers: false),
      );
      await tester.pumpWidget(_host(_loop(seen, replay: false)));
      await tester.pump(_frame);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('the gate', () {
    testWidgets('stops when its tab is hidden (TickerMode off)', (
      tester,
    ) async {
      final seen = <double>[];
      await tester.pumpWidget(_host(_loop(seen)));
      await tester.pump(_lap ~/ 4);
      expect(seen.last, greaterThan(0));

      await tester.pumpWidget(_host(_loop(seen), tickers: false));
      await tester.pump();
      expect(seen.last, 0, reason: 'the resting pose');
      await tester.pump(_lap);
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.binding.hasScheduledFrame, isFalse);

      // The tab comes back: a new appearance, a fresh budget.
      await tester.pumpWidget(_host(_loop(seen)));
      await tester.pump(_lap ~/ 4);
      expect(tester.hasRunningAnimations, isTrue);
      expect(seen.last, greaterThan(0));
    });

    for (final (name, reduced, screenReader) in [
      ('reduced motion', true, false),
      ('a screen reader', false, true),
    ]) {
      testWidgets('with $name: the resting pose, no frames', (tester) async {
        final seen = <double>[];
        await tester.pumpWidget(
          _host(_loop(seen), reduced: reduced, screenReader: screenReader),
        );
        await tester.pump(_lap);
        expect(seen.toSet(), {0.0});
        expect(tester.hasRunningAnimations, isFalse);
        expect(tester.binding.hasScheduledFrame, isFalse);
      });
    }

    testWidgets('scrolled off screen it rests; back on it plays again', (
      tester,
    ) async {
      final seen = <double>[];
      final feed = ScrollController();
      addTearDown(feed.dispose);
      await tester.pumpWidget(_host(_feed(seen, feed)));
      // Each lap ends a frame late; the deadline lands the last one.
      await _frames(tester, AppMotion.ambientBudget + AppMotion.medium);
      expect(tester.hasRunningAnimations, isFalse, reason: 'budget spent');

      feed.jumpTo(2000);
      await tester.pump();
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);

      feed.jumpTo(0);
      await tester.pump();
      await tester.pump(_lap ~/ 4);
      expect(tester.hasRunningAnimations, isTrue, reason: 'a new appearance');

      feed.jumpTo(2000);
      await tester.pump();
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse, reason: 'off screen');
      expect(seen.last, 0);
    });

    testWidgets('stops while the app is in the background', (tester) async {
      final seen = <double>[];
      await tester.pumpWidget(_host(_loop(seen)));
      await tester.pump(_lap ~/ 4);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(_lap ~/ 4);
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('PlayWhenOnScreen tells its builder when to play', (
      tester,
    ) async {
      final plays = <bool>[];
      final feed = ScrollController();
      addTearDown(feed.dispose);
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(
            controller: feed,
            child: Column(
              children: [
                PlayWhenOnScreen(
                  builder: (context, play) {
                    plays.add(play);
                    return const SizedBox.square(dimension: 80);
                  },
                ),
                const SizedBox(height: 3000),
              ],
            ),
          ),
        ),
      );
      expect(plays.last, isTrue);

      feed.jumpTo(2000);
      await tester.pump();
      await tester.pump();
      expect(plays.last, isFalse);
    });
  });

  group('presets', () {
    testWidgets('FloatLoop.glow breathes through transitions, then rests', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const FloatLoop.glow(color: Colors.amber, diameter: 40)),
      );
      final fade = tester.widget<FadeTransition>(
        find.descendant(
          of: find.byType(FloatLoop),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(fade.opacity.value, FloatLoop.defaultMinOpacity);
      await tester.pump(AppMotion.floatLoop ~/ 2);
      expect(fade.opacity.value, closeTo(FloatLoop.defaultMaxOpacity, 0.01));

      await _frames(tester, AppMotion.ambientBudget);
      await tester.pump(_frame);
      expect(tester.hasRunningAnimations, isFalse);
      expect(fade.opacity.value, closeTo(FloatLoop.defaultMinOpacity, 0.01));
    });

    testWidgets('IdleLoop rests while not running', (tester) async {
      final loops = <Animation<double>>[];
      Widget idle({required bool running}) => _host(
        IdleLoop(
          running: running,
          builder: (context, loop) {
            loops.add(loop);
            return const SizedBox.square(dimension: 40);
          },
        ),
      );
      await tester.pumpWidget(idle(running: true));
      await tester.pump(_lap);
      expect(loops.last.value, greaterThan(0));

      await tester.pumpWidget(idle(running: false));
      await tester.pump();
      expect(loops.last.value, 0);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
