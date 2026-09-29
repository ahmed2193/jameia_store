// The assistant's buddy over a scrolling screen, on the real widgets: the
// launcher floats in and opens the chat; the greeting drops in after a touch
// and a calm moment, types itself out, unfolds its starters and hands their
// question to the chat; "not now", a swipe and the countdown each record
// their outcome; a screen reader keeps it up; scrolling down tucks the
// launcher away; holding it hides it for today; RTL puts it on the left.
// A newcomer meets the tour: from the launcher's first tap (skipping it
// goes on to the chat) or the first greeting's invitation; "maybe later"
// hands back to the launcher, which thinks out loud where it lives. On a
// calm screen the launcher thinks "How can I help you today?" above its
// head: it rises out of the mascot, its words come in at once (no dots),
// it holds still (no float), then hands over in place to one more line; a
// touch or a scroll sends the line away, pressing the mascot dips it, a line
// about offers asks for them in the chat, and coming back to the app after a
// while greets again (docs/motion §9.6 §3).
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
import 'package:hero_mart/src/config/di/service_locator.dart';
import 'package:hero_mart/src/config/routes/route_args/assistant_chat_args.dart';
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/config/theme/app_theme.dart';
import 'package:hero_mart/src/core/widgets/branded_dot_loader.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_availability.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_starter.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_thought.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_availability_cubit.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_buddy_cubit.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/buddy/assistant_buddy_close_button.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/buddy/assistant_buddy_greeting_card.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/buddy/assistant_buddy_launcher.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/buddy/assistant_buddy_layer.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/buddy/assistant_buddy_thought_badge.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/buddy/assistant_buddy_thought_bubble.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/buddy/assistant_buddy_thought_cloud.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/buddy/assistant_buddy_tour_chip.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/buddy/buddy_motion_gate.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/mascot/assistant_mascot.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/onboarding/assistant_onboarding_sheet.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
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
  late DateTime now;

  setUp(() async {
    now = DateTime(2026, 9, 27, 20);
    Localization.load(const Locale('en'), translations: Translations(enJson));
    assistant = FakeAssistantRepository();
    availability = availabilityCubit(assistant);
    nudges = InMemoryAssistantNudgeRepository.met();
    buddy = buddyCubit(nudges, clock: () => now);
    await buddy.start();
  });

  /// A customer who never met the assistant.
  Future<void> newcomer() async {
    await buddy.close();
    nudges = InMemoryAssistantNudgeRepository();
    buddy = buddyCubit(nudges, clock: () => now);
    await buddy.start();
  }

  /// A customer whose launcher thinks out loud after [after] on screen,
  /// and [every] after each line.
  Future<void> thinker({
    Duration after = const Duration(milliseconds: 300),
    Duration every = const Duration(days: 1),
  }) async {
    await buddy.close();
    buddy = buddyCubit(
      nudges,
      clock: () => now,
      thinkAfter: after,
      thinkEvery: every,
    );
    await buddy.start();
  }

  /// The app goes to the background and comes back [after] later.
  Future<void> awayFor(WidgetTester tester, Duration after) async {
    Future<void> lifecycle(AppLifecycleState state) =>
        tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/lifecycle',
          const StringCodec().encodeMessage(state.toString()),
          (_) {},
        );
    await lifecycle(AppLifecycleState.paused);
    now = now.add(after);
    await lifecycle(AppLifecycleState.resumed);
  }

  /// Lets lines go by quickly until one [wanted] is up; returns it. A visit
  /// says few lines, so a quiet launcher is sent to a new visit.
  Future<AssistantThought> skipUntil(
    WidgetTester tester,
    bool Function(AssistantThought line) wanted,
  ) async {
    var quiet = 0;
    for (var i = 0; i < 600; i++) {
      final current = buddy.state.thought;
      if (current != null) {
        quiet = 0;
        if (wanted(current)) return current;
        // Said: the opening line hands over to its second one.
        buddy.thoughtSaid(current);
        if (buddy.state.thought == current) buddy.thoughtDone(current);
      } else if (++quiet > 20) {
        quiet = 0;
        await awayFor(tester, AssistantBuddyCubit.defaultVisitGap);
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    fail('no such line came');
  }

  /// Frames until the line on screen is no longer [line].
  Future<void> untilPast(WidgetTester tester, AssistantThought line) async {
    for (var i = 0; i < 120 && buddy.state.thought == line; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// The launcher's thought saying [line].
  Finder saying(AssistantThought line) => find.descendant(
    of: find.byType(AssistantBuddyThoughtBubble),
    matching: find.text(line.textKey.tr()),
  );

  /// The launcher's thought saying [key].
  Finder thought(String key) => find.descendant(
    of: find.byType(AssistantBuddyThoughtBubble),
    matching: find.text(enJson['assistant'][key] as String),
  );

  String text(String key) => enJson['assistant'][key] as String;

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

  group('the tour', () {
    testWidgets("a newcomer's first tap opens the tour; skipping it goes on "
        'to the chat', (tester) async {
      await newcomer();
      final router = await pump(tester);
      await tester.tap(launcher());
      await frames(tester, 20);
      expect(find.byType(AssistantOnboardingSheet), findsOneWidget);
      expect(find.text(text('onboarding_hello_title')), findsOneWidget);
      expect(nudges.log.isOnboarded, isTrue);
      expect(launcher().hitTestable(), findsNothing, reason: 'it is up top');

      await tester.tap(find.text(text('onboarding_skip')));
      await frames(tester, 10);
      expect(find.byType(AssistantOnboardingSheet), findsNothing);
      expect(router.state.uri.path, Routes.assistant);
      expect(nudges.log.lastOpenedAt, now);
      await unmount(tester);
    });

    testWidgets('"maybe later" hands back to the launcher, which thinks '
        'where it lives for a moment', (tester) async {
      await newcomer();
      final router = await pump(tester);
      await tester.tap(launcher());
      await frames(tester, 20);
      for (var step = 0; step < 4; step++) {
        await tester.tap(find.text(text('onboarding_next')));
        await frames(tester, 8);
      }
      await tester.tap(find.text(text('onboarding_later')));
      await frames(tester, 4);
      expect(find.byType(AssistantOnboardingSheet), findsNothing);
      expect(router.state.uri.path, '/');
      expect(launcher().hitTestable(), findsOneWidget);
      expect(find.byType(AssistantBuddyThoughtBubble), findsOneWidget);

      await frames(tester, 30);
      expect(thought('buddy_coach'), findsWidgets, reason: 'typed out');

      await frames(tester, 60);
      expect(thought('buddy_coach'), findsNothing, reason: 'it goes by itself');
      expect(buddy.state.thought, isNull);
      await unmount(tester);
    });

    testWidgets('the first greeting invites to the tour', (tester) async {
      await newcomer();
      await pump(tester);
      await greet(tester);
      expect(find.text(text('buddy_message_invite')), findsWidgets);
      expect(find.byType(AssistantBuddyTourChip), findsOneWidget);

      await tester.tap(find.byType(AssistantBuddyTourChip));
      await frames(tester, 20);
      expect(find.byType(AssistantOnboardingSheet), findsOneWidget);
      expect(find.byType(AssistantBuddyGreetingCard), findsNothing);
      expect(nudges.log.isOnboarded, isTrue);
      expect(nudges.log.lastOpenedAt, now);

      await tester.tap(find.text(text('onboarding_skip')));
      await frames(tester, 30);
      expect(find.byType(AssistantOnboardingSheet), findsNothing);
      expect(
        thought('buddy_coach'),
        findsWidgets,
        reason: 'skipped from the greeting: no chat, just where it lives',
      );
      await unmount(tester);
    });

    testWidgets('a met customer is never shown the tour', (tester) async {
      await pump(tester);
      await greet(tester);
      expect(find.byType(AssistantBuddyTourChip), findsNothing);
      await unmount(tester);
    });
  });

  group('the motion gate (the buddy holds still)', () {
    bool mayMove(WidgetTester tester) => tester
        .widget<BuddyMotionGate>(
          find.byType(BuddyMotionGate, skipOffstage: false),
        )
        .mayMove;

    Object? hops(WidgetTester tester) => tester
        .widget<AssistantMascot>(
          find.descendant(
            of: find.byType(AssistantBuddyLauncher, skipOffstage: false),
            matching: find.byType(AssistantMascot, skipOffstage: false),
            skipOffstage: false,
          ),
        )
        .cheer;

    testWidgets('while the customer types: the keyboard is up', (tester) async {
      nudges.log = nudges.log.shownAt(now);
      await pump(tester);
      expect(mayMove(tester), isTrue);
      tester.view.viewInsets = const FakeViewPadding(bottom: 900);
      addTearDown(tester.view.resetViewInsets);
      await frames(tester, 2);
      expect(mayMove(tester), isFalse);
      tester.view.resetViewInsets();
      await frames(tester, 5);
      expect(mayMove(tester), isFalse, reason: 'it settles first');
      await frames(tester, 20);
      expect(mayMove(tester), isTrue);
      await unmount(tester);
    });

    testWidgets('while the customer scrolls, and a moment after', (
      tester,
    ) async {
      nudges.log = nudges.log.shownAt(now);
      await pump(tester);
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('row 4')),
      );
      await gesture.moveBy(const Offset(0, 60));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveBy(const Offset(0, 60));
      await tester.pump(const Duration(milliseconds: 50));
      expect(mayMove(tester), isFalse);
      await gesture.up();
      await frames(tester, 5);
      expect(mayMove(tester), isFalse, reason: 'it settles first');
      await frames(tester, 25);
      expect(mayMove(tester), isTrue);
      await unmount(tester);
    });

    testWidgets('under a page on top (checkout, payment, a placed order): a '
        'cart hop is dropped, and back in front it settles first', (
      tester,
    ) async {
      nudges.log = nudges.log.shownAt(now);
      final router = await pump(tester);
      final rest = hops(tester);
      router.push(Routes.assistant);
      await frames(tester, 5);
      expect(mayMove(tester), isFalse);
      buddy.cheer();
      await frames(tester, 2);
      expect(hops(tester), rest, reason: 'still: no hop');

      router.pop();
      await frames(tester, 5);
      expect(mayMove(tester), isFalse, reason: 'it settles first');
      await frames(tester, 25);
      expect(mayMove(tester), isTrue);
      await unmount(tester);
    });

    testWidgets('the greeting countdown never runs out under a page; back '
        'in front it starts again from full', (tester) async {
      final router = await pump(tester);
      await greet(tester);
      expect(find.byType(AssistantBuddyGreetingCard), findsOneWidget);
      router.push(Routes.assistant);
      await frames(tester, 5);
      await tester.pump(const Duration(seconds: 12));
      router.pop();
      await frames(tester, 5);
      expect(find.byType(AssistantBuddyGreetingCard), findsOneWidget);
      expect(nudges.log.ignoredInARow, 0, reason: 'nothing logged');

      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(AssistantBuddyGreetingCard), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await frames(tester);
      expect(find.byType(AssistantBuddyGreetingCard), findsNothing);
      expect(nudges.log.ignoredInARow, 1);
      await unmount(tester);
    });
  });

  group('the thoughts', () {
    testWidgets('a calm launcher thinks a greeting above its head — words at '
        'once, no dots, holding still — then hands over in place to one '
        'more line', (tester) async {
      nudges.log = nudges.log.shownAt(now);
      await thinker();
      await pump(tester);
      expect(find.byType(BrandedDotLoader), findsNothing, reason: 'no dots');
      final opener = buddy.state.thought!;
      expect(opener.opens, isTrue);
      expect(saying(opener), findsOneWidget, reason: 'its words, at once');
      expect(nudges.writes, 0, reason: 'nothing to remember: every opening');
      expect(
        find.descendant(
          of: find.byType(AssistantBuddyThoughtBubble),
          matching: find.byType(AssistantBuddyThoughtBadge),
        ),
        findsOneWidget,
        reason: 'what it is about, at a glance',
      );
      await frames(tester, 2);
      expect(
        tester.widget<AssistantMascot>(launcher()).wave,
        1,
        reason: 'its sprout waves as it greets',
      );

      await frames(tester, 15);
      expect(saying(opener), findsWidgets);
      final bubble = tester.getRect(find.byType(AssistantBuddyThoughtBubble));
      final mascot = tester.getRect(launcher());
      expect(bubble.bottom, lessThanOrEqualTo(mascot.top), reason: 'above');
      final cloud = tester.getRect(find.byType(AssistantBuddyThoughtCloud));
      await frames(tester, 5);
      expect(
        tester.getRect(find.byType(AssistantBuddyThoughtCloud)),
        cloud,
        reason: 'it holds still while it is up',
      );

      await untilPast(tester, opener);
      final second = buddy.state.thought!;
      expect(second.opens, isFalse);
      await frames(tester, 5);
      expect(saying(second), findsWidgets, reason: 'in the same bubble');
      expect(find.byType(BrandedDotLoader), findsNothing);

      await frames(tester, 80);
      expect(find.byType(AssistantBuddyThoughtCloud), findsNothing);
      expect(buddy.state.thought, isNull, reason: 'then it rests');
      await unmount(tester);
    });

    testWidgets('a touch elsewhere sends the line away', (tester) async {
      nudges.log = nudges.log.shownAt(now);
      await thinker();
      await pump(tester);
      await frames(tester, 25);
      final opener = buddy.state.thought!;
      expect(saying(opener), findsWidgets);

      await tester.tap(find.text('row 5'));
      await frames(tester, 5);
      expect(buddy.state.thought, isNull);
      expect(find.byType(AssistantBuddyThoughtCloud), findsNothing);
      await unmount(tester);
    });

    testWidgets('scrolling sends the line away and tucks the launcher', (
      tester,
    ) async {
      nudges.log = nudges.log.shownAt(now);
      await thinker();
      await pump(tester);
      await frames(tester, 25);
      expect(buddy.state.thought, isNotNull);
      await tester.drag(find.text('row 3'), const Offset(0, -400));
      await frames(tester, 5);
      expect(buddy.state.thought, isNull);
      expect(find.byType(AssistantBuddyThoughtCloud), findsNothing);
      expect(launcher().hitTestable(), findsNothing, reason: 'it tucks');
      await unmount(tester);
    });

    testWidgets('pressing the mascot squishes its bubble; tapping the line '
        'opens the chat', (tester) async {
      nudges.log = nudges.log.shownAt(now);
      await thinker();
      final router = await pump(tester);
      await frames(tester, 25);
      final press = await tester.startGesture(tester.getCenter(launcher()));
      await tester.pump(const Duration(milliseconds: 200));
      final squish = tester.widget<AnimatedScale>(
        find
            .descendant(
              of: find.byType(AssistantBuddyThoughtCloud),
              matching: find.byType(AnimatedScale),
            )
            .first,
      );
      expect(squish.scale, lessThan(1));
      await press.cancel();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(saying(buddy.state.thought!).first);
      await frames(tester);
      expect(router.state.uri.path, Routes.assistant);
      await unmount(tester);
    });

    testWidgets('a line about offers asks for them in the chat', (
      tester,
    ) async {
      nudges.log = nudges.log.shownAt(now);
      await thinker(every: const Duration(milliseconds: 100));
      final router = await pump(tester);
      final deals = await skipUntil(
        tester,
        (line) => line.starter == AssistantStarter.offers,
      );
      await frames(tester, 20);
      await tester.tap(saying(deals).first);
      await frames(tester);
      expect(router.state.uri.path, Routes.assistant);
      expect(
        find.text('chat:${AssistantStarter.offers.promptKey.tr()}'),
        findsOneWidget,
      );
      await unmount(tester);
    });

    testWidgets("a newcomer's tap on a line opens the tour; skipping it asks "
        "the line's question", (tester) async {
      await newcomer();
      nudges.log = nudges.log.shownAt(now);
      await thinker(every: const Duration(milliseconds: 100));
      final router = await pump(tester);
      final deals = await skipUntil(
        tester,
        (line) => line.starter == AssistantStarter.offers,
      );
      await frames(tester, 20);
      await tester.tap(saying(deals).first);
      await frames(tester, 20);
      expect(find.byType(AssistantOnboardingSheet), findsOneWidget);

      await tester.tap(find.text(text('onboarding_skip')));
      await frames(tester, 10);
      expect(router.state.uri.path, Routes.assistant);
      expect(
        find.text('chat:${AssistantStarter.offers.promptKey.tr()}'),
        findsOneWidget,
      );
      await unmount(tester);
    });

    testWidgets('coming back to the app after a while greets again', (
      tester,
    ) async {
      nudges.log = nudges.log.shownAt(now);
      await thinker();
      await pump(tester);
      await frames(tester, 150);
      expect(find.byType(AssistantBuddyThoughtCloud), findsNothing);

      await awayFor(tester, const Duration(seconds: 5));
      await frames(tester, 30);
      expect(find.byType(AssistantBuddyThoughtCloud), findsNothing);

      await awayFor(tester, AssistantBuddyCubit.defaultVisitGap);
      await frames(tester, 30);
      final opener = buddy.state.thought;
      expect(opener?.opens, isTrue);
      expect(saying(opener!), findsWidgets);
      await unmount(tester);
    });

    testWidgets('reduced motion shows each line whole, hands over, then '
        'lets go', (tester) async {
      nudges.log = nudges.log.shownAt(now);
      await thinker();
      await pump(tester, reducedMotion: true);
      await frames(tester, 2);
      final opener = buddy.state.thought!;
      expect(saying(opener), findsWidgets);
      expect(find.byType(BrandedDotLoader), findsNothing);

      await untilPast(tester, opener);
      await tester.pump();
      expect(saying(buddy.state.thought!), findsWidgets);
      expect(find.byType(BrandedDotLoader), findsNothing);
      await frames(tester, 60);
      expect(find.byType(AssistantBuddyThoughtCloud), findsNothing);
      await unmount(tester);
    });

    testWidgets('right-to-left: the bubble rises on the left, in Arabic', (
      tester,
    ) async {
      Localization.load(const Locale('ar'), translations: Translations(arJson));
      nudges.log = nudges.log.shownAt(now);
      await thinker();
      await pump(tester, locale: const Locale('ar'));
      await frames(tester, 25);
      final opener = buddy.state.thought!;
      final arabic = arJson['assistant'][opener.textKey.split('.').last];
      expect(saying(opener), findsWidgets);
      expect(find.text(arabic as String), findsWidgets);
      final cloud = tester.getRect(find.byType(AssistantBuddyThoughtCloud));
      final width =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(cloud.center.dx, lessThan(width / 2), reason: 'on the left');
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });

    testWidgets('a screen reader hears the launcher, not a line', (
      tester,
    ) async {
      nudges.log = nudges.log.shownAt(now);
      await thinker();
      await pump(tester, screenReader: true);
      await frames(tester, 30);
      expect(find.byType(AssistantBuddyThoughtBubble), findsOneWidget);
      expect(find.byType(AssistantBuddyThoughtCloud), findsNothing);
      await unmount(tester);
    });
  });
}
