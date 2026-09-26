// How the home tab moves: blocks come in as they are first seen and their
// cards follow in turn, looping touches rest off screen, the banners hold
// under a finger, the search hint suggests things to look for, the bell
// swings for news and the countdown rolls only what changed — and under
// reduced motion none of it runs.
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/motion/flip_value.dart';
import 'package:jameia_mart/src/core/motion/motion.dart';
import 'package:jameia_mart/src/features/home/domain/entities/home_icon.dart';
import 'package:jameia_mart/src/features/home/domain/entities/home_slide_entity.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_bell_ring.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_carousel_page.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_countdown_text.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_icon_view.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_loop.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_notifications_bell.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_reveal.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_reveal_item.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_reveal_scope.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_search_hint.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_section_header.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_slides_carousel.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Room above and below a block, to put it below the fold of the 600-high
/// test screen and to scroll past it.
const double _fold = 1000;

const List<HomeSlideEntity> _slides = [
  HomeSlideEntity(id: 's1', imageUrl: ''),
  HomeSlideEntity(id: 's2', imageUrl: ''),
  HomeSlideEntity(id: 's3', imageUrl: ''),
];

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
    ui.TextDirection direction = ui.TextDirection.ltr,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: reducedMotion),
          child: Directionality(
            textDirection: direction,
            child: Scaffold(body: child),
          ),
        ),
      ),
    ),
  );

  /// The block's own fade: the first one under [of].
  double opacityUnder(WidgetTester tester, Finder of) => tester
      .widget<FadeTransition>(
        find.descendant(of: of, matching: find.byType(FadeTransition)).first,
      )
      .opacity
      .value;

  group('HomeReveal', () {
    testWidgets('a block below the fold waits, then comes in when reached', (
      tester,
    ) async {
      final page = ScrollController();
      addTearDown(page.dispose);
      await pumpApp(
        tester,
        SingleChildScrollView(
          controller: page,
          child: const Column(
            children: [
              SizedBox(height: _fold),
              HomeReveal(child: SizedBox(height: 200, child: Text('Late'))),
              SizedBox(height: _fold),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      final block = find.byType(HomeReveal);
      expect(opacityUnder(tester, block), 0, reason: 'not seen yet');

      page.jumpTo(_fold - 300);
      await tester.pump();
      await tester.pump();
      await tester.pump(AppMotion.drawOn);
      expect(opacityUnder(tester, block), 1);
    });

    testWidgets('the blocks on screen at launch come in one after another', (
      tester,
    ) async {
      await pumpApp(
        tester,
        SingleChildScrollView(
          child: Column(
            children: [
              const HomeReveal(child: SizedBox(height: 100)),
              const HomeReveal(order: 2, child: SizedBox(height: 100)),
              const SizedBox(height: _fold),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final first = opacityUnder(tester, find.byType(HomeReveal).at(0));
      final third = opacityUnder(tester, find.byType(HomeReveal).at(1));
      expect(first, greaterThan(0));
      expect(third, lessThan(first), reason: 'its turn comes two beats later');

      // Its beat comes; its clock starts on the next frame and runs out.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(AppMotion.drawOn);
      expect(opacityUnder(tester, find.byType(HomeReveal).at(1)), 1);
    });

    testWidgets('the block tells its pieces whether it is on screen', (
      tester,
    ) async {
      final page = ScrollController();
      addTearDown(page.dispose);
      final seen = <bool>[];
      await pumpApp(
        tester,
        SingleChildScrollView(
          controller: page,
          child: Column(
            children: [
              HomeReveal(
                child: Builder(
                  builder: (context) {
                    seen.add(HomeRevealScope.onScreenOf(context));
                    return const SizedBox(height: 100);
                  },
                ),
              ),
              const SizedBox(height: _fold),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(seen.last, isTrue);

      page.jumpTo(_fold);
      await tester.pump();
      await tester.pump();
      expect(seen.last, isFalse);

      page.jumpTo(0);
      await tester.pump();
      await tester.pump();
      expect(seen.last, isTrue);
    });

    testWidgets('with reduced motion a block is simply there', (tester) async {
      await pumpApp(
        tester,
        const HomeReveal(child: Text('Block')),
        reducedMotion: true,
      );
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(HomeReveal),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  testWidgets('the first cards come in in turn; later ones simply show', (
    tester,
  ) async {
    await pumpApp(
      tester,
      HomeReveal(
        child: Row(
          children: [
            for (var i = 0; i <= HomeRevealItem.maxAnimated; i++)
              HomeRevealItem(
                index: i,
                child: SizedBox(width: 40, height: 40, child: Text('$i')),
              ),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final items = find.byType(HomeRevealItem);
    expect(
      opacityUnder(tester, items.at(0)),
      greaterThan(opacityUnder(tester, items.at(3))),
    );
    expect(
      find.descendant(
        of: items.at(HomeRevealItem.maxAnimated),
        matching: find.byType(FadeTransition),
      ),
      findsNothing,
    );
  });

  group('HomeLoop', () {
    Widget loop(List<double> seen, {required bool onScreen}) => HomeRevealScope(
      reveal: kAlwaysCompleteAnimation,
      onScreen: onScreen,
      child: HomeLoop(
        period: AppMotion.floatLoop,
        builder: (context, t, child) {
          seen.add(t);
          return child;
        },
        child: const SizedBox(),
      ),
    );

    testWidgets('runs while its block is on screen, rests off it', (
      tester,
    ) async {
      final seen = <double>[];
      await pumpApp(tester, loop(seen, onScreen: true));
      await tester.pump(const Duration(milliseconds: 500));
      expect(seen.last, greaterThan(0));

      await pumpApp(tester, loop(seen, onScreen: false));
      final parked = seen.last;
      await tester.pump(const Duration(seconds: 2));
      expect(seen.last, parked);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('holds its resting pose under reduced motion', (tester) async {
      final seen = <double>[];
      await pumpApp(tester, loop(seen, onScreen: true), reducedMotion: true);
      await tester.pump(const Duration(seconds: 2));
      expect(seen.toSet(), {0.0});
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('HomeSlidesCarousel', () {
    PageController controllerOf(WidgetTester tester) =>
        tester.widget<PageView>(find.byType(PageView)).controller!;

    testWidgets('a finger holds the banners; letting go starts a full dwell', (
      tester,
    ) async {
      await pumpApp(tester, const HomeSlidesCarousel(slides: _slides));
      await tester.pump(AppMotion.carousel);
      await tester.pump(AppMotion.slow);
      expect(controllerOf(tester).page, 1, reason: 'advanced by itself');

      final finger = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await tester.pump(AppMotion.carousel * 2);
      expect(controllerOf(tester).page, 1, reason: 'held under the finger');

      await finger.up();
      await tester.pump(AppMotion.carousel ~/ 2);
      expect(controllerOf(tester).page, 1, reason: 'a full dwell first');

      await tester.pump(AppMotion.carousel);
      await tester.pump(AppMotion.slow);
      expect(controllerOf(tester).page, 2);
    });

    testWidgets('off screen the banners hold still', (tester) async {
      await pumpApp(
        tester,
        const HomeRevealScope(
          reveal: kAlwaysCompleteAnimation,
          onScreen: false,
          child: HomeSlidesCarousel(slides: _slides),
        ),
      );
      await tester.pump(AppMotion.carousel * 3);
      expect(controllerOf(tester).page, 0);
    });

    testWidgets('the banner beside the middle one sits a step back', (
      tester,
    ) async {
      await pumpApp(tester, const HomeSlidesCarousel(slides: _slides));
      final controller = controllerOf(tester);
      expect(HomeCarouselPage.offsetOf(controller, 0), 0);
      expect(HomeCarouselPage.offsetOf(controller, 1), -1);

      double scaleOf(int index) => tester
          .widget<Transform>(
            find
                .descendant(
                  of: find.byType(HomeCarouselPage).at(index),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .entry(0, 0);
      expect(scaleOf(0), 1);
      expect(scaleOf(1), lessThan(1));
    });
  });

  group('HomeSearchHint', () {
    const style = TextStyle();

    testWidgets('suggests things to look for, one after another', (
      tester,
    ) async {
      await pumpApp(tester, const HomeSearchHint(style: style));
      expect(find.text('Search products'), findsOneWidget);

      await tester.pump(AppMotion.carousel);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Search for "milk"'), findsOneWidget);
      expect(find.text('Search products'), findsNothing);

      await tester.pump(AppMotion.carousel - const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Search for "bread"'), findsOneWidget);
    });

    testWidgets('types each suggestion in, letter by letter', (tester) async {
      await pumpApp(tester, const HomeSearchHint(style: style));
      await tester.pump(AppMotion.carousel);
      expect(find.text('Search for "|"'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 170));
      expect(find.text('Search for "mi|"'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Search for "milk"'), findsOneWidget, reason: 'done');
      await tester.pumpAndSettle();
    });

    testWidgets('stays on the plain hint under reduced motion', (tester) async {
      await pumpApp(
        tester,
        const HomeSearchHint(style: style),
        reducedMotion: true,
      );
      await tester.pump(AppMotion.carousel * 3);
      expect(find.text('Search products'), findsOneWidget);
    });
  });

  group('the bell', () {
    Matrix4 swingOf(WidgetTester tester) => tester
        .widget<Transform>(
          find
              .descendant(
                of: find.byType(HomeBellRing),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform;

    testWidgets('swings when something new comes in, then settles', (
      tester,
    ) async {
      await pumpApp(
        tester,
        HomeNotificationsBell(hasUnread: false, onTap: () {}),
      );
      expect(swingOf(tester).isIdentity(), isTrue);

      await pumpApp(
        tester,
        HomeNotificationsBell(hasUnread: true, onTap: () {}),
      );
      await tester.pump(const Duration(milliseconds: 60));
      expect(swingOf(tester).isIdentity(), isFalse);

      await tester.pump(AppMotion.drawOn);
      expect(swingOf(tester).isIdentity(), isTrue);
    });

    testWidgets('stays still under reduced motion', (tester) async {
      await pumpApp(
        tester,
        HomeNotificationsBell(hasUnread: true, onTap: () {}),
        reducedMotion: true,
      );
      await tester.pump(const Duration(milliseconds: 60));
      expect(swingOf(tester).isIdentity(), isTrue);
    });
  });

  group('HomeCountdownText', () {
    const style = TextStyle();
    final endsAt = DateTime.now().add(
      const Duration(hours: 1, minutes: 2, seconds: 30),
    );

    testWidgets('only the part that changed rolls', (tester) async {
      await pumpApp(tester, HomeCountdownText(endsAt: endsAt, style: style));
      expect(find.byType(FlipValue), findsNWidgets(3));

      await pumpApp(
        tester,
        HomeCountdownText(
          endsAt: endsAt.subtract(const Duration(seconds: 1)),
          style: style,
        ),
      );
      await tester.pump(AppMotion.flip ~/ 2);
      int textsIn(int part) => find
          .descendant(
            of: find.byType(FlipValue).at(part),
            matching: find.byType(Text),
          )
          .evaluate()
          .length;
      expect(textsIn(0), 1, reason: 'the hours stay put');
      expect(textsIn(2), 2, reason: 'the seconds roll: old and new');
    });

    testWidgets('reads left to right in Arabic too', (tester) async {
      await pumpApp(
        tester,
        HomeCountdownText(endsAt: endsAt, style: style),
        direction: ui.TextDirection.rtl,
      );
      final hours = tester.getTopLeft(find.byType(FlipValue).at(0)).dx;
      final seconds = tester.getTopLeft(find.byType(FlipValue).at(2)).dx;
      expect(hours, lessThan(seconds));
    });
  });

  testWidgets('a section header pops its icon in with its block', (
    tester,
  ) async {
    final clock = AnimationController(vsync: const TestVSync());
    addTearDown(clock.dispose);
    await pumpApp(
      tester,
      HomeRevealScope(
        reveal: clock,
        onScreen: true,
        child: HomeSectionHeader(
          title: "Today's deals",
          icon: const HomeIcon(key: HomeIconKey.zap),
          onSeeAll: () {},
        ),
      ),
    );
    double iconScale() => tester
        .widget<ScaleTransition>(
          find
              .ancestor(
                of: find.byType(HomeIconView),
                matching: find.byType(ScaleTransition),
              )
              .first,
        )
        .scale
        .value;
    expect(iconScale(), lessThan(1));

    clock.value = 1;
    await tester.pump();
    expect(iconScale(), 1);
  });
}
