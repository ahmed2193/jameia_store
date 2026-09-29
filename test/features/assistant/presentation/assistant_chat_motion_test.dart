// The chat's motion (docs/motion §9.6 §2.2–§2.10, B1-13 part 2): the
// stream's words arrive evenly over the next flush window and fade in (the
// network mode of the word reveal; reduced motion = whole at once, the caret
// gone at once), a reply faster than the loader delay never flashes dots, a
// confirmed proposal flies to the cart and ticks on the landing (no
// confetti), a spent proposal mutes by colour with no haptic and no opacity
// layer, the thumbs tick once per tap and say thanks beside themselves, and
// a reply that failed mid-stream keeps its words and retries in place.
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
import 'package:hero_mart/src/config/di/service_locator.dart';
import 'package:hero_mart/src/config/theme/app_theme.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/motion/confetti_burst.dart';
import 'package:hero_mart/src/core/motion/fly_to_cart.dart';
import 'package:hero_mart/src/core/motion/haptics.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_action_result.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_block.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_message_entity.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_rich_text.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_stream_event.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_availability_cubit.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_chat_cubit.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_chat_state.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_voice_cubit.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/assistant_motion.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/assistant_stream_pace.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/blocks/assistant_card_list.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/blocks/assistant_cart_action_card.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/chat/assistant_chat_body.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/chat/assistant_message_actions.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/chat/assistant_streaming_caret.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/chat/assistant_text_bubble.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/chat/assistant_thinking_bubble.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hero_mart/src/features/language/presentation/cubit/localization_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'assistant_test_fakes.dart';
import 'assistant_voice_fakes.dart';

const String _click = 'HapticFeedbackType.selectionClick';

