// The chat sheet's widgets: each bubble says who wrote it to a screen
// reader; the rider starting to type leaves the bubbles alone; a keyboard
// send while a message is on its way does nothing (not even the haptic)
// and the send button stays still; a quick reply that cannot be tapped
// does not dip and keeps a 48 dp hit box; the sheet folds its optional
// rows instead of overflowing in landscape with the keyboard up.
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/motion/press_scale.dart';
import 'package:hero_mart/src/core/responsive/app_size.dart';
import 'package:hero_mart/src/features/orders/domain/entities/rider_chat.dart';
import 'package:hero_mart/src/features/orders/domain/entities/rider_chat_message.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/rider_chat_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/rider_chat/rider_chat_bubble.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/rider_chat/rider_chat_composer.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/rider_chat/rider_chat_list.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/rider_chat/rider_chat_quick_replies.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/rider_chat/rider_chat_quick_reply_chip.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/rider_chat/rider_chat_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'live_map_test_fakes.dart';

final DateTime _t0 = DateTime.utc(2026, 9, 30, 12);

const String _vibrate = 'HapticFeedback.vibrate';

/// No translations at all: every text reads as its key, so a test can
/// tell which key a widget used.
class _KeysOnly extends AssetLoader {
  const _KeysOnly();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      <String, dynamic>{};
}

/// A message the customer sent at [at].
RiderChatMessage _customerSays(String id, DateTime at, {String text = 'Ok'}) =>
    RiderChatMessage(
      id: id,
      fromRider: false,
      sentAt: at,
      textEn: text,
      textAr: text,
    );

