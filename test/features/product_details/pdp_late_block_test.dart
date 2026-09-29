// I15a — a product-page block that lands after the page first showed opens
// its room (height + fade) instead of popping in; one that was there is
// simply there; reduced motion shows it at once.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_late_block.dart';

void main() {
  const Key block = ValueKey<String>('block');

  Widget host({required bool late, bool reduced = false}) => MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: Scaffold(
          body: Column(
            children: [
              PdpLateBlock(
                late: late,
                child: const SizedBox(key: block, height: 100),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  double heightOf(WidgetTester tester) =>
      tester.getSize(find.byType(PdpLateBlock)).height;

  testWidgets('a block that was there is simply there', (tester) async {
    await tester.pumpWidget(host(late: false));
    expect(heightOf(tester), 100);
    await tester.pump(AppMotion.medium);
    expect(heightOf(tester), 100, reason: 'no reveal runs');
  });

  testWidgets('a late block opens its room', (tester) async {
    await tester.pumpWidget(host(late: true));
    expect(heightOf(tester), 0, reason: 'mounted closed');
    await tester.pump();
    await tester.pump(AppMotion.medium ~/ 2);
    expect(heightOf(tester), inExclusiveRange(0, 100));
    await tester.pumpAndSettle();
    expect(heightOf(tester), 100);
  });

  testWidgets('reduced motion: a late block is simply there', (tester) async {
    await tester.pumpWidget(host(late: true, reduced: true));
    expect(heightOf(tester), 100);
    await tester.pumpAndSettle();
    expect(heightOf(tester), 100);
  });
}
