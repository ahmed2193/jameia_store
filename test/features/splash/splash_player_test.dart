import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/config/routes/feature_routes/shell_routes.dart';
import 'package:hero_mart/src/config/routes/feature_routes/splash_routes.dart';
import 'package:hero_mart/src/config/routes/route_args/shell_arrival.dart';
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/navigation/navigation.dart';
import 'package:hero_mart/src/features/splash/presentation/pages/splash_page.dart';
import 'package:hero_mart/src/features/splash/presentation/widgets/splash_motion.dart';
import 'package:hero_mart/src/features/splash/presentation/widgets/splash_player.dart';
import 'package:hero_mart/src/features/splash/presentation/widgets/splash_scene_painter.dart';
import 'package:hero_mart/src/features/splash/presentation/widgets/splash_variant.dart';
import 'package:hero_mart/src/features/splash/presentation/widgets/splash_wordmark.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shows the splash inside EasyLocalization (the tagline is translated).
Future<void> _pumpLocalized(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      saveLocale: false,
      child: child,
    ),
  );
  // Translations load asynchronously; the first frame waits for them.
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
}

Future<void> _pumpPlayer(
  WidgetTester tester, {
  required SplashVariant variant,
  required VoidCallback onFinished,
  VoidCallback? onLaunchFrame,
  bool reducedMotion = false,
}) => _pumpLocalized(
  tester,
  MediaQuery(
    data: MediaQueryData(disableAnimations: reducedMotion),
    child: MaterialApp(
      home: Scaffold(
        body: SplashPlayer(
          variant: variant,
          onFinished: onFinished,
          onLaunchFrame: onLaunchFrame,
        ),
      ),
    ),
  ),
);