List<String?> _recordHaptics(WidgetTester tester) {
  final calls = <String?>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String?);
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
  return calls;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await setupServiceLocator();
    final enJson = json.decode(
      await rootBundle.loadString('assets/i18n/en.json'),
    ) as Map<String, dynamic>;
    Localization.load(const Locale('en'), translations: Translations(enJson));
  });

  late FakeAssistantRepository repo;
  late AssistantChatCubit chat;
  late AssistantAvailabilityCubit availability;
  late AssistantVoiceCubit voice;

  setUp(() {
    Haptics.debugReset();
    repo = FakeAssistantRepository();
    chat = chatCubit(repo);
    availability = availabilityCubit(repo);
    voice = voiceCubit(FakeVoiceRepository());
  });

  tearDown(() async {
    await chat.close();
    await availability.close();
    await voice.close();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pump(
    WidgetTester tester,
    Widget body, {
    bool reducedMotion = false,
  }) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
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
          child: MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: const MediaQueryData(size: Size(400, 800))
                  .copyWith(disableAnimations: reducedMotion),
              child: Scaffold(body: body),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  group('the stream pace (network mode)', () {
    test('a flush is released evenly over the next window', () {
      final pace = AssistantStreamPace()..reveal(5, Duration.zero);
      const step = Duration(milliseconds: 10); // 50 ms / 5 words
      for (var i = 0; i < 5; i++) {
        expect(pace.alphaAt(i, step * i), 0, reason: 'word $i starts');
        expect(pace.alphaAt(i, step * i + AppMotion.fast), 1);
      }
      expect(pace.settledAt(step * 4 + AppMotion.fast), isTrue);
      expect(pace.settledAt(step * 4), isFalse);
    });

    test('a flush that lands while words wait queues after them', () {
      final pace = AssistantStreamPace()
        ..reveal(2, Duration.zero) // starts 0, 25
        ..reveal(4, Duration.zero); // starts 50, 75
      expect(pace.alphaAt(2, const Duration(milliseconds: 49)), 0);
      expect(pace.alphaAt(2, const Duration(milliseconds: 50)), 0);
      expect(pace.alphaAt(3, const Duration(milliseconds: 75)), 0);
      expect(pace.alphaAt(3, const Duration(milliseconds: 76)), greaterThan(0));
    });

    test('never more than the lag limit behind: a burst comes in one fade', () {
      final pace = AssistantStreamPace();
      for (var words = 1; words <= 20; words++) {
        pace.reveal(words, Duration.zero); // each one waits a window more
      }
      // Twenty windows would be 1 s behind: everything waiting starts now.
      for (var i = 0; i < 20; i++) {
        expect(pace.alphaAt(i, AppMotion.fast), 1, reason: 'word $i');
      }
      expect(
        AssistantMotion.streamFlush * 20,
        greaterThan(AssistantMotion.streamMaxLag),
      );
    });

    test('the stream ending releases the rest at once', () {
      final pace = AssistantStreamPace()..reveal(10, Duration.zero);
      pace.finish(Duration.zero);
      expect(pace.settledAt(AppMotion.fast), isTrue);
    });

    test('reduced motion: every word is whole the moment it is known', () {
      final pace = AssistantStreamPace(immediate: true)
        ..reveal(3, Duration.zero);
      expect(pace.settledAt(Duration.zero), isTrue);
      expect(pace.alphaAt(2, Duration.zero), 1);
    });
  });

  group('the streamed reply', () {
    AssistantRichText text(String source) => AssistantRichText.parse(source);

    /// The alpha of every word span of the reply's text (a plain run: 1).
    List<double> alphas(WidgetTester tester) {
      final rich = tester.widget<Text>(
        find.descendant(
          of: find.byType(AssistantTextBubble),
          matching: find.byType(Text),
        ),
      );
      final values = <double>[];
      rich.textSpan!.visitChildren((span) {
        if (span is TextSpan && span.text != null) {
          values.add(span.style?.color?.a ?? 1);
        }
        return true;
      });
      return values;
    }

    Widget bubble(AssistantRichText richText, {required bool streaming}) =>
        AssistantTextBubble(richText: richText, streaming: streaming);

    testWidgets('new words fade in, the caret fades out when it ends', (
      tester,
    ) async {
      await pump(tester, bubble(text('Two offers'), streaming: true));
      await tester.pump(const Duration(milliseconds: 200));
      expect(alphas(tester).every((alpha) => alpha == 1), isTrue);

      await pump(
        tester,
        bubble(text('Two offers are running today'), streaming: true),
      );
      await tester.pump(const Duration(milliseconds: 20));
      expect(
        alphas(tester).any((alpha) => alpha < 1),
        isTrue,
        reason: 'the new words are still fading in',
      );
      expect(find.textContaining('running today'), findsOneWidget);

      await pump(
        tester,
        bubble(text('Two offers are running today'), streaming: false),
      );
      expect(find.byType(AssistantStreamingCaret), findsOneWidget);
      await tester.pump(AppMotion.fast + const Duration(milliseconds: 50));
      await tester.pump();
      expect(find.byType(AssistantStreamingCaret), findsNothing);
      expect(alphas(tester).every((alpha) => alpha == 1), isTrue);
      await unmount(tester);
    });

    testWidgets('reduced motion: the full text at once, the caret gone at '
        'once', (tester) async {
      await pump(
        tester,
        bubble(text('Two offers'), streaming: true),
        reducedMotion: true,
      );
      await pump(
        tester,
        bubble(text('Two offers are running today'), streaming: true),
        reducedMotion: true,
      );
      await tester.pump();
      expect(alphas(tester).every((alpha) => alpha == 1), isTrue);
      expect(find.textContaining('running today'), findsOneWidget);

      await pump(
        tester,
        bubble(text('Two offers are running today'), streaming: false),
        reducedMotion: true,
      );
      await tester.pump();
      expect(find.byType(AssistantStreamingCaret), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
      await unmount(tester);
    });

    testWidgets('a stored reply is plain text with no clock', (tester) async {
      await pump(tester, bubble(text('Hello there'), streaming: false));
      expect(alphas(tester).every((alpha) => alpha == 1), isTrue);
      expect(tester.hasRunningAnimations, isFalse);
      await unmount(tester);
    });
  });

  group('the reply row', () {
    testWidgets('a reply faster than the loader delay never shows the dots', (
      tester,
    ) async {
      await pump(tester, const AssistantChatBody());
      chat.send('hi');
      await tester.pump();
      repo.lastSend
        ..accept()
        ..add(const AssistantStreamTextDelta(delta: 'Hello there, '));
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.byType(AssistantThinkingBubble), findsNothing);
      await tester.pump(AppMotion.loaderDelay);
      expect(find.byType(AssistantThinkingBubble), findsNothing);
      expect(find.textContaining('Hello there'), findsOneWidget);
      repo.lastSend.complete(assistantReply('m1', 'Hello there, friend.'));
      await settle(tester);
      await unmount(tester);
    });

    testWidgets('the thinking row waits the loader delay, then shows', (
      tester,
    ) async {
      await pump(tester, const AssistantChatBody());
      chat.send('hi');
      await tester.pump();
      repo.lastSend.accept();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AssistantThinkingBubble), findsNothing);
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.byType(AssistantThinkingBubble), findsOneWidget);
      expect(find.text('Thinking'), findsOneWidget);
      repo.lastSend.complete(assistantReply('m1', 'Done.'));
      await settle(tester);
      await unmount(tester);
    });

    testWidgets('a reply cut mid-stream keeps its words; Retry answers in '
        'the same row, no second bubble', (tester) async {
      await pump(tester, const AssistantChatBody());
      chat.send('hi');
      await tester.pump();
      repo.lastSend
        ..accept()
        ..add(const AssistantStreamTextDelta(delta: 'Partial answer here '));
      await settle(tester);
      repo.lastSend.add(
        const AssistantStreamFailed(code: 'X', message: 'Something broke'),
      );
      await settle(tester);
      expect(find.textContaining('Partial answer'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byType(AssistantStreamingCaret), findsNothing);
      final failedKey = chat.state.thread.lastKey;

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(repo.sends, hasLength(2));
      expect(chat.state.liveTurn?.key, failedKey, reason: 'same row');
      await tester.pump(AppMotion.fast);
      // Back to the thinking bubble in place — no loader delay, no entrance.
      expect(find.byType(AssistantThinkingBubble), findsOneWidget);
      expect(find.text('hi'), findsOneWidget, reason: 'one user bubble');
      await settle(tester);
      expect(find.text('Retry'), findsNothing, reason: 'the footer folded');
      repo.lastSend
        ..accept()
        ..complete(assistantReply('m1', 'All good now.'));
      await settle(tester);
      expect(find.textContaining('All good now'), findsOneWidget);
      await unmount(tester);
    });
  });

  group('a cart proposal', () {
    final cart = GlobalKey();

    Widget proposalScene() => Column(
      children: [
        SizedBox(key: cart, width: 40, height: 40),
        Expanded(
          child: SingleChildScrollView(
            child:
                BlocSelector<
                  AssistantChatCubit,
                  AssistantChatState,
                  AssistantCartActionBlock?
                >(
                  selector: (state) => state.thread.cartAction('act-1'),
                  builder: (context, block) => block == null
                      ? const SizedBox.shrink()
                      : AssistantCardList(cards: [block]),
                ),
          ),
        ),
      ],
    );

    Future<void> openProposal(WidgetTester tester, {bool reduced = false}) {
      unawaited(chat.loadThread('c1'));
      repo.threads.single.open(
        Right(
          threadOf([
            userMessage('u1', 'add eggs'),
            assistantReply('m1', 'Here you go', blocks: [pendingProposal]),
          ]),
        ),
      );
      return pump(tester, proposalScene(), reducedMotion: reduced);
    }

    setUp(() => FlyToCart.pushTarget(cart));
    tearDown(() => FlyToCart.popTarget(cart));

    testWidgets('confirmed: the line flies to the cart and the add ticks on '
        'the landing — no confetti', (tester) async {
      final haptics = _recordHaptics(tester);
      await openProposal(tester);
      await tester.pump();
      await tester.tap(find.text('Add 2 items to cart'));
      await tester.pump();
      haptics.clear(); // the button's own commit tap
      repo.confirms.single.open(
        Right(
          AssistantActionResult(
            message: 'Added to your cart',
            blocks: [
              pendingProposal.withStatus(AssistantActionStatus.confirmed),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(FlyToCart.airborne, 1, reason: 'one line, one thumbnail');
      expect(haptics, isEmpty, reason: 'nothing until it lands');
      await tester.pump(AppMotion.slow + const Duration(milliseconds: 50));
      expect(FlyToCart.airborne, 0);
      expect(haptics, [_click]);
      expect(find.byType(ConfettiBurst), findsNothing);
      expect(find.text('Added to your cart'), findsOneWidget);
      await settle(tester);
      await unmount(tester);
    });

    testWidgets('reduced motion: no flight, the add ticks at once', (
      tester,
    ) async {
      final haptics = _recordHaptics(tester);
      await openProposal(tester, reduced: true);
      await tester.pump();
      await tester.tap(find.text('Add 2 items to cart'));
      await tester.pump();
      haptics.clear();
      repo.confirms.single.open(
        Right(
          AssistantActionResult(
            blocks: [
              pendingProposal.withStatus(AssistantActionStatus.confirmed),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(FlyToCart.airborne, 0);
      expect(haptics, [_click]);
      await unmount(tester);
    });

    testWidgets('spent (expired): muted by colour, no opacity layer, no '
        'haptic', (tester) async {
      final haptics = _recordHaptics(tester);
      await openProposal(tester);
      await tester.pump();
      await tester.tap(find.text('Add 2 items to cart'));
      await tester.pump();
      haptics.clear();
      repo.confirms.single.open(const Left(NotFoundFailure('gone')));
      await settle(tester);
      expect(
        find.text('This suggestion is no longer available'),
        findsOneWidget,
      );
      expect(find.text('Add 2 items to cart'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(AssistantCartActionCard),
          matching: find.byWidgetPredicate(
            (widget) => widget is Opacity || widget is AnimatedOpacity,
          ),
        ),
        findsNothing,
      );
      expect(haptics, isEmpty);
      await unmount(tester);
    });

    testWidgets('a confirm the server refused says why under the button', (
      tester,
    ) async {
      await openProposal(tester);
      await tester.pump();
      await tester.tap(find.text('Add 2 items to cart'));
      await tester.pump();
      repo.confirms.single.open(
        const Left(ServerFailure('Out of stock', statusCode: 409)),
      );
      await settle(tester);
      expect(find.text('Out of stock'), findsOneWidget);
      expect(find.text('Add 2 items to cart'), findsOneWidget);

      // Tried again: the line folds away while it goes.
      await tester.tap(find.text('Add 2 items to cart'));
      await settle(tester);
      expect(find.text('Out of stock'), findsNothing);
      await unmount(tester);
    });
  });

  group('the thumbs', () {
    Future<void> openRated(WidgetTester tester) async {
      unawaited(chat.loadThread('c1'));
      repo.threads.single.open(
        Right(
          threadOf([userMessage('u1', 'hi'), assistantReply('m1', 'Hello')]),
        ),
      );
      await tester.pump();
      await pump(
        tester,
        BlocSelector<
          AssistantChatCubit,
          AssistantChatState,
          AssistantMessageEntity?
        >(
          selector: (state) => state.thread.messageById('m1'),
          builder: (context, message) => message == null
              ? const SizedBox.shrink()
              : AssistantMessageActions(message: message),
        ),
      );
      await tester.pump();
    }

    testWidgets('one tick per tap; "Thanks!" beside them, then gone', (
      tester,
    ) async {
      final haptics = _recordHaptics(tester);
      await openRated(tester);
      await tester.tap(find.byTooltip('Helpful'));
      await tester.pump();
      expect(haptics, [_click]);
      expect(
        chat.state.thread.messageById('m1')?.feedback,
        AssistantFeedback.up,
      );
      await tester.pump(AppMotion.fast);
      expect(find.text('Thanks!'), findsOneWidget);
      repo.ratings.single.open(const Right(unit));
      await tester.pump(AppMotion.snackDwell);
      await tester.pump(AppMotion.fast);
      await tester.pump(AppMotion.fast);
      expect(find.text('Thanks!'), findsNothing);

      // Un-rating: one tick, no thanks.
      await tester.tap(find.byTooltip('Helpful'));
      await tester.pump();
      expect(haptics, [_click, _click]);
      await tester.pump(AppMotion.fast);
      expect(find.text('Thanks!'), findsNothing);
      await settle(tester);
      await unmount(tester);
    });
  });
}
