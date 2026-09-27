// ReadyWipe: the pill's fill. Static at mount; turning ready wipes the ready
// colour in from the start edge (the right in RTL) with one light band, then
// rests with no clip and no band; turning not-ready is instant. Reduced
// motion changes the colour at once; a covered page wipes on reveal.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/widgets/light_sweep_band.dart';
import 'package:hero_mart/src/core/widgets/ready_wipe.dart';

const Color _green = Color(0xFF22C55E);
const Color _grey = Color(0xFFEBEBEB);
const BorderRadius _pill = BorderRadius.all(Radius.circular(999));

Widget _host(
  bool ready, {
  bool reduced = false,
  bool tickers = true,
  TextDirection direction = TextDirection.ltr,
}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduced),
  child: Directionality(
    textDirection: direction,
    child: TickerMode(
      enabled: tickers,
      child: Center(
        child: SizedBox(
          width: 200,
          height: 52,
          child: ReadyWipe(
            ready: ready,
            readyColor: _green,
            idleColor: _grey,
            borderRadius: _pill,
            child: const Center(child: _Label()),
          ),
        ),
      ),
    ),
  ),
);

class _Label extends StatefulWidget {
  const _Label();

  @override
  State<_Label> createState() => _LabelState();
}

class _LabelState extends State<_Label> {
  @override
  Widget build(BuildContext context) => const Text('Place order');
}

Finder _inWipe(Type type) =>
    find.descendant(of: find.byType(ReadyWipe), matching: find.byType(type));

Color? _restingColor(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(_inWipe(DecoratedBox).first);
  return (box.decoration as BoxDecoration).color;
}

double _fill(WidgetTester tester) => tester
    .widget<FractionallySizedBox>(_inWipe(FractionallySizedBox))
    .widthFactor!;

void main() {
  testWidgets('mount is a static fill: no clip, no band', (tester) async {
    await tester.pumpWidget(_host(false));
    expect(_restingColor(tester), _grey);
    expect(_inWipe(ClipRRect), findsNothing);
    expect(_inWipe(LightSweepBand), findsNothing);

    await tester.pumpWidget(_host(true));
    await tester.pumpAndSettle();
    await tester.pumpWidget(Container());
    await tester.pumpWidget(_host(true));
    expect(_restingColor(tester), _green);
    expect(_inWipe(ClipRRect), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('turning ready wipes once from the start edge, with one band, '
      'and rests without clip or band', (tester) async {
    await tester.pumpWidget(_host(false));
    final label = tester.element(find.byType(_Label));

    await tester.pumpWidget(_host(true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_fill(tester), inExclusiveRange(0, 1));
    final wipe = tester.getRect(find.byType(ReadyWipe));
    final fill = tester.getRect(
      find.descendant(
        of: _inWipe(FractionallySizedBox),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(fill.left, wipe.left);
    expect(fill.right, lessThan(wipe.right));

    await tester.pump(const Duration(milliseconds: 300));
    expect(_inWipe(LightSweepBand), findsOneWidget);
    expect(identical(tester.element(find.byType(_Label)), label), isTrue);

    await tester.pump(AppMotion.drawOn);
    expect(_inWipe(ClipRRect), findsNothing);
    expect(_inWipe(LightSweepBand), findsNothing);
    expect(_restingColor(tester), _green);
    expect(tester.hasRunningAnimations, isFalse);
    expect(identical(tester.element(find.byType(_Label)), label), isTrue);
  });

  testWidgets('turning not-ready is instant, even mid-wipe', (tester) async {
    await tester.pumpWidget(_host(false));
    await tester.pumpWidget(_host(true));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.pumpWidget(_host(false));
    expect(_restingColor(tester), _grey);
    expect(_inWipe(LightSweepBand), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('RTL wipes from the right', (tester) async {
    await tester.pumpWidget(_host(false, direction: TextDirection.rtl));
    await tester.pumpWidget(_host(true, direction: TextDirection.rtl));
    await tester.pump(const Duration(milliseconds: 100));

    final wipe = tester.getRect(find.byType(ReadyWipe));
    final fill = tester.getRect(
      find.descendant(
        of: _inWipe(FractionallySizedBox),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(fill.right, wipe.right);
    expect(fill.left, greaterThan(wipe.left));
    await tester.pumpAndSettle();
  });

  testWidgets('reduced motion: the colour changes at once', (tester) async {
    await tester.pumpWidget(_host(false, reduced: true));
    await tester.pumpWidget(_host(true, reduced: true));

    expect(_restingColor(tester), _green);
    expect(_inWipe(ClipRRect), findsNothing);
    expect(_inWipe(LightSweepBand), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('covered: stays idle, then wipes in full on reveal', (
    tester,
  ) async {
    await tester.pumpWidget(_host(false, tickers: false));
    await tester.pumpWidget(_host(true, tickers: false));
    await tester.pump(AppMotion.drawOn * 3);
    expect(_restingColor(tester), _grey);
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pumpWidget(_host(true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_fill(tester), inExclusiveRange(0, 1));

    await tester.pump(AppMotion.drawOn);
    expect(_restingColor(tester), _green);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