/// [child] at the bottom of a [size] screen, over [cubit].
Future<void> _pump(
  WidgetTester tester,
  RiderChatCubit cubit,
  Widget child, {
  Size size = const Size(400, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
        path: 'assets/i18n',
        assetLoader: const _KeysOnly(),
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: BlocProvider<RiderChatCubit>.value(
              value: cubit,
              child: Material(
                child: Align(alignment: Alignment.bottomCenter, child: child),
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  });
  await tester.pump();
}

/// Counts the haptics fired from here on.
List<Object?> _recordHaptics(WidgetTester tester) {
  final calls = <Object?>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == _vibrate) calls.add(call.arguments);
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
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  late FakeRiderChatRepository repository;
  late RiderChatCubit cubit;

  /// The chat of order o1 — started in the test's own zone, so the
  /// conversation's events reach the widgets on the next pump.
  void startChat() {
    repository = FakeRiderChatRepository();
    cubit = buildRiderChatCubit(repository)..start('o1');
    addTearDown(() async {
      final gate = repository.gate;
      if (gate != null && !gate.isCompleted) gate.complete();
      await cubit.close();
    });
  }

  Future<void> push(WidgetTester tester, RiderChat chat) async {
    repository.push(chat);
    await tester.pump();
  }

  group('RiderChatBubble', () {
    testWidgets('a screen reader hears who said it first', (tester) async {
      startChat();
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        cubit,
        const SizedBox(height: 600, child: RiderChatList()),
      );
      await push(
        tester,
        RiderChat(
          messages: [
            riderSays('m1', _t0, text: 'Hi'),
            _customerSays('m2', _t0.add(const Duration(minutes: 1))),
          ],
        ),
      );
      await tester.pumpAndSettle();

      String labelOf(String text) => tester
          .getSemantics(
            find
                .ancestor(
                  of: find.text(text),
                  matching: find.byType(MergeSemantics),
                )
                .first,
          )
          // The merge boundary itself: what a screen reader hears, its
          // merged children included.
          .getSemanticsData()
          .label;

      expect(labelOf('Hi'), startsWith('orders.chat_rider_said'));
      expect(labelOf('Hi'), contains('Hi'));
      expect(labelOf('Ok'), startsWith('orders.chat_you_said'));
      semantics.dispose();
    });
  });

  group('RiderChatList', () {
    testWidgets('the rider typing leaves the bubbles alone', (tester) async {
      startChat();
      await _pump(
        tester,
        cubit,
        const SizedBox(height: 600, child: RiderChatList()),
      );
      final first = riderSays('m1', _t0, text: 'Hi');
      final second = _customerSays('m2', _t0.add(const Duration(minutes: 1)));
      await push(tester, RiderChat(messages: [first, second]));
      await tester.pumpAndSettle();
      RiderChatBubble bubble() =>
          tester.widget<RiderChatBubble>(find.byKey(const ValueKey('m1')));
      final before = bubble();

      // The same messages in a new list, with the rider typing.
      await push(
        tester,
        RiderChat(messages: [first, second], riderTyping: true),
      );
      expect(identical(bubble(), before), isTrue);

      // A new message does rebuild them.
      await push(
        tester,
        RiderChat(
          messages: [
            first,
            second,
            riderSays('m3', _t0.add(const Duration(minutes: 2))),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(identical(bubble(), before), isFalse);
      expect(find.byType(RiderChatBubble), findsNWidgets(3));
    });
  });

  group('RiderChatComposer', () {
    testWidgets('a keyboard send while a message is on its way does nothing', (
      tester,
    ) async {
      startChat();
      repository.gate = Completer<void>();
      await _pump(tester, cubit, const RiderChatComposer());
      final haptics = _recordHaptics(tester);

      await tester.enterText(find.byType(TextField), 'On my way down');
      await tester.pump();
      await tester.tap(find.byType(PressScale));
      await tester.pump();

      expect(cubit.state.sending, isTrue);
      expect(
        tester.widget<PressScale>(find.byType(PressScale)).enabled,
        isFalse,
      );
      final firedForTheTap = haptics.length;

      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      expect(haptics, hasLength(firedForTheTap));

      repository.gate!.complete();
      await tester.pump();
      await tester.pump();

      expect(repository.sent.map((sent) => sent.$2), ['On my way down']);
      expect(cubit.state.sending, isFalse);
    });

    testWidgets('the send button\'s hit box is 48 dp', (tester) async {
      startChat();
      await _pump(tester, cubit, const RiderChatComposer());

      expect(
        tester.getSize(find.byType(PressScale)),
        const Size.square(AppSize.s48),
      );
    });
  });

  group('RiderChatQuickReplyChip', () {
    testWidgets(
      'while a message is on its way a chip fades, does not dip, and keeps '
      'a 48 dp hit box',
      (tester) async {
        startChat();
        repository.gate = Completer<void>();
        await _pump(tester, cubit, const RiderChatQuickReplies());
        unawaited(cubit.send('Hi'));
        await tester.pump();
        await tester.pump(AppMotion.fast);

        final chip = find.byType(RiderChatQuickReplyChip).first;
        final press = find.descendant(
          of: chip,
          matching: find.byType(PressScale),
        );
        expect(tester.widget<RiderChatQuickReplyChip>(chip).onPressed, isNull);
        expect(tester.widget<PressScale>(press).enabled, isFalse);
        expect(tester.getSize(press).height, AppSize.s48);
        expect(
          tester
              .widget<AnimatedOpacity>(
                find.descendant(
                  of: chip,
                  matching: find.byType(AnimatedOpacity),
                ),
              )
              .opacity,
          lessThan(1),
        );

        final finger = await tester.startGesture(tester.getCenter(chip));
        await tester.pump(AppMotion.microPop);
        expect(
          tester
              .widget<AnimatedScale>(
                find.descendant(
                  of: press,
                  matching: find.byType(AnimatedScale),
                ),
              )
              .scale,
          1,
        );
        await finger.up();
        await tester.pump();

        expect(repository.sent, isEmpty);
      },
    );
  });

  group('RiderChatSheet', () {
    testWidgets(
      'landscape with the keyboard up folds the optional rows, no overflow',
      (tester) async {
        startChat();
        tester.view.viewInsets = const FakeViewPadding(bottom: 200);
        await _pump(
          tester,
          cubit,
          const RiderChatSheet(riderName: 'Ali'),
          size: const Size(800, 411),
        );
        await push(tester, RiderChat(messages: [riderSays('m1', _t0)]));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(RiderChatQuickReplies), findsNothing);
        expect(find.text('orders.chat_translated'), findsNothing);
        expect(find.byType(RiderChatComposer), findsOneWidget);
      },
    );

    testWidgets('portrait keeps every row', (tester) async {
      startChat();
      await _pump(tester, cubit, const RiderChatSheet(riderName: 'Ali'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(RiderChatQuickReplies), findsOneWidget);
      expect(find.text('orders.chat_translated'), findsOneWidget);
    });
  });
}
