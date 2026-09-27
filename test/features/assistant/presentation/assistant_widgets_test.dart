// The assistant chat UI over the real widgets: every block kind draws its
// card, a proposal confirms once (and waits while the reply streams), the
// composer refuses an over-long message and sends a valid one, the welcome
// starters send their full question, a store with the assistant off says so,
// reduced motion leaves nothing animating, and history pops the picked id.
//
// App-global cubits come from the real container (cart, session); the
// assistant cubits run over `FakeAssistantRepository`.
import 'dart:async';
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
import 'package:intl/date_symbol_data_local.dart';
import 'package:hero_mart/src/config/di/service_locator.dart';
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/config/theme/app_theme.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/widgets/app_button.dart';
import 'package:hero_mart/src/features/assistant/data/mappers/assistant_block_mapper.dart';
import 'package:hero_mart/src/features/assistant/data/models/assistant_block_model.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_availability.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_block.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_conversation_entity.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_availability_cubit.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_chat_cubit.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_history_cubit.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_voice_cubit.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/blocks/assistant_card_list.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/chat/assistant_chat_app_bar.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/chat/assistant_chat_body.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/composer/assistant_composer.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/composer/assistant_send_button.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/history/assistant_history_body.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hero_mart/src/features/language/presentation/cubit/localization_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../assistant_fixtures.dart';
import 'assistant_test_fakes.dart';
import 'assistant_voice_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<AssistantBlock> blocks;
  late Map<String, dynamic> enJson;
  late Map<String, dynamic> arJson;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
    await setupServiceLocator();
    enJson = json.decode(
      await rootBundle.loadString('assets/i18n/en.json'),
    ) as Map<String, dynamic>;
    arJson = json.decode(
      await rootBundle.loadString('assets/i18n/ar.json'),
    ) as Map<String, dynamic>;
    Localization.load(const Locale('en'), translations: Translations(enJson));
    blocks = AssistantBlockModel.listFrom(AssistantFixtures.mockBlocks())
        .toEntities();
  });

  late FakeAssistantRepository repo;
  late AssistantChatCubit chat;
  late AssistantAvailabilityCubit availability;
  late AssistantHistoryCubit history;
  late AssistantVoiceCubit voice;

  setUp(() {
    repo = FakeAssistantRepository();
    chat = chatCubit(repo);
    availability = availabilityCubit(repo);
    history = historyCubit(repo);
    voice = voiceCubit(FakeVoiceRepository());
  });

  tearDown(() async {
    await chat.close();
    await availability.close();
    await history.close();
    await voice.close();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<GoRouter> pump(
    WidgetTester tester,
    Widget home, {
    bool reducedMotion = false,
    Locale locale = const Locale('en'),
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    Widget stub(String name) => Scaffold(body: Text(name));
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => home),
        for (final path in [
          Routes.cartPreview,
          Routes.orderTracking,
          Routes.offers,
          Routes.recipe,
          Routes.category,
          Routes.productListing,
          Routes.productDetail,
          Routes.login,
        ])
          GoRoute(path: path, builder: (_, _) => stub(path)),
        GoRoute(
          path: Routes.assistantHistory,
          builder: (_, _) => BlocProvider.value(
            value: history,
            child: const Scaffold(body: AssistantHistoryBody()),
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
            BlocProvider<LocalizationCubit>(
              create: (_) => sl<LocalizationCubit>(),
            ),
            BlocProvider<AssistantChatCubit>.value(value: chat),
            BlocProvider<AssistantAvailabilityCubit>.value(value: availability),
            BlocProvider<AssistantVoiceCubit>.value(value: voice),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: reducedMotion,
                textScaler: textScaler,
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
    await settle(tester);
    return router;
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('every known block kind draws its card; unknown kinds none', (
    tester,
  ) async {
    await pump(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: AssistantCardList(cards: AssistantCards.of(blocks)),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Suggested for your cart'), findsOneWidget);
    expect(find.text('Your cart'), findsOneWidget);
    expect(find.text('5 items'), findsOneWidget);
    expect(find.textContaining('JM-10042'), findsOneWidget);
    expect(find.text('Order status'), findsOneWidget);
    expect(find.text('Offers for you'), findsOneWidget);
    expect(find.text('SAVE10'), findsOneWidget);
    expect(find.textContaining('Kuwaiti Egg'), findsOneWidget);
    expect(find.text('Where do you deliver?'), findsOneWidget);
    expect(find.text('Sections'), findsOneWidget);
    expect(find.text('Dairy'), findsOneWidget);
    expect(find.text('Brands'), findsOneWidget);
    expect(find.text('Available delivery times'), findsOneWidget);
    expect(find.text('Free'), findsOneWidget); // fee 0 (N22)
    expect(find.text('Branches'), findsOneWidget);
    expect(find.text('Salmiya branch'), findsOneWidget);
    expect(find.textContaining('T-2026-0042'), findsOneWidget);
    expect(
      find.text('Part of this answer is unavailable right now.'),
      findsOneWidget,
    );
    // The empty delivery_info (L13) and the unknown kind draw nothing.
    expect(find.text('Delivery'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a FAQ answer unfolds on tap', (tester) async {
    await pump(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: AssistantCardList(
            cards: [blocks.whereType<AssistantFaqBlock>().single],
          ),
        ),
      ),
    );
    final answer = find.text('All of Kuwait.');
    expect(answer.hitTestable(), findsNothing);
    await tester.tap(find.text('Where do you deliver?'));
    await settle(tester);
    expect(answer.hitTestable(), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Where do you deliver?')),
      isSemantics(isButton: true, isExpanded: true),
    );
    await unmount(tester);
  });

  testWidgets('a pending proposal confirms once, and waits while streaming', (
    tester,
  ) async {
    unawaited(chat.loadThread('c1'));
    repo.threads.single.open(
      Right(
        threadOf([
          userMessage('u1', 'add eggs'),
          assistantReply('m1', 'Here you go', blocks: [pendingProposal]),
        ]),
      ),
    );
    await pump(
      tester,
      const Scaffold(body: AssistantCardList(cards: [pendingProposal])),
    );

    final confirm = find.text('Add 2 items to cart');
    expect(confirm, findsOneWidget);
    await tester.tap(confirm);
    await tester.pump();
    await tester.tap(find.byType(AssistantCardList), warnIfMissed: false);
    await tester.pump();
    expect(repo.confirms, hasLength(1));
    // It fails (offline): the proposal stays pending and can be tried again.
    repo.confirms.single.open(const Left(NetworkFailure()));
    await settle(tester);
    expect(find.text('Add 2 items to cart'), findsOneWidget);
    await unmount(tester);

    await pump(
      tester,
      const Scaffold(
        body: AssistantCardList(cards: [pendingProposal], live: true),
      ),
    );
    expect(
      find.text('You can add these once the reply finishes'),
      findsOneWidget,
    );
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(repo.confirms, hasLength(1));
    await unmount(tester);
  });

  testWidgets('composer: an over-long message is refused, a valid one sent', (
    tester,
  ) async {
    await pump(
      tester,
      const Scaffold(
        body: Column(
          children: [
            Expanded(child: SizedBox()),
            AssistantComposer(),
          ],
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'a' * 2001);
    await tester.pump();
    expect(find.textContaining('2001'), findsOneWidget);
    await tester.tap(find.byType(AssistantSendButton));
    await settle(tester);
    expect(
      find.text('Your message is too long. Keep it under 2000 characters.'),
      findsOneWidget,
    );
    expect(repo.sends, isEmpty);
    // The snack bar floats over the composer until it times out.
    await tester.pump(const Duration(seconds: 5));
    await settle(tester);

    await tester.enterText(find.byType(TextField), '  Hello there  ');
    await tester.pump();
    await tester.tap(find.byType(AssistantSendButton));
    await tester.pump();
    expect(repo.sends.single.message, 'Hello there');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
    expect(
      tester.getSemantics(find.byType(AssistantSendButton)),
      matchesSemantics(
        label: 'Stop',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    await unmount(tester);
  });

  testWidgets('welcome: a starter sends its full question, the reply lands', (
    tester,
  ) async {
    await pump(
      tester,
      const Scaffold(appBar: AssistantChatAppBar(), body: AssistantChatBody()),
    );

    expect(find.text('How can I help you shop today?'), findsOneWidget);
    await tester.tap(find.text("Today's offers"));
    await settle(tester);
    expect(repo.sends.single.message, 'What offers do you have today?');
    expect(find.text('What offers do you have today?'), findsOneWidget);

    repo.lastSend
      ..accept()
      ..complete(assistantReply('m1', 'Two offers are running today.'));
    await settle(tester);
    expect(find.textContaining('Two offers are running'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('a store with the assistant off says so', (tester) async {
    unawaited(availability.ensureLoaded());
    repo.availability.single.open(
      const Right(AssistantAvailability(enabled: false)),
    );
    await pump(tester, const Scaffold(body: AssistantChatBody()));

    expect(
      find.text("The assistant isn't available right now"),
      findsOneWidget,
    );
    expect(find.byType(AssistantComposer), findsNothing);
    await unmount(tester);
  });

  testWidgets('reduced motion: the welcome has nothing animating', (
    tester,
  ) async {
    await pump(
      tester,
      const Scaffold(appBar: AssistantChatAppBar(), body: AssistantChatBody()),
      reducedMotion: true,
    );
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    await unmount(tester);
  });

  testWidgets('history: grouped by day, a tap pops the conversation id', (
    tester,
  ) async {
    final router = await pump(tester, const Scaffold(body: SizedBox()));
    String? picked;
    unawaited(history.load());
    unawaited(
      router.push<String>(Routes.assistantHistory).then((id) => picked = id),
    );
    await settle(tester);
    final now = DateTime.now();
    repo.lists.single.open(
      Right(
        feedOf([
          AssistantConversationEntity(
            id: 'c1',
            title: 'Breakfast',
            lastMessageAt: now,
            lastMessagePreview: 'Eggs and bread',
          ),
          AssistantConversationEntity(
            id: 'c2',
            title: 'Old order',
            lastMessageAt: now.subtract(const Duration(days: 30)),
            status: AssistantConversationStatus.closed,
          ),
        ]),
      ),
    );
    await settle(tester);

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Earlier'), findsOneWidget);
    expect(find.text('Ended'), findsOneWidget);
    await tester.tap(find.text('Old order'));
    await settle(tester);
    expect(picked, 'c2');
    await unmount(tester);
  });

  testWidgets('Arabic: the thread reads right to left, nothing overflows', (
    tester,
  ) async {
    // A phone-sized view, so the reverse list builds the whole turn.
    tester.view
      ..physicalSize = const Size(1080, 2640)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // Loaded in setUpAll: real asset I/O never completes inside a widget
    // test's fake clock.
    Localization.load(const Locale('ar'), translations: Translations(arJson));
    addTearDown(
      () => Localization.load(
        const Locale('en'),
        translations: Translations(enJson),
      ),
    );
    unawaited(chat.loadThread('c1'));
    repo.threads.single.open(
      Right(
        threadOf([
          userMessage('u1', 'أضف بيض'),
          assistantReply(
            'm1',
            'إليك **الخيارات** المتاحة',
            blocks: [
              blocks.whereType<AssistantProductsBlock>().first,
              pendingProposal,
            ],
          ),
        ]),
      ),
    );
    await pump(
      tester,
      const Scaffold(body: AssistantChatBody()),
      locale: const Locale('ar'),
    );

    final error = tester.takeException();
    expect(
      error,
      isNull,
      reason: error is FlutterError ? error.toStringDeep() : '$error',
    );
    // The customer's bubble sits at the end — the LEFT in Arabic.
    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(tester.getCenter(find.text('أضف بيض')).dx, lessThan(width / 2));
    expect(find.textContaining('الخيارات', findRichText: true), findsWidgets);
    await unmount(tester);
  });

  testWidgets('largest text on a small phone: every card still fits', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(960, 1920)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pump(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: AssistantCardList(cards: AssistantCards.of(blocks)),
        ),
      ),
      textScaler: const TextScaler.linear(1.3),
    );
    final error = tester.takeException();
    expect(
      error,
      isNull,
      reason: error is FlutterError ? error.toStringDeep() : '$error',
    );
    await unmount(tester);
  });
}
