// RotatingLine: it rests on a timer (no frames between swaps), stands still
// when it should, shows news first, keeps its place when the list only
// re-orders, and stays out of the semantics tree.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/motion/rotating_line.dart';

RotatingLineItem _item(String id) =>
    RotatingLineItem(id: id, child: Text('fact $id'));

Widget _host(
  List<String> ids, {
  bool paused = false,
  bool reduced = false,
  bool tickers = true,
}) => _hostItems(
  [for (final id in ids) _item(id)],
  paused: paused,
  reduced: reduced,
  tickers: tickers,
);

Widget _hostItems(
  List<RotatingLineItem> items, {
  bool paused = false,
  bool reduced = false,
  bool tickers = true,
}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
      child: Scaffold(
        body: TickerMode(
          enabled: tickers,
          child: Center(
            child: RotatingLine(paused: paused, items: items),
          ),
        ),
      ),
    ),
  ),
);

/// A swap's flip, plus the frame after it in which the old item is dropped
/// (an animation reports done on the first frame past its duration).
Future<void> _land(WidgetTester tester) async {
  await tester.pump(AppMotion.flip);
  await tester.pump(_frame);
}

const Duration _frame = Duration(milliseconds: 16);

RotatingLineState _state(WidgetTester tester) =>
    tester.state<RotatingLineState>(find.byType(RotatingLine));

