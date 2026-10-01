// The composer's mic over real widgets and real gestures, WhatsApp style:
// the empty box offers the mic and typing turns it into send; holding
// records (hold bar, timer, lock, live words) and letting go sends what was
// heard; the language beside the live words switches mid-recording and is
// kept; sliding toward the start cancels (the bin plays) — right in
// Arabic; sliding up locks (hands-free controls, the mic becomes send) and
// stop puts the words in the box; a page opening over the chat stops the
// recording (words kept, no keyboard over that page) and the chat closing
// drops it; words the chat cannot take wait in the box; a mere tap shows
// how to record; a blocked microphone offers the settings; no recognizer,
// no mic; reduced motion leaves nothing animating.
//
// The chat and voice cubits run over scripted repositories; nothing here
// reaches DI, the network or the device's recognizer.
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
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/config/theme/app_theme.dart';
import 'package:hero_mart/src/core/design/hero_icons.dart';
import 'package:hero_mart/src/core/navigation/route_observer.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_voice_access.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_voice_event.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_voice_language.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_voice_policy.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_chat_cubit.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_voice_cubit.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_voice_state.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/composer/assistant_composer.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/composer/assistant_send_button.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/voice/assistant_voice_discard.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/voice/assistant_voice_hold_bar.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/voice/assistant_voice_language_switch.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/voice/assistant_voice_lock_pill.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/voice/assistant_voice_locked_controls.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/voice/assistant_voice_locked_panel.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/voice/assistant_voice_mic_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'assistant_test_fakes.dart';
import 'assistant_voice_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> enJson;
  late Map<String, dynamic> arJson;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    enJson = json.decode(
      await rootBundle.loadString('assets/i18n/en.json'),
    ) as Map<String, dynamic>;
    arJson = json.decode(
      await rootBundle.loadString('assets/i18n/ar.json'),
    ) as Map<String, dynamic>;
    Localization.load(const Locale('en'), translations: Translations(enJson));
  });

  late FakeAssistantRepository chatRepo;
  late FakeVoiceRepository voiceRepo;
  late AssistantChatCubit chat;
  late AssistantVoiceCubit voice;

  setUp(() {
    chatRepo = FakeAssistantRepository();
    voiceRepo = FakeVoiceRepository();
    chat = chatCubit(chatRepo);
    // The real timings: the clock is fake in a widget test.
    voice = voiceCubit(
      voiceRepo,
      policy: const AssistantVoicePolicy(),
      tick: AssistantVoiceCubit.defaultTick,
    );
  });

  tearDown(() async {
    await chat.close();
    await voice.close();
  });

  Finder mic() => find.byType(AssistantVoiceMicButton);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    bool reducedMotion = false,
  }) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: locale,
        saveLocale: false,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AssistantChatCubit>.value(value: chat),
            BlocProvider<AssistantVoiceCubit>.value(value: voice),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            navigatorObservers: [routeObserver],
            home: MediaQuery(
              data: const MediaQueryData(size: Size(390, 844))
                  .copyWith(disableAnimations: reducedMotion),
              child: Directionality(
                textDirection: locale.languageCode == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: const Scaffold(
                  body: Column(
                    children: [
                      Expanded(child: SizedBox()),
                      AssistantComposer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  /// Presses the mic and holds past a mere tap.
  Future<TestGesture> hold(WidgetTester tester) async {
    final gesture = await tester.startGesture(tester.getCenter(mic()));
    await tester.pump();
    await tester.pump(AssistantVoicePolicy.defaultAccidentalTap);
    await tester.pump(const Duration(milliseconds: 100));
    return gesture;
  }

  /// What a screen reader's double tap on the mic does.
  void screenReaderTap(WidgetTester tester) => tester
      .widget<Semantics>(
        find.descendant(of: mic(), matching: find.byType(Semantics)).first,
      )
      .properties
      .onTap!();

  testWidgets('the empty box offers the mic; typing turns it into send', (
    tester,
  ) async {
    await pump(tester);
    expect(mic(), findsOneWidget);
    expect(find.byType(AssistantSendButton), findsNothing);

    await tester.enterText(find.byType(TextField), 'milk');
    await settle(tester);
    expect(find.byType(AssistantSendButton), findsOneWidget);
    expect(mic(), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await settle(tester);
    expect(mic(), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('holding records — hold bar, timer, lock, live words — and '
      'letting go sends what was heard', (tester) async {
    await pump(tester);
    final gesture = await hold(tester);
    expect(voice.state.phase, AssistantVoicePhase.holding);
    expect(find.byType(AssistantVoiceHoldBar), findsOneWidget);
    expect(find.byType(AssistantVoiceLockPill), findsOneWidget);
    expect(find.text('Slide to cancel'), findsOneWidget);
    expect(find.text('Listening…'), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);
    expect(
      find.textContaining('Hold to record, release to send'),
      findsNothing,
    );
    expect(voiceRepo.languages, ['en']);

    voiceRepo.take.add(const AssistantVoiceHeard('milk and eggs'));
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text('milk and eggs'), findsOneWidget);
    expect(find.text('0:01'), findsOneWidget);

    await gesture.up();
    await tester.pump();
    expect(voice.state.phase, AssistantVoicePhase.sending);
    expect(voiceRepo.finishes, 1);

    voiceRepo.take.add(const AssistantVoiceDone('milk and eggs'));
    await settle(tester);
    expect(chatRepo.sends.single.message, 'milk and eggs');
    expect(find.byType(AssistantVoiceHoldBar), findsNothing);
    await unmount(tester);
  });

  testWidgets('the language beside the live words: a tap (a second finger) '
      'listens in the other one — the wrong words go, the recording goes '
      'on — and the choice is kept', (tester) async {
    await pump(tester);
    final gesture = await hold(tester);
    expect(
      find.widgetWithText(AssistantVoiceLanguageSwitch, 'English'),
      findsOneWidget,
    );
    voiceRepo.take.add(const AssistantVoiceHeard('and a bee halib'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('and a bee halib'), findsOneWidget);

    await tester.tap(find.byType(AssistantVoiceLanguageSwitch));
    await tester.pump(const Duration(milliseconds: 200));
    expect(voiceRepo.languages, ['en', 'ar']);
    expect(voiceRepo.savedLanguages, [AssistantVoiceLanguage.arabic]);
    expect(
      find.widgetWithText(AssistantVoiceLanguageSwitch, 'العربية'),
      findsOneWidget,
    );
    expect(find.text('and a bee halib'), findsNothing);
    expect(voice.state.phase, AssistantVoicePhase.holding);

    voiceRepo.take.add(const AssistantVoiceHeard('أبي حليب'));
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.up();
    await tester.pump();
    voiceRepo.take.add(const AssistantVoiceDone('أبي حليب'));
    await settle(tester);
    expect(chatRepo.sends.single.message, 'أبي حليب');
    expect(find.byType(AssistantVoiceLanguageSwitch), findsNothing);
    await unmount(tester);
  });

  testWidgets('sliding toward the start cancels: the bin plays, nothing is '
      'sent', (tester) async {
    await pump(tester);
    final gesture = await hold(tester);
    await gesture.moveBy(const Offset(-70, 0));
    await tester.pump();
    expect(voice.state.phase, AssistantVoicePhase.holding);
    await gesture.moveBy(const Offset(-70, 0));
    await tester.pump();
    expect(voice.state.phase, AssistantVoicePhase.idle);
    expect(find.byType(AssistantVoiceDiscard), findsOneWidget);
    expect(voiceRepo.cancels, 1);

    await gesture.up();
    await tester.pump(AssistantVoiceDiscard.duration);
    await settle(tester);
    expect(find.byType(AssistantVoiceDiscard), findsNothing);
    expect(chatRepo.sends, isEmpty);
    expect(voiceRepo.finishes, 0);
    await unmount(tester);
  });

  testWidgets('Arabic: sliding right cancels', (tester) async {
    Localization.load(const Locale('ar'), translations: Translations(arJson));
    addTearDown(
      () => Localization.load(
        const Locale('en'),
        translations: Translations(enJson),
      ),
    );
    await pump(tester, locale: const Locale('ar'));
    final gesture = await hold(tester);
    expect(voiceRepo.languages, ['ar']);
    expect(find.text('اسحب للإلغاء'), findsOneWidget);
    expect(
      find.widgetWithText(AssistantVoiceLanguageSwitch, 'العربية'),
      findsOneWidget,
    );
    // Toward the end of an Arabic line: nothing.
    await gesture.moveBy(const Offset(-140, 0));
    await tester.pump();
    expect(voice.state.phase, AssistantVoicePhase.holding);
    await gesture.moveBy(const Offset(280, 0));
    await tester.pump();
    expect(voice.state.notice, AssistantVoiceNotice.discarded);
    await gesture.up();
    await tester.pump(AssistantVoiceDiscard.duration);
    await settle(tester);
    await unmount(tester);
  });

  testWidgets('sliding up locks: hands-free controls, the mic becomes send', (
    tester,
  ) async {
    await pump(tester);
    final gesture = await hold(tester);
    await gesture.moveBy(const Offset(0, -100));
    await tester.pump();
    expect(voice.state.phase, AssistantVoicePhase.locked);
    await gesture.up();
    await settle(tester);
    expect(voice.state.phase, AssistantVoicePhase.locked);
    expect(find.byType(AssistantVoiceLockedControls), findsOneWidget);
    expect(find.byType(AssistantVoiceLockedPanel), findsOneWidget);
    expect(find.byType(AssistantVoiceLockPill), findsNothing);
    expect(find.byIcon(HeroIcons.arrowUp), findsOneWidget);

    await tester.tap(mic());
    await tester.pump();
    expect(voice.state.phase, AssistantVoicePhase.sending);
    voiceRepo.take.add(const AssistantVoiceDone('rice'));
    await settle(tester);
    expect(chatRepo.sends.single.message, 'rice');
    await unmount(tester);
  });

  testWidgets('stop in hands-free puts the words in the box to read over', (
    tester,
  ) async {
    await pump(tester);
    final gesture = await hold(tester);
    await gesture.moveBy(const Offset(0, -100));
    await gesture.up();
    await settle(tester);

    await tester.tap(find.byTooltip('Stop and edit'));
    await tester.pump();
    expect(voice.state.phase, AssistantVoicePhase.stopping);
    voiceRepo.take.add(const AssistantVoiceDone('eggs and bread'));
    await settle(tester);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'eggs and bread',
    );
    expect(chatRepo.sends, isEmpty);
    expect(find.byType(AssistantSendButton), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a page opening over the chat stops a hands-free recording: '
      'the words wait in the box, no keyboard over that page', (tester) async {
    await pump(tester);
    final gesture = await hold(tester);
    await gesture.moveBy(const Offset(0, -100));
    await gesture.up();
    await settle(tester);
    voiceRepo.take.add(const AssistantVoiceHeard('two lemons'));
    await tester.pump();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('product')),
        ),
      ),
    );
    await tester.pump();
    expect(voice.state.phase, AssistantVoicePhase.stopping);
    expect(voiceRepo.finishes, 1);

    voiceRepo.take.add(const AssistantVoiceDone('two lemons'));
    await settle(tester);
    final field = tester.widget<TextField>(
      find.byType(TextField, skipOffstage: false),
    );
    expect(field.controller!.text, 'two lemons');
    expect(field.focusNode!.hasFocus, isFalse);
    expect(chatRepo.sends, isEmpty);

    navigator.pop();
    await settle(tester);
    await unmount(tester);
  });

  testWidgets('the chat closing mid-recording drops it', (tester) async {
    await pump(tester);
    final gesture = await hold(tester);
    expect(voice.state.phase, AssistantVoicePhase.holding);
    await unmount(tester);
    expect(voice.state.phase, AssistantVoicePhase.idle);
    expect(voiceRepo.cancels, 1);
    expect(voiceRepo.finishes, 0);
    await gesture.up();
  });

  testWidgets('spoken words the chat cannot take wait in the box', (
    tester,
  ) async {
    await pump(tester);
    final gesture = await hold(tester);
    await gesture.up();
    await tester.pump();
    final tooLong = ('milk ' * 401).trim();
    voiceRepo.take.add(AssistantVoiceDone(tooLong));
    await settle(tester);
    expect(chatRepo.sends, isEmpty);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      tooLong,
    );
    await tester.pump(const Duration(seconds: 4));
    await unmount(tester);
  });

  testWidgets('the bin in hands-free drops the recording', (tester) async {
    await pump(tester);
    final gesture = await hold(tester);
    await gesture.moveBy(const Offset(0, -100));
    await gesture.up();
    await settle(tester);

    await tester.tap(find.byTooltip('Delete recording'));
    await tester.pump();
    expect(voice.state.phase, AssistantVoicePhase.idle);
    expect(voiceRepo.cancels, 1);
    await tester.pump(AssistantVoiceDiscard.duration);
    await settle(tester);
    expect(mic(), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a mere tap shows how to record', (tester) async {
    await pump(tester);
    await tester.tap(mic());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(voice.state.notice, AssistantVoiceNotice.tooShort);
    expect(
      find.textContaining('Hold to record, release to send'),
      findsOneWidget,
    );
    expect(voiceRepo.cancels, 1);
    await tester.pump(const Duration(seconds: 3));
    await unmount(tester);
  });

  testWidgets('a blocked microphone offers the settings', (tester) async {
    voiceRepo.access = const Right(AssistantVoiceAccess.blocked);
    await pump(tester);
    final gesture = await hold(tester);
    await gesture.up();
    await settle(tester);
    expect(find.text('Allow the microphone'), findsOneWidget);

    await tester.tap(find.text('Open settings'));
    await settle(tester);
    expect(voiceRepo.settingsOpened, 1);
    expect(find.text('Allow the microphone'), findsNothing);
    await unmount(tester);
  });

  testWidgets('a device with no recognizer shows no mic', (tester) async {
    voiceRepo.prepared = AssistantVoiceAccess.unavailable;
    await voice.prepare();
    await pump(tester);
    expect(mic(), findsNothing);
    expect(find.byType(AssistantSendButton), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('reduced motion: holding and locking animate nothing', (
    tester,
  ) async {
    await pump(tester, reducedMotion: true);
    final gesture = await hold(tester);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    await gesture.moveBy(const Offset(0, -100));
    await gesture.up();
    await tester.pump();
    await tester.pump();
    expect(voice.state.phase, AssistantVoicePhase.locked);
    expect(tester.hasRunningAnimations, isFalse);

    await tester.tap(find.byTooltip('Delete recording'));
    await tester.pump();
    expect(find.byType(AssistantVoiceDiscard), findsNothing);
    await unmount(tester);
  });

  testWidgets('screen readers get a button that records hands-free', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    expect(
      tester.getSemantics(mic()),
      matchesSemantics(
        label: 'Voice message',
        hint: 'Double tap to talk hands-free',
        isButton: true,
        hasTapAction: true,
      ),
    );
    screenReaderTap(tester);
    // The state reaches the widgets in a microtask: pump a real frame.
    await tester.pump(const Duration(milliseconds: 16));
    expect(voice.state.phase, AssistantVoicePhase.locked);
    expect(
      tester.getSemantics(mic()),
      matchesSemantics(label: 'Send', isButton: true, hasTapAction: true),
    );

    screenReaderTap(tester);
    // The state reaches the widgets in a microtask: pump a real frame.
    await tester.pump(const Duration(milliseconds: 16));
    expect(voice.state.phase, AssistantVoicePhase.sending);
    voiceRepo.take.add(const AssistantVoiceDone('olive oil'));
    await settle(tester);
    expect(chatRepo.sends.single.message, 'olive oil');
    semantics.dispose();
    await unmount(tester);
  });

  group('motion (docs/motion §9.6 §2.9)', () {
    List<String?> recordHaptics(WidgetTester tester) {
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

    testWidgets('the hold ticks once, at touch-down, before the mic opens', (
      tester,
    ) async {
      await pump(tester);
      final haptics = recordHaptics(tester);
      final gesture = await tester.startGesture(tester.getCenter(mic()));
      expect(haptics, ['HapticFeedbackType.selectionClick']);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(voice.state.phase, AssistantVoicePhase.holding);
      expect(haptics, hasLength(1), reason: 'nothing while it records');
      await gesture.moveBy(const Offset(-140, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump(AssistantVoiceDiscard.duration);
      await settle(tester);
      await unmount(tester);
    });

    testWidgets('a cancel bins in 400 ms over a field that takes input at '
        'once', (tester) async {
      await pump(tester);
      final gesture = await hold(tester);
      await gesture.moveBy(const Offset(-140, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(AssistantVoiceDiscard), findsOneWidget);
      expect(AssistantVoiceDiscard.duration, const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(TextField).hitTestable(), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'milk');
      await tester.pump();
      expect(find.byType(AssistantVoiceDiscard), findsOneWidget);
      await tester.pump(AssistantVoiceDiscard.duration);
      expect(find.byType(AssistantVoiceDiscard), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'milk',
      );
      await settle(tester);
      await unmount(tester);
    });

    testWidgets('reduced motion: the held mic only darkens; lock and cancel '
        'swap at once, with no bin', (tester) async {
      await pump(tester, reducedMotion: true);
      final gesture = await hold(tester);
      final scale = tester.widget<AnimatedScale>(
        find.descendant(of: mic(), matching: find.byType(AnimatedScale)),
      );
      expect(scale.scale, 1, reason: 'no growth under reduced motion');
      expect(find.byType(AssistantVoiceHoldBar), findsOneWidget);

      await gesture.moveBy(const Offset(0, -100));
      await tester.pump();
      await tester.pump();
      expect(find.byType(AssistantVoiceLockedControls), findsOneWidget);
      expect(find.byType(AssistantVoiceHoldBar), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
      await gesture.up();
      await tester.pump();

      await tester.tap(find.byTooltip('Delete recording'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(AssistantVoiceDiscard), findsNothing);
      expect(find.byType(AssistantVoiceLockedControls), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
      await unmount(tester);
    });
  });
}
