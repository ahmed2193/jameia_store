// The buddy's motion policy (docs/motion §9.6 §3), on the real widgets: a
// mascot is still by default and plays nothing through a closed gate or
// under reduced motion; a wake blinks once, at most once per wake gap; the
// chat keeps its mascots still while the mic records, a reply streams or
// the keyboard is up; the launcher hops at most once per hop gap and a hop
// waits for a flight to the cart to land; the word reveal brings known text
// in word by word within its ceiling, plain once done, whole at once under
// reduced motion.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/motion/confetti_burst.dart';
import 'package:hero_mart/src/core/motion/fly_to_cart.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_thought.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_chat_cubit.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_chat_state.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_voice_cubit.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_voice_state.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/assistant_motion.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/assistant_word_pace.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/assistant_word_reveal.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/buddy/assistant_buddy_launcher.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/buddy/buddy_motion_gate.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/chat/assistant_chat_motion_gate.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/chat/assistant_typing_scope.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/chat/assistant_typing_signal.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/mascot/assistant_mascot.dart';

class _MockChatCubit extends MockCubit<AssistantChatState>
    implements AssistantChatCubit {}

class _MockVoiceCubit extends MockCubit<AssistantVoiceState>
    implements AssistantVoiceCubit {}

void main() {
  Widget app(Widget child, {bool reduced = false}) => MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );

  /// A mascot behind a gate, with the given reasons to move.
  Widget mascot({
    bool mayMove = true,
    bool reduced = false,
    Object? wake,
    Object? cheer,
    Object? wave,
    Object? wink,
  }) => app(
    BuddyMotionGate(
      mayMove: mayMove,
      child: AssistantMascot(wake: wake, cheer: cheer, wave: wave, wink: wink),
    ),
    reduced: reduced,
  );

  group('the mascot', () {
    testWidgets('is still by default: nothing runs, no timer, no frame', (
      tester,
    ) async {
      await tester.pumpWidget(app(const AssistantMascot()));
      await tester.pump(const Duration(seconds: 20));
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('a closed gate (typing, recording, checkout…) plays no '
        'gesture and no wake blink', (tester) async {
      await tester.pumpWidget(mascot(mayMove: false, cheer: 0, wake: 0));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(
        mascot(mayMove: false, cheer: 1, wave: 1, wink: 1, wake: 1),
      );
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pump(AssistantMotion.wakeBlinkDelay * 2);
      expect(tester.hasRunningAnimations, isFalse, reason: 'no blink');
    });

    testWidgets('reduced motion is static: no hop, wave, wink or blink', (
      tester,
    ) async {
      await tester.pumpWidget(mascot(reduced: true, cheer: 0, wake: 0));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(
        mascot(reduced: true, cheer: 1, wave: 1, wink: 1, wake: 1),
      );
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pump(AssistantMotion.wakeBlinkDelay * 2);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('an open gate hops once per cheer, then rests', (tester) async {
      await tester.pumpWidget(mascot(cheer: 0));
      await tester.pumpWidget(mascot(cheer: 1));
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pump(AssistantMotion.hop);
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a wake blinks once, and not again within the wake gap', (
      tester,
    ) async {
      Future<bool> blinksAfter(Object wake) async {
        await tester.pumpWidget(mascot(wake: wake));
        await tester.pump(AssistantMotion.wakeBlinkDelay);
        await tester.pump(const Duration(milliseconds: 16));
        final blinked = tester.hasRunningAnimations;
        // Frame by frame to the end of the blink: a single long pump is ONE
        // frame, so the blink's second half (and the random double blink)
        // would only start in the next wake's window and read as a blink.
        await tester.pumpAndSettle();
        return blinked;
      }

      await tester.pumpWidget(mascot());
      expect(await blinksAfter(1), isTrue);
      expect(await blinksAfter(2), isFalse, reason: 'too soon');
      await tester.pump(AssistantMotion.wakeBlinkGap);
      expect(await blinksAfter(3), isTrue);
      await tester.pump(AssistantMotion.wakeBlinkGap);
    });
  });

  group('the chat keeps its mascots still', () {
    late _MockChatCubit chat;
    late _MockVoiceCubit voice;

    setUp(() {
      chat = _MockChatCubit();
      voice = _MockVoiceCubit();
      whenListen(
        chat,
        const Stream<AssistantChatState>.empty(),
        initialState: const AssistantChatState(),
      );
    });

    Future<bool> mayMove(
      WidgetTester tester, {
      AssistantVoicePhase phase = AssistantVoicePhase.idle,
      double keyboard = 0,
      bool typing = false,
    }) async {
      final signal = AssistantTypingSignal()..report(typing);
      addTearDown(signal.dispose);
      whenListen(
        voice,
        const Stream<AssistantVoiceState>.empty(),
        initialState: AssistantVoiceState(phase: phase),
      );
      late bool may;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: keyboard)),
            child: MultiBlocProvider(
              providers: [
                BlocProvider<AssistantChatCubit>.value(value: chat),
                BlocProvider<AssistantVoiceCubit>.value(value: voice),
              ],
              child: AssistantTypingScope(
                signal: signal,
                child: AssistantChatMotionGate(
                  child: Builder(
                    builder: (context) {
                      may = BuddyMotionGate.mayMoveOf(context);
                      return const SizedBox();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      return may;
    }

    testWidgets('free to move when nothing goes on', (tester) async {
      expect(await mayMove(tester), isTrue);
    });

    testWidgets('while the mic is open (holding, locked, sending)', (
      tester,
    ) async {
      for (final phase in [
        AssistantVoicePhase.holding,
        AssistantVoicePhase.locked,
        AssistantVoicePhase.sending,
      ]) {
        expect(await mayMove(tester, phase: phase), isFalse, reason: '$phase');
      }
    });

    testWidgets('while the customer types (the keyboard is up)', (
      tester,
    ) async {
      expect(await mayMove(tester, keyboard: 300), isFalse);
    });

    testWidgets('while a draft waits in the box (keyboard down)', (
      tester,
    ) async {
      expect(await mayMove(tester, typing: true), isFalse);
    });
  });

  group('the launcher', () {
    final touches = ValueNotifier<Offset?>(null);
    tearDownAll(touches.dispose);

    Widget launcher({required int cheers, int visit = 0}) => app(
      SizedBox(
        width: 400,
        height: 700,
        child: BuddyMotionGate(
          mayMove: true,
          child: AssistantBuddyLauncher(
            shown: true,
            cheers: cheers,
            visit: visit,
            onThoughtSaid: (AssistantThought _) {},
            onThoughtDone: (AssistantThought _) {},
            touches: touches,
            onOpen: () {},
            onThoughtTap: (AssistantThought _) {},
            onHide: () async {},
          ),
        ),
      ),
    );

    Object? hops(WidgetTester tester) =>
        tester.widget<AssistantMascot>(find.byType(AssistantMascot)).cheer;

    testWidgets('hops at most once per hop gap and a few times a visit', (
      tester,
    ) async {
      await tester.pumpWidget(launcher(cheers: 0));
      final rest = hops(tester);
      await tester.pumpWidget(launcher(cheers: 1));
      final first = hops(tester);
      expect(first, isNot(rest), reason: 'one hop');
      await tester.pumpWidget(launcher(cheers: 2));
      expect(hops(tester), first, reason: 'too soon: dropped');

      for (
        var cheers = 3;
        cheers < 3 + AssistantMotion.hopsPerVisit;
        cheers++
      ) {
        await tester.pump(AssistantMotion.hopGap);
        await tester.pumpWidget(launcher(cheers: cheers));
      }
      final capped = hops(tester);
      await tester.pump(AssistantMotion.hopGap);
      await tester.pumpWidget(launcher(cheers: 10));
      expect(hops(tester), capped, reason: 'the visit had its hops');

      await tester.pump(AssistantMotion.hopGap);
      await tester.pumpWidget(launcher(cheers: 11, visit: 1));
      expect(hops(tester), isNot(capped), reason: 'a new visit');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a hop waits for the flight to the cart to land', (
      tester,
    ) async {
      final source = GlobalKey();
      final cart = GlobalKey();
      FlyToCart.pushTarget(cart);
      addTearDown(() => FlyToCart.popTarget(cart));
      await tester.pumpWidget(
        app(
          Column(
            children: [
              SizedBox(key: cart, width: 40, height: 40),
              SizedBox(key: source, width: 40, height: 40),
              Expanded(child: launcher(cheers: 0)),
            ],
          ),
        ),
      );
      final rest = hops(tester);
      final context = tester.element(find.byKey(source));
      expect(
        FlyToCart.fly(
          context,
          sourceKey: source,
          thumbnail: const SizedBox.square(dimension: 8),
        ),
        isTrue,
      );
      expect(FlyToCart.inFlight.value, isTrue);
      await tester.pumpWidget(
        app(
          Column(
            children: [
              SizedBox(key: cart, width: 40, height: 40),
              SizedBox(key: source, width: 40, height: 40),
              Expanded(child: launcher(cheers: 1)),
            ],
          ),
        ),
      );
      expect(hops(tester), rest, reason: 'the flight is in the air');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 16));
      expect(FlyToCart.inFlight.value, isFalse);
      expect(hops(tester), isNot(rest), reason: 'landed: now it hops');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a hop waits for a confetti burst to fall', (tester) async {
      Widget scene({required Object? burst, required int cheers}) => app(
        ConfettiBurst(
          playKey: burst,
          colors: const [Color(0xFF00AA00)],
          child: launcher(cheers: cheers),
        ),
      );
      await tester.pumpWidget(scene(burst: null, cheers: 0));
      final rest = hops(tester);

      await tester.pumpWidget(scene(burst: 1, cheers: 0));
      expect(ConfettiBurst.playing.value, isTrue);
      await tester.pumpWidget(scene(burst: 1, cheers: 1));
      expect(hops(tester), rest, reason: 'the confetti is in the air');

      await tester.pump(AppMotion.confetti);
      await tester.pump(const Duration(milliseconds: 16));
      expect(ConfettiBurst.playing.value, isFalse);
      expect(hops(tester), isNot(rest), reason: 'it fell: now it hops');
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('the word reveal', () {
    const text = 'Need a hand with dinner tonight?';

    testWidgets('brings the words in one by one, never past its ceiling, '
        'and ends plain', (tester) async {
      var done = 0;
      await tester.pumpWidget(
        app(
          AssistantWordReveal(
            text: text,
            style: const TextStyle(color: Color(0xFF000000)),
            onDone: () => done++,
          ),
        ),
      );
      final pace = AssistantWordPace(text);
      expect(pace.words.join(), text, reason: 'whole words, nothing lost');
      expect(pace.words, hasLength(6));
      expect(
        pace.length,
        lessThanOrEqualTo(
          AssistantMotion.revealMax + const Duration(milliseconds: 150),
        ),
      );
      expect(find.text(text), findsOneWidget, reason: 'laid out whole');

      List<double> alphas() {
        final span =
            tester.widget<Text>(find.byType(Text)).textSpan! as TextSpan;
        return [
          for (final word in span.children ?? const <InlineSpan>[])
            (word as TextSpan).style!.color!.a,
        ];
      }

      await tester.pump(pace.step * 2);
      final midway = alphas();
      expect(midway.first, 1, reason: 'the first word is in');
      expect(midway.last, 0, reason: 'the last one is not yet');
      for (var i = 1; i < midway.length; i++) {
        expect(midway[i], lessThanOrEqualTo(midway[i - 1]));
      }

      await tester.pump(pace.length);
      await tester.pump();
      final plain =
          tester.widget<Text>(find.byType(Text)).textSpan! as TextSpan;
      expect(plain.children, isNull, reason: 'finished text is plain');
      expect(done, 1);
    });

    testWidgets('reduced motion: whole at once, done after the first frame', (
      tester,
    ) async {
      var done = 0;
      await tester.pumpWidget(
        app(
          AssistantWordReveal(
            text: text,
            style: const TextStyle(color: Color(0xFF000000)),
            onDone: () => done++,
          ),
          reduced: true,
        ),
      );
      final span = tester.widget<Text>(find.byType(Text)).textSpan! as TextSpan;
      expect(span.children, isNull);
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pump();
      expect(done, 1);
    });
  });
}
