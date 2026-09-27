// PopSwitcher: what is there at first build never pops, a new identity pops
// in from its corner (mirrored in RTL) while the old one fades out, and
// reduced motion swaps in one frame.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/motion/pop_switcher.dart';

Widget _host(
  Object key, {
  bool reduced = false,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
      child: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Center(
            child: PopSwitcher(
              stateKey: key,
              alignment: AlignmentDirectional.bottomEnd,
              child: Text('$key'),
            ),
          ),
        ),
      ),
    ),
  ),
);

Finder get _scales => find.descendant(
  of: find.byType(PopSwitcher),
  matching: find.byType(ScaleTransition),
);

ScaleTransition _scaleOf(WidgetTester tester, String text) =>
    tester.widget<ScaleTransition>(
      find.ancestor(
        of: find.text(text),
        matching: find.byType(ScaleTransition),
      ),
    );

void main() {
  testWidgets('CT-P1 the first child is static', (tester) async {
    await tester.pumpWidget(_host('a'));

    for (final scale in tester.widgetList<ScaleTransition>(_scales)) {
      expect(scale.scale.value, 1);
    }
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('CT-P2 a new key pops in from the given corner and the old one '
      'fades out', (tester) async {
    await tester.pumpWidget(_host('a'));
    await tester.pumpWidget(_host('b'));
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    final incoming = _scaleOf(tester, 'b');
    expect(incoming.scale.value, lessThan(1));
    expect(incoming.alignment, Alignment.bottomRight);

    await tester.pumpAndSettle();
    expect(find.text('a'), findsNothing);
    expect(find.text('b'), findsOneWidget);
  });

  testWidgets('CT-P2 the corner mirrors in RTL', (tester) async {
    await tester.pumpWidget(_host('a', direction: TextDirection.rtl));
    await tester.pumpWidget(_host('b', direction: TextDirection.rtl));
    await tester.pump(const Duration(milliseconds: 16));

    final incoming = _scaleOf(tester, 'b');
    expect(incoming.scale.value, lessThan(1));
    expect(incoming.alignment, Alignment.bottomLeft);
    await tester.pumpAndSettle();
  });

  testWidgets('CT-P3 reduced motion swaps in one frame', (tester) async {
    await tester.pumpWidget(_host('a', reduced: true));
    await tester.pumpWidget(_host('b', reduced: true));
    await tester.pump();

    expect(find.text('a'), findsNothing);
    expect(find.text('b'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
