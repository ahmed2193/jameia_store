// How the home tab answers the finger: cards sink a touch under it and let go
// once it drags, an add tap sends up a "+1", and a swiped banner clicks softly
// as it arrives. (The way back to the top: test/core/widgets/.)
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/features/home/domain/entities/home_slide_entity.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_add_burst.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_pressable.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_slides_carousel.dart';
import 'package:shared_preferences/shared_preferences.dart';

const double _card = 120;

/// A card that takes touches, like a real one.
class _Card extends StatelessWidget {
  const _Card();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Colors.white,
    child: SizedBox.square(dimension: _card),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final enRaw = await rootBundle.loadString('assets/i18n/en.json');
    Localization.load(
      const Locale('en'),
      translations: Translations(json.decode(enRaw) as Map<String, dynamic>),
    );
  });

  Future<void> pumpApp(
    WidgetTester tester,
    Widget child, {
    bool reducedMotion = false,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: reducedMotion),
          child: Scaffold(body: child),
        ),
      ),
    ),
  );

  group('HomePressable', () {
    double scaleOf(WidgetTester tester) =>
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

    testWidgets('sinks under the finger and comes back up on release', (
      tester,
    ) async {
      await pumpApp(tester, const Center(child: HomePressable(child: _Card())));
      final finger = await tester.startGesture(
        tester.getCenter(find.byType(HomePressable)),
      );
      await tester.pump();
      expect(scaleOf(tester), lessThan(1));

      await finger.up();
      await tester.pump();
      expect(scaleOf(tester), 1);
    });

    testWidgets('lets go as soon as the finger starts to drag', (tester) async {
      await pumpApp(tester, const Center(child: HomePressable(child: _Card())));
      final finger = await tester.startGesture(
        tester.getCenter(find.byType(HomePressable)),
      );
      await tester.pump();
      expect(scaleOf(tester), lessThan(1));
      await finger.moveBy(const Offset(kTouchSlop * 2, 0));
      await tester.pump();
      expect(scaleOf(tester), 1, reason: 'a drag is not a press');
      await finger.up();
    });
  });

  group('HomeAddBurst', () {
    double plusOneOpacity(WidgetTester tester) => tester
        .widget<FadeTransition>(
          find
              .ancestor(
                of: find.text('+1'),
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;

    Widget burst(ValueNotifier<int> adds) => Center(
      child: HomeAddBurst(
        trigger: adds,
        width: _card,
        child: const SizedBox(width: _card, height: _card * 2),
      ),
    );

    testWidgets('an add tap sends up a "+1" that fades away', (tester) async {
      final adds = ValueNotifier<int>(0);
      addTearDown(adds.dispose);
      await pumpApp(tester, burst(adds));
      expect(plusOneOpacity(tester), 0, reason: 'nothing before an add');

      adds.value++;
      await tester.pump();
      await tester.pump(AppMotion.drawOn ~/ 3);
      expect(plusOneOpacity(tester), greaterThan(0));

      await tester.pump(AppMotion.drawOn);
      expect(plusOneOpacity(tester), 0);
    });

    testWidgets('stays hidden under reduced motion', (tester) async {
      final adds = ValueNotifier<int>(0);
      addTearDown(adds.dispose);
      await pumpApp(tester, burst(adds), reducedMotion: true);
      adds.value++;
      await tester.pump();
      await tester.pump(AppMotion.drawOn ~/ 3);
      expect(plusOneOpacity(tester), 0);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  testWidgets('a banner carried in by the finger clicks softly', (
    tester,
  ) async {
    final haptics = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpApp(
      tester,
      const HomeSlidesCarousel(
        slides: [
          HomeSlideEntity(id: 's1', imageUrl: ''),
          HomeSlideEntity(id: 's2', imageUrl: ''),
        ],
      ),
    );

    final finger = await tester.startGesture(
      tester.getCenter(find.byType(PageView)),
    );
    for (var step = 0; step < 10; step++) {
      await finger.moveBy(const Offset(-50, 0));
      await tester.pump();
    }
    expect(haptics, contains('HapticFeedbackType.selectionClick'));
    await finger.up();
    await tester.pumpAndSettle();
  });
}