void main() {
  testWidgets('CT-T1 rests without frames, swaps every dwell', (tester) async {
    await tester.pumpWidget(_host(['a', 'b']));
    await tester.pumpAndSettle();

    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(_state(tester).debugResting, isTrue);
    expect(find.text('fact a'), findsOneWidget);

    await tester.pump(AppMotion.carousel);
    expect(tester.binding.hasScheduledFrame, isTrue);

    await _land(tester);
    expect(find.text('fact b'), findsOneWidget);
    expect(find.text('fact a'), findsNothing);

    // The next item rests a full dwell once it has landed, again frameless.
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(_state(tester).debugResting, isTrue);
  });

  group('CT-T3 stands still', () {
    Future<void> expectStill(WidgetTester tester, Widget host) async {
      await tester.pumpWidget(host);
      await tester.pump(const Duration(seconds: 10));

      expect(find.text('fact a'), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(_state(tester).debugResting, isFalse);
    }

    testWidgets('with one item', (tester) => expectStill(tester, _host(['a'])));

    testWidgets(
      'while paused',
      (tester) => expectStill(tester, _host(['a', 'b'], paused: true)),
    );

    testWidgets(
      'under reduced motion',
      (tester) => expectStill(tester, _host(['a', 'b'], reduced: true)),
    );

    testWidgets(
      'with TickerMode off',
      (tester) => expectStill(tester, _host(['a', 'b'], tickers: false)),
    );

    testWidgets('and starts again when unpaused', (tester) async {
      await tester.pumpWidget(_host(['a', 'b'], paused: true));
      expect(_state(tester).debugResting, isFalse);

      await tester.pumpWidget(_host(['a', 'b']));
      expect(_state(tester).debugResting, isTrue);
      await tester.pump(AppMotion.carousel);
      await tester.pump(AppMotion.flip);
      expect(find.text('fact b'), findsOneWidget);
    });
  });

  testWidgets('CT-T4 a new id is shown next at once and the dwell '
      'restarts', (tester) async {
    await tester.pumpWidget(_host(['a', 'b']));
    await tester.pump(AppMotion.carousel ~/ 2);
    expect(find.text('fact a'), findsOneWidget);

    await tester.pumpWidget(_host(['a', 'b', 'v']));
    await _land(tester);
    expect(find.text('fact v'), findsOneWidget);
    expect(find.text('fact a'), findsNothing);

    // v rests a full dwell from when it landed (the old schedule is gone).
    const justBefore = Duration(milliseconds: 1);
    await tester.pump(AppMotion.carousel - _frame - justBefore);
    expect(find.text('fact v'), findsOneWidget);
    expect(find.text('fact a'), findsNothing);
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pump(justBefore * 2);
    expect(find.text('fact a'), findsOneWidget); // the next swap started
  });

  testWidgets('CT-T5 items that only re-order keep the current one', (
    tester,
  ) async {
    await tester.pumpWidget(_host(['a', 'b']));
    await tester.pump(AppMotion.carousel);
    await _land(tester);
    expect(find.text('fact b'), findsOneWidget);
    expect(find.text('fact a'), findsNothing);

    await tester.pumpWidget(_host(['b', 'a']));
    await tester.pump();
    expect(find.text('fact b'), findsOneWidget);
    expect(find.text('fact a'), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('a shown item that goes away falls back to the first', (
    tester,
  ) async {
    await tester.pumpWidget(_host(['a', 'b']));
    await tester.pump(AppMotion.carousel);
    await tester.pump(AppMotion.flip);
    expect(find.text('fact b'), findsOneWidget);

    await tester.pumpWidget(_host(['a']));
    await tester.pumpAndSettle();
    expect(find.text('fact a'), findsOneWidget);
    expect(_state(tester).debugResting, isFalse);
  });

  group('frozen while paused (a re-price)', () {
    RotatingLineItem saving(String amount) =>
        RotatingLineItem(id: 's', child: Text('saving $amount'));

    testWidgets('an item that leaves for the pause stays on screen and comes '
        'back in place, updated, without a swap', (tester) async {
      await tester.pumpWidget(_hostItems([saving('1'), _item('c')]));
      await tester.pumpAndSettle();
      expect(find.text('saving 1'), findsOneWidget);

      // Pending: the saving is hidden while the cart re-prices.
      await tester.pumpWidget(_hostItems([_item('c')], paused: true));
      await tester.pump();
      expect(find.text('saving 1'), findsOneWidget);
      expect(find.text('fact c'), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);

      // The reply: the saving is back with its new amount — not news.
      await tester.pumpWidget(_hostItems([saving('2'), _item('c')]));
      await tester.pump();
      expect(find.text('saving 2'), findsOneWidget);
      expect(find.text('saving 1'), findsNothing);
      expect(find.text('fact c'), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
      expect(_state(tester).debugResting, isTrue);
    });

    testWidgets('the only item is held through an empty list', (tester) async {
      await tester.pumpWidget(_hostItems([saving('1')]));
      await tester.pumpWidget(_hostItems(const [], paused: true));
      await tester.pump();
      expect(find.text('saving 1'), findsOneWidget);

      await tester.pumpWidget(_hostItems([saving('2')]));
      await tester.pump();
      expect(find.text('saving 2'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('an item that is still listed updates in place', (
      tester,
    ) async {
      await tester.pumpWidget(_hostItems([saving('1'), _item('c')]));
      await tester.pumpWidget(
        _hostItems([saving('2'), _item('c')], paused: true),
      );
      await tester.pump();
      expect(find.text('saving 2'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('real news that lands with the reply still goes first', (
      tester,
    ) async {
      await tester.pumpWidget(_hostItems([saving('1'), _item('c')]));
      await tester.pumpWidget(_hostItems([_item('c')], paused: true));
      await tester.pumpWidget(
        _hostItems([saving('2'), _item('c'), _item('free')]),
      );
      await _land(tester);
      expect(find.text('fact free'), findsOneWidget);
      expect(find.text('saving 2'), findsNothing);
    });
  });

  testWidgets('CT-T6 the line is out of the semantics tree', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_host(['a', 'b']));

    expect(find.text('fact a'), findsOneWidget);
    expect(find.bySemanticsLabel('fact a'), findsNothing);
    semantics.dispose();
  });

  testWidgets('tearing it down cancels the rest', (tester) async {
    await tester.pumpWidget(_host(['a', 'b']));
    expect(_state(tester).debugResting, isTrue);

    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
