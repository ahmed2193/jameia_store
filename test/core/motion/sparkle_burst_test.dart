// SparkleBurst: stars around a figure that just got better — never on mount,
// once per new non-null key, painted from the controller (no rebuild per
// frame), invisible to screen readers, mirrored in RTL, and nothing under
// reduced motion. A burst on a covered page plays when it is revealed.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/motion/motion.dart';
import 'package:jameia_mart/src/core/motion/sparkle_burst.dart';
import 'package:jameia_mart/src/core/motion/sparkle_painter.dart';

Widget _host(
  Widget child, {
  bool reduced = false,
  bool tickers = true,
  TextDirection direction = TextDirection.ltr,
}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduced),
  child: Directionality(
    textDirection: direction,
    child: TickerMode(
      enabled: tickers,
      child: Center(child: child),
    ),
  ),
);

int _builds = 0;

/// Counts its builds, so a per-frame rebuild would show.
class _Probe extends StatefulWidget {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  Widget build(BuildContext context) {
    _builds++;
    return const SizedBox(width: 80, height: 24);
  }
}

SparkleBurst _burst(Object? key) =>
    SparkleBurst(playKey: key, child: const _Probe());

final Finder _stars = find.byWidgetPredicate(
  (widget) => widget is CustomPaint && widget.painter is SparklePainter,
);

void main() {
  setUp(() => _builds = 0);

  testWidgets('never on mount, even with a key', (tester) async {
    await tester.pumpWidget(_host(_burst('SAVE10')));
    await tester.pump(AppMotion.drawOn ~/ 7);

    expect(_stars, findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('one burst per new non-null key, then nothing is left', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_burst(null)));
    await tester.pumpWidget(_host(_burst('SAVE10')));
    await tester.pump(AppMotion.drawOn ~/ 14);
    expect(_stars, findsOneWidget);

    await tester.pump(AppMotion.drawOn);
    expect(_stars, findsNothing);
    expect(tester.hasRunningAnimations, isFalse);

    // The same key again: nothing.
    await tester.pumpWidget(_host(_burst('SAVE10')));
    await tester.pump(AppMotion.drawOn ~/ 14);
    expect(_stars, findsNothing);

    // A null key never plays.
    await tester.pumpWidget(_host(_burst(null)));
    await tester.pump(AppMotion.drawOn ~/ 14);
    expect(_stars, findsNothing);

    // A new key plays again.
    await tester.pumpWidget(_host(_burst('WELCOME')));
    await tester.pump(AppMotion.drawOn ~/ 14);
    expect(_stars, findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('the child keeps its element and is not rebuilt per frame', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_burst(null)));
    final element = tester.element(find.byType(_Probe));

    await tester.pumpWidget(_host(_burst('SAVE10')));
    final buildsAtStart = _builds;
    for (var i = 0; i < 6; i++) {
      await tester.pump(AppMotion.drawOn ~/ 10);
    }
    expect(_stars, findsOneWidget);
    expect(_builds, buildsAtStart);
    expect(identical(tester.element(find.byType(_Probe)), element), isTrue);

    await tester.pumpAndSettle();
    expect(identical(tester.element(find.byType(_Probe)), element), isTrue);
  });

  testWidgets('the stars are outside semantics and ignore touches', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_burst(null)));
    await tester.pumpWidget(_host(_burst('SAVE10')));
    await tester.pump(AppMotion.drawOn ~/ 14);

    expect(
      find.ancestor(of: _stars, matching: find.byType(ExcludeSemantics)),
      findsWidgets,
    );
    expect(
      find.ancestor(of: _stars, matching: find.byType(IgnorePointer)),
      findsWidgets,
    );
    expect(
      find.ancestor(of: _stars, matching: find.byType(RepaintBoundary)),
      findsWidgets,
    );
    await tester.pumpAndSettle();
  });

  testWidgets('RTL mirrors the stars', (tester) async {
    await tester.pumpWidget(_host(_burst(null), direction: TextDirection.rtl));
    await tester.pumpWidget(
      _host(_burst('SAVE10'), direction: TextDirection.rtl),
    );
    await tester.pump(AppMotion.drawOn ~/ 14);

    final painter = tester.widget<CustomPaint>(_stars).painter!;
    expect((painter as SparklePainter).direction, TextDirection.rtl);
    // The painted box is the child's plus the spread on every side.
    expect(
      tester.getSize(_stars),
      const Size(
        80 + 2 * SparkleBurst.defaultSpread,
        24 + 2 * SparkleBurst.defaultSpread,
      ),
    );
    const size = Size(100, 50);
    for (var i = 0; i < SparklePainter.anchors.length; i++) {
      final ltr = SparklePainter.centerOf(i, size, TextDirection.ltr);
      final rtl = SparklePainter.centerOf(i, size, TextDirection.rtl);
      expect(rtl.dx, closeTo(size.width - ltr.dx, 1e-9));
      expect(rtl.dy, ltr.dy);
    }
    await tester.pumpAndSettle();
  });

  testWidgets('reduced motion: no stars, nothing running', (tester) async {
    await tester.pumpWidget(_host(_burst(null), reduced: true));
    await tester.pumpWidget(_host(_burst('SAVE10'), reduced: true));
    await tester.pump();

    expect(_stars, findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('covered: the burst waits, then plays once on reveal', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_burst(null), tickers: false));
    await tester.pumpWidget(_host(_burst('SAVE10'), tickers: false));
    await tester.pump(AppMotion.drawOn * 3);
    expect(_stars, findsNothing);
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pumpWidget(_host(_burst('SAVE10')));
    await tester.pump(AppMotion.drawOn ~/ 7);
    expect(_stars, findsOneWidget);

    await tester.pump(AppMotion.drawOn);
    expect(_stars, findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  test('star lives are staggered and bounded', () {
    expect(SparklePainter.lifeOf(0, 0), 0);
    expect(SparklePainter.lifeOf(0, 0.5), 1);
    expect(SparklePainter.lifeOf(4, 0.4), 0);
    expect(SparklePainter.lifeOf(4, 0.65), closeTo(0.5, 1e-9));
    expect(SparklePainter.lifeOf(4, 1), 1);
  });
}
