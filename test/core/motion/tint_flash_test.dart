// TintFlash: one colour wash on a real change — never on mount, filtered by
// `when`, under or over the child, and never at the cost of the child's
// identity (a rolling / counting number inside keeps its state). Reduced
// motion does nothing; a change on a covered page plays on reveal.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/motion/tint_flash.dart';

const Color _wash = Color(0xFF00AA00);

Widget _host(Widget child, {bool reduced = false, bool tickers = true}) =>
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: TickerMode(
          enabled: tickers,
          child: Center(child: child),
        ),
      ),
    );

/// A stateful child, so its element and state identity can be pinned.
class _Probe extends StatefulWidget {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  Widget build(BuildContext context) =>
      const SizedBox(width: 80, height: 24, child: Text('total'));
}

TintFlash<int> _flash(
  int value, {
  bool over = false,
  bool Function(int, int)? when,
  double peakAlpha = TintFlash.defaultPeakAlpha,
}) => TintFlash<int>(
  value: value,
  color: _wash,
  over: over,
  when: when,
  peakAlpha: peakAlpha,
  child: const _Probe(),
);

Finder _inFlash(Type type) => find.descendant(
  of: find.byType(TintFlash<int>),
  matching: find.byType(type),
);

double _opacity(WidgetTester tester) =>
    tester.widget<FadeTransition>(_inFlash(FadeTransition)).opacity.value;

void main() {
  testWidgets('never washes on mount', (tester) async {
    await tester.pumpWidget(_host(_flash(1)));
    await tester.pump(AppMotion.breathe);

    expect(_inFlash(FadeTransition), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('a change washes once: rises to the peak, fades, and leaves '
      'no layer behind', (tester) async {
    await tester.pumpWidget(_host(_flash(1, peakAlpha: 0.35)));
    await tester.pumpWidget(_host(_flash(2, peakAlpha: 0.35)));
    await tester.pump();
    expect(_inFlash(FadeTransition), findsOneWidget);
    expect(_inFlash(RepaintBoundary), findsOneWidget);

    // The rise takes the first quarter of the run.
    await tester.pump(AppMotion.breathe ~/ 4);
    expect(_opacity(tester), closeTo(0.35, 0.01));
    await tester.pump(AppMotion.breathe ~/ 4);
    expect(_opacity(tester), inExclusiveRange(0, 0.35));

    await tester.pump(AppMotion.breathe);
    expect(_inFlash(FadeTransition), findsNothing);
    expect(_inFlash(RepaintBoundary), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('`when` decides which changes wash', (tester) async {
    bool drop(int previous, int next) => next < previous;
    await tester.pumpWidget(_host(_flash(5, when: drop)));

    await tester.pumpWidget(_host(_flash(7, when: drop)));
    await tester.pump(AppMotion.breathe ~/ 6);
    expect(_inFlash(FadeTransition), findsNothing);

    await tester.pumpWidget(_host(_flash(3, when: drop)));
    await tester.pump(AppMotion.breathe ~/ 6);
    expect(_inFlash(FadeTransition), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('under puts the layer before the child, over after it', (
    tester,
  ) async {
    Stack stack() => tester.widget<Stack>(_inFlash(Stack).first);

    await tester.pumpWidget(_host(_flash(1)));
    expect(stack().children.first, isA<Positioned>());
    expect(stack().children.last, isNot(isA<Positioned>()));

    await tester.pumpWidget(_host(_flash(1, over: true)));
    expect(stack().children.first, isNot(isA<Positioned>()));
    expect(stack().children.last, isA<Positioned>());
  });

  testWidgets('the child keeps its element and state through a wash', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_flash(1, over: true)));
    final element = tester.element(find.byType(_Probe));
    final state = tester.state(find.byType(_Probe));

    await tester.pumpWidget(_host(_flash(2, over: true)));
    await tester.pump(AppMotion.breathe ~/ 3);
    expect(_inFlash(FadeTransition), findsOneWidget);
    expect(identical(tester.element(find.byType(_Probe)), element), isTrue);

    await tester.pump(AppMotion.breathe);
    expect(identical(tester.element(find.byType(_Probe)), element), isTrue);
    expect(identical(tester.state(find.byType(_Probe)), state), isTrue);
  });

  testWidgets('the wash reaches `inflate` past the child on every side', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const TintFlash<int>(
          value: 1,
          color: _wash,
          inflate: 4,
          child: SizedBox(width: 80, height: 24),
        ),
      ),
    );
    await tester.pumpWidget(
      _host(
        const TintFlash<int>(
          value: 2,
          color: _wash,
          inflate: 4,
          child: SizedBox(width: 80, height: 24),
        ),
      ),
    );
    await tester.pump(AppMotion.breathe ~/ 4);

    expect(tester.getSize(_inFlash(FadeTransition)), const Size(88, 32));
    expect(tester.getSize(find.byType(TintFlash<int>)), const Size(80, 24));
    await tester.pumpAndSettle();
  });

  testWidgets('reduced motion: no wash, nothing running', (tester) async {
    await tester.pumpWidget(_host(_flash(1), reduced: true));
    await tester.pumpWidget(_host(_flash(2), reduced: true));
    await tester.pump();

    expect(_inFlash(FadeTransition), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('covered: a change waits, then washes once on reveal', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_flash(1), tickers: false));
    await tester.pumpWidget(_host(_flash(2), tickers: false));
    await tester.pump(AppMotion.breathe * 2);
    // Muted: the wash waits unbuilt, and no frame is scheduled for it.
    expect(_inFlash(FadeTransition), findsNothing);
    expect(tester.binding.hasScheduledFrame, isFalse);

    // Revealed after a long cover: the whole wash is seen, from its start.
    await tester.pumpWidget(_host(_flash(2)));
    await tester.pump();
    expect(_opacity(tester), lessThan(0.1));
    await tester.pump(AppMotion.breathe ~/ 4);
    expect(_opacity(tester), closeTo(1, 0.01));

    await tester.pump(AppMotion.breathe);
    expect(_inFlash(FadeTransition), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
