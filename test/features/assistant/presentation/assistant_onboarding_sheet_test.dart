// The assistant's tour on the real widgets: it opens on its first step with
// the mascot perched on its edge; Next walks through five steps whose demos
// play (the question types out and its answers pop up; the cart confirms on
// a tap — or by the ghost finger — and counts the items); Skip, Maybe later,
// Start chatting, a question on the last step and a swipe down each close
// it with their result; reduced motion and right-to-left run every step.
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
import 'package:hero_mart/src/features/assistant/presentation/widgets/chat/assistant_suggestion_chip.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/onboarding/assistant_onboarding_perch.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/onboarding/assistant_onboarding_result.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/onboarding/assistant_onboarding_sheet.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    await frames(tester, 6);
    expect(find.text(en('onboarding_demo_added')), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
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
