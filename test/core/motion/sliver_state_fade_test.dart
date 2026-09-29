// I15a — a listing's state swaps after its first arrival fade in instead of
// snapping (App A §45): a new sort brings the bones back, then the new
// cards, each over `fast`; the first arrival is the cascade's; reduced
// motion swaps at once.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/motion/sliver_state_fade.dart';

void main() {
  Widget app(String state, {bool reduced = false}) => MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverStateFade(
                stateKey: state,
                arrived: state != 'bones',
                sliver: SliverToBoxAdapter(child: Text(state)),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  double opacity(WidgetTester tester) => tester
      .widget<SliverFadeTransition>(find.byType(SliverFadeTransition))
      .opacity
      .value;

  testWidgets('the first arrival is not faded; later swaps fade in fast', (
    tester,
  ) async {
    await tester.pumpWidget(app('bones'));
    await tester.pumpWidget(app('cards'));
    await tester.pump();
    expect(opacity(tester), 1, reason: 'the cascade plays the first arrival');
    expect(tester.binding.hasScheduledFrame, isFalse);

    // A new sort: the bones come back, faded in.
    await tester.pumpWidget(app('bones'));
    await tester.pump(AppMotion.fast ~/ 2);
    expect(find.text('bones'), findsOneWidget);
    expect(opacity(tester), inExclusiveRange(0, 1));
    await tester.pump(AppMotion.fast);
    expect(opacity(tester), 1);

    // …then the new cards, faded in too.
    await tester.pumpWidget(app('sorted'));
    await tester.pump(AppMotion.fast ~/ 2);
    expect(opacity(tester), inExclusiveRange(0, 1));
    await tester.pump(AppMotion.fast);
    expect(opacity(tester), 1);
  });

  testWidgets('reduced motion: every swap is instant', (tester) async {
    await tester.pumpWidget(app('cards', reduced: true));
    await tester.pumpWidget(app('bones', reduced: true));
    await tester.pump();
    expect(opacity(tester), 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