SystemUiOverlayStyle _statusBar(WidgetTester tester) => tester
    .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>).last,
    )
    .value;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  for (final variant in SplashVariant.values) {
    testWidgets('${variant.name} hands off exactly once, at its end', (
      tester,
    ) async {
      var finished = 0;
      await _pumpPlayer(tester, variant: variant, onFinished: () => finished++);
      final duration = variant.choreography.duration;

      expect(find.byType(SplashPlayer), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint && widget.painter is SplashScenePainter,
        ),
        findsOneWidget,
      );

      // The launch frame holds still first: nothing moves or ends early.
      await tester.pump(SplashPlayer.maxStartDelay);
      expect(finished, 0);
      await tester.pump(duration - AppMotion.fast);
      expect(finished, 0);

      await tester.pump(AppMotion.page);
      expect(finished, 1);

      // The failsafe (twice the run) must not fire a second hand-off.
      await tester.pump(duration * 2);
      expect(finished, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the launch frame holds still until it is on screen', (
    tester,
  ) async {
    await _pumpPlayer(
      tester,
      variant: SplashVariant.wordmark,
      onFinished: () {},
    );
    final painter =
        tester
                .widget<CustomPaint>(
                  find.byWidgetPredicate(
                    (widget) =>
                        widget is CustomPaint &&
                        widget.painter is SplashScenePainter,
                  ),
                )
                .painter!
            as SplashScenePainter;

    await tester.pump(SplashMotion.firstFrameWait);
    expect(painter.clock.value, 0);
    await tester.pump(SplashMotion.handOffHold);
    await tester.pump(AppMotion.page);
    expect(painter.clock.value, greaterThan(0));
  });

  // B1-14: the first screen's data starts loading while the launch frame
  // holds still — overlapping the intro, not following it.
  testWidgets('the launch frame starts the prefetch once, before the intro '
      'moves', (tester) async {
    var prefetches = 0;
    var finished = 0;
    await _pumpPlayer(
      tester,
      variant: SplashVariant.wordmark,
      onFinished: () => finished++,
      onLaunchFrame: () => prefetches++,
    );
    final painter =
        tester
                .widget<CustomPaint>(
                  find.byWidgetPredicate(
                    (widget) =>
                        widget is CustomPaint &&
                        widget.painter is SplashScenePainter,
                  ),
                )
                .painter!
            as SplashScenePainter;

    await tester.pump(SplashMotion.firstFrameWait);
    expect(prefetches, 1);
    expect(painter.clock.value, 0, reason: 'the intro has not moved yet');

    await tester.pump(SplashPlayer.maxStartDelay);
    await tester.pump(SplashVariant.wordmark.choreography.duration);
    await tester.pump(AppMotion.page);
    expect(finished, 1, reason: 'the hand-off is unchanged');
    expect(prefetches, 1);
  });

  testWidgets('reduced motion starts the prefetch at once', (tester) async {
    var prefetches = 0;
    await _pumpPlayer(
      tester,
      variant: SplashVariant.wordmark,
      onFinished: () {},
      onLaunchFrame: () => prefetches++,
      reducedMotion: true,
    );

    expect(prefetches, 1);
    await tester.pump(SplashMotion.reducedHold + AppMotion.page);
    expect(prefetches, 1);
  });

  testWidgets('reduced motion shows the lockup, then hands off after a hold', (
    tester,
  ) async {
    var finished = 0;
    await _pumpPlayer(
      tester,
      variant: SplashVariant.wordmark,
      onFinished: () => finished++,
      reducedMotion: true,
    );

    final painter =
        tester
                .widget<CustomPaint>(
                  find.byWidgetPredicate(
                    (widget) =>
                        widget is CustomPaint &&
                        widget.painter is SplashScenePainter,
                  ),
                )
                .painter!
            as SplashScenePainter;
    expect(painter.clock.value, 1);

    await tester.pump(SplashMotion.reducedHold - AppMotion.fast);
    expect(finished, 0);
    await tester.pump(AppMotion.page);
    expect(finished, 1);
  });

  testWidgets('tapping the bag makes it hop; reduced motion ignores touch', (
    tester,
  ) async {
    SplashScenePainter painter() =>
        tester
                .widget<CustomPaint>(
                  find.byWidgetPredicate(
                    (widget) =>
                        widget is CustomPaint &&
                        widget.painter is SplashScenePainter,
                  ),
                )
                .painter!
            as SplashScenePainter;

    await _pumpPlayer(
      tester,
      variant: SplashVariant.wordmark,
      onFinished: () {},
    );
    await tester.tapAt(tester.getCenter(find.byType(SplashPlayer)));
    await tester.pump(); // the touch clock's first tick
    await tester.pump(SplashMotion.markHop ~/ 2);
    expect(painter().touch!.markLift, greaterThan(0));
    expect(painter().touch!.capeFlick, greaterThan(0));
    expect(painter().touch!.ripples, isNotEmpty);

    await tester.pumpWidget(const SizedBox());
    await _pumpPlayer(
      tester,
      variant: SplashVariant.burst,
      onFinished: () {},
      reducedMotion: true,
    );
    expect(painter().touch, isNull);
  });

  for (final (locale, tagline, wordmark) in const [
    (Locale('en'), 'Your everyday grocery hero', SplashWordmark.latin),
    (Locale('ar'), 'بطلك اليومي لكل مشترياتك', SplashWordmark.arabic),
  ]) {
    testWidgets(
      'the ${locale.languageCode} splash delivers its own name and live tagline',
      (tester) async {
        // Wired like the app: the MaterialApp waits for the translations.
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('en'), Locale('ar')],
            path: 'assets/i18n',
            fallbackLocale: const Locale('en'),
            startLocale: locale,
            saveLocale: false,
            child: Builder(
              builder: (context) => MaterialApp(
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                home: Scaffold(
                  body: SplashPlayer(
                    variant: SplashVariant.wordmark,
                    onFinished: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        for (
          var i = 0;
          i < 5 && find.byType(SplashPlayer).evaluate().isEmpty;
          i++
        ) {
          await tester.runAsync(() => Future<void>.delayed(AppMotion.fast));
          await tester.pump();
        }
        await tester.pump(SplashPlayer.maxStartDelay);
        await tester.pump(SplashVariant.wordmark.choreography.duration);

        expect(find.text(tagline), findsOneWidget);
        final painter =
            tester
                    .widget<CustomPaint>(
                      find.byWidgetPredicate(
                        (widget) =>
                            widget is CustomPaint &&
                            widget.painter is SplashScenePainter,
                      ),
                    )
                    .painter!
                as SplashScenePainter;
        expect(painter.wordmark, wordmark);
      },
    );
  }

  testWidgets('status bar icons turn dark once the burst covers the top', (
    tester,
  ) async {
    await _pumpPlayer(tester, variant: SplashVariant.burst, onFinished: () {});
    expect(_statusBar(tester).statusBarIconBrightness, Brightness.light);

    await tester.pump(SplashPlayer.maxStartDelay);
    expect(_statusBar(tester).statusBarIconBrightness, Brightness.light);
    await tester.pump(SplashVariant.burst.choreography.duration);
    expect(_statusBar(tester).statusBarIconBrightness, Brightness.dark);
  });

  testWidgets('the splash fades into the shell as a fresh arrival', (
    tester,
  ) async {
    Object? shellExtra;
    final router = GoRouter(
      initialLocation: Routes.splash,
      routes: [
        ...splashRoutes,
        GoRoute(
          path: Routes.shell,
          builder: (_, state) {
            shellExtra = state.extra;
            return const Text('shell');
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await _pumpLocalized(tester, MaterialApp.router(routerConfig: router));

    expect(find.byType(SplashPage), findsOneWidget);
    await tester.pump(SplashPlayer.maxStartDelay);
    await tester.pump(SplashVariant.configured.choreography.duration);
    await tester.pump(AppMotion.page);
    await tester.pump(AppMotion.page);

    expect(find.text('shell'), findsOneWidget);
    expect(shellExtra, isA<ShellArrival>());
  });

  testWidgets(
    'every arrival on the shell route is the same fade-through page',
    (tester) async {
      final router = GoRouter(routes: shellRoutes);
      addTearDown(router.dispose);
      final shell = shellRoutes.whereType<GoRoute>().firstWhere(
        (route) => route.path == Routes.shell,
      );
      late BuildContext context;
      await tester.pumpWidget(
        Builder(
          builder: (built) {
            context = built;
            return const SizedBox();
          },
        ),
      );

      GoRouterState state(Object? extra) => GoRouterState(
        router.configuration,
        uri: Uri.parse(Routes.shell),
        matchedLocation: Routes.shell,
        fullPath: Routes.shell,
        pathParameters: const {},
        pageKey: const ValueKey<String>(Routes.shell),
        extra: extra,
      );

      // Same type (and key) from every entry, so a `go` back to a shell in the
      // stack keeps it and its tabs.
      expect(
        shell.pageBuilder!(context, state(ShellArrival())),
        isA<HeroFadeThroughPage<Object?>>(),
      );
      expect(
        shell.pageBuilder!(context, state(null)),
        isA<HeroFadeThroughPage<Object?>>(),
      );
    },
  );
}
