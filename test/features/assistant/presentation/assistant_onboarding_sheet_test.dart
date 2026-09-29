// The assistant's tour on the real widgets: it opens on its first step with
// the mascot perched on its edge; Next walks through five steps whose demos
// play (the question types out and its answers pop up; the cart confirms on
// a tap — or by the ghost finger — and counts the items); Skip, Maybe later,
// Start chatting, a question on the last step and a swipe down each close
// it with their result; reduced motion and right-to-left run every step.
// Motion (docs/motion §9.6 §2.12): each demo plays once per opening (a step
// swiped back to shows its end, and the mascot does not react again); the
// perch leans the drag's way without flipping side half-way; the cart demo
// flies its items into its cart (no confetti); under reduced motion the
// perch sits upright in place and the cart counts at once, with no flight.
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/config/di/service_locator.dart';
import 'package:hero_mart/src/config/theme/app_theme.dart';
import 'package:hero_mart/src/core/motion/confetti_burst.dart';
import 'package:hero_mart/src/core/motion/fly_to_cart.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/chat/assistant_suggestion_chip.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/onboarding/assistant_onboarding_perch.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/onboarding/assistant_onboarding_result.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/onboarding/assistant_onboarding_sheet.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/motion/rolling_test_finders.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> enJson;
  late Map<String, dynamic> arJson;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await setupServiceLocator();
    enJson = json.decode(
      await rootBundle.loadString('assets/i18n/en.json'),
    ) as Map<String, dynamic>;
    arJson = json.decode(
      await rootBundle.loadString('assets/i18n/ar.json'),
    ) as Map<String, dynamic>;
  });

  setUp(
    () => Localization.load(
      const Locale('en'),
      translations: Translations(enJson),
    ),
  );

  String en(String key) => enJson['assistant'][key] as String;
  String ar(String key) => arJson['assistant'][key] as String;

  AssistantOnboardingResult? result;
  var closed = false;

  Future<void> frames(WidgetTester tester, [int count = 10]) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Opens the tour over a plain page.
  Future<void> open(
    WidgetTester tester, {
    bool reducedMotion = false,
    Locale locale = const Locale('en'),
  }) async {
    result = null;
    closed = false;
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () async {
                    result = await AssistantOnboardingSheet.show(context);
                    closed = true;
                  },
                  child: const Text('open'),
                ),
              ),
            ),
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
        startLocale: locale,
        saveLocale: false,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<CartCubit>(create: (_) => sl<CartCubit>()),
            BlocProvider<AuthSessionCubit>(
              create: (_) => sl<AuthSessionCubit>(),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(disableAnimations: reducedMotion),
              child: Directionality(
                textDirection: locale.languageCode == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child!,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('open'));
    await frames(tester, 20);
  }

  /// Taps Next [times] times, letting each step's demo play for [play].
  Future<void> next(
    WidgetTester tester, {
    int times = 1,
    int play = 8,
    String? label,
  }) async {
    for (var step = 0; step < times; step++) {
      await tester.tap(find.text(label ?? en('onboarding_next')));
      await frames(tester, play);
    }
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('opens on its first step with the mascot on its edge', (
    tester,
  ) async {
    await open(tester);
    expect(find.byType(AssistantOnboardingPerch), findsOneWidget);
    expect(find.text(en('onboarding_hello_title')), findsOneWidget);
    expect(find.text(en('onboarding_skill_find')), findsOneWidget);
    expect(find.text(en('onboarding_skip')), findsOneWidget);
    expect(find.text(en('onboarding_next')), findsOneWidget);

    // The mascot sits across the card's top edge, above the first step.
    final perch = tester.getRect(find.byType(AssistantOnboardingPerch));
    final title = tester.getRect(find.text(en('onboarding_hello_title')));
    expect(perch.bottom, lessThan(title.top));
    await unmount(tester);
  });

  testWidgets('Next walks every step; the last one starts the chat', (
    tester,
  ) async {
    await open(tester);
    for (final step in ['ask', 'cart', 'more', 'ready']) {
      await next(tester);
      expect(find.text(en('onboarding_${step}_title')), findsOneWidget);
    }
    expect(find.text(en('onboarding_next')), findsNothing);
    expect(find.text(en('onboarding_skip')), findsNothing);
    expect(find.text(en('onboarding_later')), findsOneWidget);

    await tester.tap(find.text(en('onboarding_start')));
    await frames(tester);
    expect(closed, isTrue);
    expect(
      result,
      const AssistantOnboardingResult(AssistantOnboardingExit.chat),
    );
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('Skip closes it on the way', (tester) async {
    await open(tester);
    await next(tester);
    await tester.tap(find.text(en('onboarding_skip')));
    await frames(tester);
    expect(
      result,
      const AssistantOnboardingResult(AssistantOnboardingExit.skipped),
    );
    await unmount(tester);
  });

  testWidgets('"Maybe later" on the last step closes it for later', (
    tester,
  ) async {
    await open(tester);
    await next(tester, times: 4);
    await tester.tap(find.text(en('onboarding_later')));
    await frames(tester);
    expect(
      result,
      const AssistantOnboardingResult(AssistantOnboardingExit.later),
    );
    await unmount(tester);
  });

  testWidgets('a question on the last step opens the chat with it', (
    tester,
  ) async {
    await open(tester);
    await next(tester, times: 4, play: 12);
    final starters = find.byType(AssistantSuggestionChip);
    expect(starters, findsWidgets);

    await tester.tap(starters.first);
    await frames(tester);
    expect(result?.exit, AssistantOnboardingExit.chat);
    expect(result?.starter, isNotNull);
    await unmount(tester);
  });

  testWidgets('swiped down, it closes with nothing', (tester) async {
    await open(tester);
    await tester.fling(
      find.byType(AssistantOnboardingPerch),
      const Offset(0, 600),
      2000,
    );
    await frames(tester);
    expect(closed, isTrue);
    expect(result, isNull);
    await unmount(tester);
  });

  testWidgets('the ask demo types the question and pops up the answers', (
    tester,
  ) async {
    await open(tester);
    await next(tester, play: 40);
    expect(find.text(en('onboarding_demo_ask')), findsWidgets);
    expect(find.text(en('onboarding_demo_answer')), findsOneWidget);
    for (final item in ['cleaner', 'bulbs', 'coffee']) {
      expect(find.text(en('onboarding_demo_$item')), findsOneWidget);
    }
    await unmount(tester);
  });

  testWidgets('the cart demo confirms on a tap and counts the items', (
    tester,
  ) async {
    await open(tester);
    await next(tester, times: 2, play: 20);
    expect(find.text(en('onboarding_demo_added')), findsNothing);

    await tester.tap(find.text(en('onboarding_demo_confirm')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(FlyToCart.inFlight.value, isTrue, reason: 'the items fly in');
    expect(findRolled('4'), findsNothing, reason: 'the count waits to land');
    await frames(tester, 6);
    expect(FlyToCart.inFlight.value, isFalse);
    expect(find.text(en('onboarding_demo_added')), findsOneWidget);
    expect(findRolled('4'), findsOneWidget);
    expect(find.byType(ConfettiBurst), findsNothing, reason: 'no confetti');
    await unmount(tester);
  });

  testWidgets('left alone, the ghost finger shows how and confirms', (
    tester,
  ) async {
    await open(tester);
    await next(tester, times: 2, play: 60);
    expect(find.text(en('onboarding_demo_added')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('reduced motion shows each demo whole at once', (tester) async {
    await open(tester, reducedMotion: true);
    expect(find.text(en('onboarding_skill_home')), findsOneWidget);
    await next(tester, play: 2);
    expect(find.text(en('onboarding_demo_coffee')), findsOneWidget);
    await next(tester, play: 2);
    expect(find.text(en('onboarding_demo_confirm')), findsOneWidget);
    await next(tester, play: 2);
    expect(find.text(en('onboarding_demo_slot_today')), findsOneWidget);
    await next(tester, play: 2);
    expect(find.text(en('onboarding_demo_tap_me')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  /// The perch's tilt: the sine of its rotation (> 0 leans clockwise).
  double lean(WidgetTester tester) {
    final rotate = tester
        .widgetList<Transform>(
          find.descendant(
            of: find.byType(AssistantOnboardingPerch),
            matching: find.byType(Transform),
          ),
        )
        .firstWhere(
          (transform) => transform.alignment == Alignment.bottomCenter,
        );
    return rotate.transform.storage[1];
  }

  /// Drags the pages towards the next step in steps, returning the tilt
  /// seen at each; the finger stays down.
  Future<(TestGesture, List<double>)> dragTowardsNext(
    WidgetTester tester, {
    double direction = -1,
  }) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PageView)),
    );
    final tilts = <double>[];
    for (var step = 0; step < 8; step++) {
      await gesture.moveBy(Offset(direction * 38, 0));
      await tester.pump(const Duration(milliseconds: 16));
      tilts.add(lean(tester));
    }
    return (gesture, tilts);
  }

  testWidgets('each demo plays once per opening: a step swiped back to '
      'shows its end and the mascot does not react again', (tester) async {
    await open(tester);
    AssistantOnboardingPerch perch() => tester.widget<AssistantOnboardingPerch>(
      find.byType(AssistantOnboardingPerch),
    );
    expect(perch().wave, 1, reason: 'the hello: its own painted wave');
    await next(tester, play: 40);
    final waved = perch().wave;
    final cheered = perch().cheer;
    final mood = perch().mood;

    await tester.drag(find.byType(PageView), const Offset(400, 0));
    await frames(tester, 10);
    expect(find.text(en('onboarding_hello_title')), findsOneWidget);
    expect(find.text(en('onboarding_skill_home')), findsOneWidget);
    expect(perch().wave, waved, reason: 'no second hello');
    expect(perch().cheer, cheered);
    expect(perch().mood, mood);
    await unmount(tester);
  });

  testWidgets('the perch leans the way of the drag and never flips side '
      'half-way', (tester) async {
    await open(tester);
    final (gesture, tilts) = await dragTowardsNext(tester);
    expect(tilts.reduce((a, b) => a > b ? a : b), greaterThan(0.1));
    for (final tilt in tilts) {
      expect(tilt, greaterThanOrEqualTo(0), reason: 'one side all the way');
    }
    await gesture.up();
    await frames(tester, 10);
    expect(lean(tester), closeTo(0, 0.001), reason: 'upright once landed');
    await unmount(tester);
  });

  testWidgets('reduced motion: the perch sits upright in place and the cart '
      'counts at once, with no flight', (tester) async {
    await open(tester, reducedMotion: true);
    final (gesture, tilts) = await dragTowardsNext(tester);
    expect(tilts.every((tilt) => tilt == 0), isTrue);
    await gesture.up();
    await frames(tester, 4);
    await next(tester, play: 2);
    await tester.tap(find.text(en('onboarding_demo_confirm')));
    await tester.pump();
    expect(FlyToCart.inFlight.value, isFalse);
    expect(findRolled('4'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('right-to-left runs every step cleanly', (tester) async {
    Localization.load(const Locale('ar'), translations: Translations(arJson));
    await open(tester, locale: const Locale('ar'));
    expect(find.text(ar('onboarding_hello_title')), findsOneWidget);
    await next(tester, times: 4, play: 36, label: ar('onboarding_next'));
    expect(find.text(ar('onboarding_ready_title')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(ar('onboarding_start')));
    await frames(tester);
    expect(result?.exit, AssistantOnboardingExit.chat);
    await unmount(tester);
  });
}
