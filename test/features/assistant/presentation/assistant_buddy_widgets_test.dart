// The assistant's buddy over a scrolling screen, on the real widgets: the
// launcher floats in and opens the chat; the greeting drops in after a touch
// and a calm moment, types itself out, unfolds its starters and hands their
// question to the chat; "not now", a swipe and the countdown each record
// their outcome; a screen reader keeps it up; scrolling down tucks the
// launcher away; holding it hides it for today; RTL puts it on the left.
import 'dart:convert';

import 'package:dartz/dartz.dart';
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
import 'package:jameia_mart/src/config/di/service_locator.dart';
import 'package:jameia_mart/src/config/routes/route_args/assistant_chat_args.dart';
import 'package:jameia_mart/src/config/routes/routes.dart';
import 'package:jameia_mart/src/config/theme/app_theme.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_availability.dart';
import 'package:jameia_mart/src/features/assistant/presentation/cubit/assistant_availability_cubit.dart';
import 'package:jameia_mart/src/features/assistant/presentation/cubit/assistant_buddy_cubit.dart';
import 'package:jameia_mart/src/features/assistant/presentation/widgets/buddy/assistant_buddy_close_button.dart';
import 'package:jameia_mart/src/features/assistant/presentation/widgets/buddy/assistant_buddy_greeting_card.dart';
import 'package:jameia_mart/src/features/assistant/presentation/widgets/buddy/assistant_buddy_launcher.dart';
import 'package:jameia_mart/src/features/assistant/presentation/widgets/buddy/assistant_buddy_layer.dart';
import 'package:jameia_mart/src/features/assistant/presentation/widgets/mascot/assistant_mascot.dart';
import 'package:jameia_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'assistant_nudge_fakes.dart';
import 'assistant_test_fakes.dart';

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

  late FakeAssistantRepository assistant;
  late AssistantAvailabilityCubit availability;
  late InMemoryAssistantNudgeRepository nudges;
  late AssistantBuddyCubit buddy;
  final now = DateTime(2026, 9, 27, 20);

  setUp(() async {
    Localization.load(const Locale('en'), translations: Translations(enJson));
    assistant = FakeAssistantRepository();
    availability = availabilityCubit(assistant);
    nudges = InMemoryAssistantNudgeRepository();
    buddy = buddyCubit(nudges, clock: () => now);
    await buddy.start();
  });

  tearDown(() => availability.close());

  Finder launcher() => find.descendant(
    of: find.byType(AssistantBuddyLauncher),
    matching: find.byType(AssistantMascot),
  );

  Future<void> frames(WidgetTester tester, [int count = 10]) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<GoRouter> pump(
    WidgetTester tester, {
    bool reducedMotion = false,
    bool screenReader = false,
    Locale locale = const Locale('en'),
  }) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: BlocProvider.value(
              value: buddy,
              child: AssistantBuddyLayer(
                place: 'home',
                greetHere: true,
                launcherHere: true,
                child: ListView.builder(
                  itemCount: 80,
                  itemBuilder: (_, index) =>
                      SizedBox(height: 64, child: Text('row $index')),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: Routes.assistant,
          builder: (_, state) {
            final args = state.extra;
            final prompt = args is AssistantChatArgs ? args.initialPrompt : '';
            return Scaffold(body: Text('chat:$prompt'));
          },
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
            BlocProvider<AssistantAvailabilityCubit>.value(value: availability),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: reducedMotion,
                accessibleNavigation: screenReader,
              ),
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
    availability.ensureLoaded();
    await tester.pump();
    assistant.availability.single.open(
      const Right(AssistantAvailability(enabled: true, allowGuests: true)),
    );
    await frames(tester);
    return router;
  }

  /// Touch the content, then give the greeting its calm moment and let it
  /// type out.
  Future<void> greet(WidgetTester tester) async {
    await tester.tap(find.text('row 2'));
    await frames(tester, 30);
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await buddy.close();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('the launcher floats in and opens the chat', (tester) async {
    final router = await pump(tester);
    expect(launcher(), findsOneWidget);
    expect(find.bySemanticsLabel(enJson['assistant']['entry']), findsOneWidget);

    await tester.tap(launcher());
    await frames(tester);
    expect(router.state.uri.path, Routes.assistant);
    expect(nudges.log.lastOpenedAt, now);
    await unmount(tester);
  });

  testWidgets('the greeting drops in, types, unfolds its starters and hands '
      'the chosen question to the chat', (tester) async {
    final router = await pump(tester);
    expect(find.byType(AssistantBuddyGreetingCard), findsNothing);

    await greet(tester);
    expect(find.byType(AssistantBuddyGreetingCard), findsOneWidget);
    expect(find.text('Good evening'), findsOneWidget);
    expect(
      find.text(enJson['assistant']['buddy_message_evening'] as String),
      findsWidgets,
    );
    expect(nudges.log.lastShownAt, now);

    final dinner = enJson['assistant']['starter_dinner_label'] as String;
    await tester.tap(find.text(dinner));
    await frames(tester);
    expect(router.state.uri.path, Routes.assistant);
    expect(
      find.text('chat:${enJson['assistant']['starter_dinner_prompt']}'),
      findsOneWidget,
    );
    expect(nudges.log.lastOpenedAt, now);
    await unmount(tester);
  });

  testWidgets('"not now" closes it, snoozes it and the launcher comes back', (
    tester,
  ) async {
    await pump(tester);
    await greet(tester);
    expect(launcher().hitTestable(), findsNothing);

    await tester.tap(find.byType(AssistantBuddyCloseButton));
    await frames(tester);
    expect(find.byType(AssistantBuddyGreetingCard), findsNothing);
    expect(nudges.log.snoozedUntil, now.add(const Duration(days: 3)));
    expect(launcher().hitTestable(), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a swipe up dismisses it', (tester) async {
    await pump(tester);
    await greet(tester);
    await tester.drag(
      find.byType(AssistantBuddyGreetingCard),
      const Offset(0, -160),
    );
    await frames(tester);
    expect(find.byType(AssistantBuddyGreetingCard), findsNothing);
    expect(nudges.log.snoozedUntil, isNotNull);
    await unmount(tester);
  });

  testWidgets('left alone it leaves after its countdown', (tester) async {
    await pump(tester);
    await greet(tester);
    await tester.pump(const Duration(seconds: 9));
    await frames(tester);
    expect(find.byType(AssistantBuddyGreetingCard), findsNothing);
    expect(nudges.log.ignoredInARow, 1);
    await unmount(tester);
  });

  testWidgets('with a screen reader it never leaves on its own', (
    tester,
  ) async {
    await pump(tester, screenReader: true);
    await greet(tester);
    await tester.pump(const Duration(seconds: 30));
    expect(find.byType(AssistantBuddyGreetingCard), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('reduced motion shows the greeting whole at once', (
    tester,
  ) async {
    await pump(tester, reducedMotion: true);
    await greet(tester);
    final dinner = enJson['assistant']['starter_dinner_label'] as String;
    expect(find.text(dinner), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('scrolling down tucks the launcher away, up brings it back', (
    tester,
  ) async {
    // Today already had its greeting: nothing takes the launcher's place.
    nudges.log = nudges.log.shownAt(now);
    await pump(tester);
    await tester.drag(find.text('row 3'), const Offset(0, -400));
    await frames(tester);
    expect(launcher().hitTestable(), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, 200));
    await frames(tester);
    expect(launcher().hitTestable(), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('holding the launcher offers to hide it for today', (
    tester,
  ) async {
    await pump(tester);
    await tester.longPress(launcher());
    await frames(tester);
    final hide = enJson['assistant']['buddy_hide'] as String;
    expect(find.text(enJson['assistant']['buddy_hide_title']), findsOneWidget);

    await tester.tap(find.text(hide));
    await frames(tester);
    expect(launcher().hitTestable(), findsNothing);
    expect(nudges.log.launcherHiddenUntil, DateTime(2026, 9, 28));
    await unmount(tester);
  });

  testWidgets('right-to-left puts the launcher on the left', (tester) async {
    Localization.load(const Locale('ar'), translations: Translations(arJson));
    await pump(tester, locale: const Locale('ar'));
    final center = tester.getCenter(launcher());
    expect(center.dx, lessThan(tester.view.physicalSize.width / 3 / 2));
    await greet(tester);
    expect(find.byType(AssistantBuddyGreetingCard), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });
}
