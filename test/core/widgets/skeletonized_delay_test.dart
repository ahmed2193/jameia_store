// I15a — the skeleton's shimmer starts after `loaderDelay` (docs/motion
// §9.4 #6): a read that answers sooner shows still bones, never a flash of
// shimmer; reduced motion keeps the bones still.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/widgets/skeletonized.dart';
import 'package:skeletonizer/skeletonizer.dart';

void main() {
  Widget app({bool reduced = false}) => MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: const Scaffold(
          body: Skeletonized(loading: true, child: Text('bone')),
        ),
      ),
    ),
  );

  PaintingEffect effect(WidgetTester tester) => tester
      .widget<Skeletonizer>(
        find.byWidgetPredicate((widget) => widget is Skeletonizer),
      )
      .effect!;

  testWidgets('still bones first, the shimmer after loaderDelay', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    expect(effect(tester), isA<SolidColorEffect>());
    await tester.pump(AppMotion.loaderDelay);
    expect(effect(tester), isA<ShimmerEffect>());
  });

  testWidgets('reduced motion: the bones stay still', (tester) async {
    await tester.pumpWidget(app(reduced: true));
    await tester.pump(AppMotion.loaderDelay);
    expect(effect(tester), isA<SolidColorEffect>());
  });
}
