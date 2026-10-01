// The first-order welcome gift popup: the GIF of the current language (the
// text is baked in), the held last frame under reduced motion, the whole
// card is "Order now", the ring under it closes; in the popup queue the gift
// comes first, "Order now" ends the queue and a close moves on to the
// marketing popups.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/core/design/hero_assets.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_popup_close_ring.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_popup_queue.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_welcome_gift_art.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_welcome_popup_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_test_fakes.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Future<void> frames(WidgetTester tester, [int count = 10]) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Widget localized({required Locale locale, required Widget child}) =>
      EasyLocalization(
        supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: locale,
        saveLocale: false,
        child: child,
      );

  Future<void> pumpView(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    bool reducedMotion = false,
    VoidCallback? onOrderNow,
    VoidCallback? onClose,
  }) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        localized(
          locale: locale,
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: MediaQuery(
                data: MediaQueryData(disableAnimations: reducedMotion),
                child: Scaffold(
                  body: HomeWelcomePopupView(
                    onOrderNow: onOrderNow ?? () {},
                    onClose: onClose ?? () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      // Lets the translation asset load for real.
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await frames(tester);
  }

  String shownAsset(WidgetTester tester) {
    final image = tester.widget<Image>(
      find.descendant(
        of: find.byType(HomeWelcomeGiftArt),
        matching: find.byType(Image),
      ),
    );
    return (image.image as AssetImage).assetName;
  }

  group('HomeWelcomePopupView', () {
    testWidgets('English: the English GIF, labelled as one button', (
      tester,
    ) async {
      await pumpView(tester);

      expect(shownAsset(tester), HeroAssets.popupFirstOrderFreeDeliveryEn);
      expect(
        find.bySemanticsLabel(
          'Welcome gift: free delivery on your first order. Order now',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Close'), findsOneWidget);
    });

    testWidgets('Arabic: the Arabic GIF', (tester) async {
      await pumpView(tester, locale: const Locale('ar'));

      expect(shownAsset(tester), HeroAssets.popupFirstOrderFreeDeliveryAr);
    });

    testWidgets('reduced motion: the held last frame, no animation', (
      tester,
    ) async {
      await pumpView(tester, reducedMotion: true);

      expect(shownAsset(tester), HeroAssets.popupFirstOrderFreeDeliveryEnStill);
    });

    testWidgets('the card orders, the ring closes', (tester) async {
      var ordered = 0;
      var closed = 0;
      await pumpView(
        tester,
        onOrderNow: () => ordered++,
        onClose: () => closed++,
      );

      await tester.tap(find.byType(HomeWelcomeGiftArt));
      await frames(tester, 3);
      await tester.tap(find.byType(HomePopupCloseRing));
      await frames(tester, 3);

      expect(ordered, 1);
      expect(closed, 1);
    });

    testWidgets('the art keeps its 640 × 844 shape, capped at 320 wide', (
      tester,
    ) async {
      await pumpView(tester);

      final size = tester.getSize(find.byType(HomeWelcomeGiftArt));
      expect(size.width, 320);
      expect(size.width / size.height, closeTo(640 / 844, 0.01));
    });

    testWidgets('a short (landscape) screen shrinks the card, no overflow', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 360)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpView(tester);

      final art = tester.getSize(find.byType(HomeWelcomeGiftArt));
      expect(tester.takeException(), isNull);
      expect(art.height, lessThan(360));
      expect(art.width / art.height, closeTo(640 / 844, 0.01));
      expect(find.byType(HomePopupCloseRing), findsOneWidget);
    });
  });

  group('HomePopupQueue', () {
    Future<void> pumpQueue(WidgetTester tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => HomePopupQueue.show(
                    context,
                    welcome: true,
                    popups: const [sessionPopup],
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.runAsync(() async {
        await tester.pumpWidget(
          localized(
            locale: const Locale('en'),
            child: Builder(
              builder: (context) => MaterialApp.router(
                routerConfig: router,
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
              ),
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await frames(tester);
      await tester.tap(find.text('open'));
      await frames(tester);
    }

    testWidgets('the gift opens the queue; a close moves on to the popups', (
      tester,
    ) async {
      await pumpQueue(tester);
      expect(find.byType(HomeWelcomePopupView), findsOneWidget);
      expect(find.text(sessionPopup.title), findsNothing);

      await tester.tap(find.byType(HomePopupCloseRing));
      await frames(tester);

      expect(find.byType(HomeWelcomePopupView), findsNothing);
      expect(find.text(sessionPopup.title), findsOneWidget);
    });

    testWidgets('"Order now" ends the queue: no popup on top of shopping', (
      tester,
    ) async {
      await pumpQueue(tester);

      await tester.tap(find.byType(HomeWelcomeGiftArt));
      await frames(tester);

      expect(find.byType(HomeWelcomePopupView), findsNothing);
      expect(find.text(sessionPopup.title), findsNothing);
    });
  });
}
