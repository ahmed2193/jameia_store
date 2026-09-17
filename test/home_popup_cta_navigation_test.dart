// Regression test: home popup CTA navigation after the Navigator -> GoRouter
// migration.
//
// Legacy flow (root Navigator + onGenerateRoute): the popup CTA ran
// `Navigator.maybePop()` then `Navigator.pushNamed(Routes.shop)`. `maybePop`
// is async and skips the pop when the top route changed meanwhile; the
// synchronous `pushNamed` changed it, so the popup stayed UNDER the shop page
// and the popup queue stayed paused until the user came back to Home and
// closed that popup.
//
// Under GoRouter a push only reaches the Navigator on the next frame, so the
// same code really closed the dialog; `showHomePopups` then resumed and, 300ms
// later, drew the NEXT home popup on the root navigator ON TOP of the shop.
//
// This pins the legacy behavior with the bundled catalogue (p_coupon ->
// p_image, both scheme 's1').

import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jameia_mart/src/config/di/service_locator.dart';
import 'package:jameia_mart/src/config/routes/routes.dart';
import 'package:jameia_mart/src/config/theme/app_theme.dart';
import 'package:jameia_mart/src/core/navigation/navigation.dart';
import 'package:jameia_mart/src/features/home/presentation/cubit/home_cubit.dart';
import 'package:jameia_mart/src/features/home/presentation/popups/home_popup_host.dart';

const Key _homeKey = Key('popup-test-home');
const Key _shopKey = Key('popup-test-shop');

// Seeded catalogue texts (English).
const String _firstCta = 'Claim now'; // p_coupon ctaTextEn
// p_image is an imageText popup: it renders its image + CTA pill only.
const String _secondCta = 'Shop now'; // p_image ctaTextEn

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await setupServiceLocator();
    final enRaw = await rootBundle.loadString('assets/i18n/en.json');
    Localization.load(
      const Locale('en'),
      translations: Translations(json.decode(enRaw) as Map<String, dynamic>),
    );
  });

  Future<void> settle(WidgetTester tester, {int frames = 8}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  bool isCurrent(WidgetTester tester, Key key) => ModalRoute.of(
    tester.element(find.byKey(key, skipOffstage: false)),
  )!.isCurrent;

  testWidgets(
    'popup CTA opens the shop over the still-open popup and pauses the queue',
    (tester) async {
      // Real home feed popups (via the real HomeCubit) — no entity import, so
      // the test follows whatever entity type the host consumes.
      final popups = (await tester.runAsync(() async {
        final cubit = sl<HomeCubit>();
        final loaded = cubit.state.popups.isNotEmpty
            ? cubit.state
            : await cubit.stream
                  .firstWhere((s) => s.popups.isNotEmpty)
                  .timeout(const Duration(seconds: 10));
        await cubit.close();
        return loaded.popups;
      }))!;
      expect(popups.length, greaterThanOrEqualTo(2));
      expect(popups.first.scheme, isNotEmpty);

      final router = GoRouter(
        navigatorKey: GlobalKey<NavigatorState>(),
        initialLocation: Routes.home,
        routes: <RouteBase>[
          GoRoute(
            path: Routes.home,
            pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
              key: state.pageKey,
              name: state.uri.path,
              child: const Scaffold(key: _homeKey, body: Text('home')),
            ),
          ),
          GoRoute(
            path: Routes.shop,
            pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
              key: state.pageKey,
              name: state.uri.path,
              child: Scaffold(key: _shopKey, body: Text('shop ${state.extra}')),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ar')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          saveLocale: false,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await settle(tester);

      unawaited(showHomePopups(tester.element(find.byKey(_homeKey)), popups));
      await settle(tester);
      expect(find.text(_firstCta), findsOneWidget);

      // Tap the CTA, then wait well past the queue's 300ms settle delay and the
      // popup / page transitions.
      await tester.tap(find.text(_firstCta));
      await settle(tester, frames: 15);

      expect(router.state.uri.path, Routes.shop);
      expect(find.text('shop ${popups.first.scheme}'), findsOneWidget);
      // The next home popup must NOT be drawn over the shop page.
      expect(find.text(_secondCta, skipOffstage: false), findsNothing);
      expect(isCurrent(tester, _shopKey), isTrue);
      // Legacy: the first popup is still open, underneath the shop.
      expect(find.text(_firstCta, skipOffstage: false), findsOneWidget);

      // Back from the shop -> the first popup is on screen over Home again.
      router.pop();
      await settle(tester);
      expect(router.state.uri.path, Routes.home);
      expect(find.text(_firstCta), findsOneWidget);
      expect(find.text(_secondCta, skipOffstage: false), findsNothing);

      // Closing it resumes the queue: the next popup appears over Home.
      await Navigator.of(tester.element(find.text(_firstCta))).maybePop();
      await settle(tester, frames: 15);
      expect(find.text(_firstCta), findsNothing);
      expect(find.text(_secondCta), findsOneWidget);
      expect(router.state.uri.path, Routes.home);
      expect(isCurrent(tester, _homeKey), isFalse); // popup #2 on top of Home

      // Close the last popup so the queue completes, then unmount.
      await Navigator.of(tester.element(find.text(_secondCta))).maybePop();
      await settle(tester);
      expect(isCurrent(tester, _homeKey), isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    },
  );
}
