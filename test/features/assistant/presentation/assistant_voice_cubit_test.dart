// The composer's voice message, WhatsApp style, over a scripted repository:
// press and hold records at once in the app's language, a mere tap only
// hints, letting go sends the words heard (or says nothing was heard),
// sliding away drops them, sliding up locks and sends / stops to read over;
// microphone refusals, a device with no recognizer, the permission dialog
// taking the touch, the clock and waveform, the length cap, failures that
// keep the words, and leaving mid-recording. The language: the app's until
// the customer switches, then theirs — mid-recording too.
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_prompt.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_voice_access.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_voice_event.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_voice_language.dart';
import 'package:jameia_mart/src/features/assistant/domain/entities/assistant_voice_problem.dart';
import 'package:jameia_mart/src/features/assistant/presentation/cubit/assistant_voice_cubit.dart';
import 'package:jameia_mart/src/features/assistant/presentation/cubit/assistant_voice_state.dart';

import 'assistant_voice_fakes.dart';

void main() {
  late FakeVoiceRepository repo;
  late AssistantVoiceCubit cubit;

  setUp(() {
    repo = FakeVoiceRepository();
    cubit = voiceCubit(repo);
  });
  tearDown(() => cubit.close());

  Future<void> flush() => Future<void>.delayed(Duration.zero);
  Future<void> wait(Duration duration) => Future<void>.delayed(duration);

  /// Holds the mic past a mere tap, the microphone open.
  Future<void> recording() async {
    unawaited(cubit.hold('en'));
    await flush();
    await wait(testVoicePolicy.accidentalTap + testVoiceTick * 3);
  }

  group('press and hold', () {
    test('the mic records at once and listens in the app language', () async {
      final holding = cubit.hold('ar');
      expect(cubit.state.phase, AssistantVoicePhase.holding);
      await holding;
      expect(repo.accessRequests, 1);
      expect(repo.languages, ['ar']);
    });

    test('a mere tap is no message: the hint, and the mic stops', () async {
      unawaited(cubit.hold('en'));
      await flush();
      cubit.release();
      expect(cubit.state.phase, AssistantVoicePhase.idle);
      expect(cubit.state.notice, AssistantVoiceNotice.tooShort);
      await flush();
      expect(repo.cancels, 1);
      expect(repo.finishes, 0);
    });

    test('letting go sends the words heard', () async {
      await recording();
      repo.take.add(const AssistantVoiceHeard('milk and eggs'));
      await flush();
      expect(cubit.state.transcript, 'milk and eggs');

      cubit.release();
      expect(cubit.state.phase, AssistantVoicePhase.sending);
      await flush();
      expect(repo.finishes, 1);

      repo.take.add(const AssistantVoiceDone(' milk and eggs please '));
      await flush();
      expect(cubit.state.phase, AssistantVoicePhase.idle);
      expect(cubit.state.notice, AssistantVoiceNotice.send);
      expect(cubit.state.noticeText, 'milk and eggs please');
    });

    test('nothing heard: nothing sent, "didn\'t catch that"', () async {
      await recording();
      cubit.release();
      repo.take.add(const AssistantVoiceDone('  '));
      await flush();
      expect(cubit.state.notice, AssistantVoiceNotice.noSpeech);
      expect(cubit.state.noticeText, isEmpty);
    });

    test('slid away: the words are dropped, later ones ignored', () async {
      await recording();
      final take = repo.take;
      cubit.discard();
      expect(cubit.state.phase, AssistantVoicePhase.idle);
      expect(cubit.state.notice, AssistantVoiceNotice.discarded);
      await flush();
      expect(repo.cancels, 1);

      take.add(const AssistantVoiceHeard('too late'));
      await flush();
      expect(cubit.state.transcript, isEmpty);
      expect(cubit.state.phase, AssistantVoicePhase.idle);
    });

    test('slid up: hands-free, then sent from the send button', () async {
      await recording();
      cubit.lock();
      expect(cubit.state.phase, AssistantVoicePhase.locked);
      cubit.release(); // the finger lifting from a locked mic: nothing
      expect(cubit.state.phase, AssistantVoicePhase.locked);

      cubit.send();
      expect(cubit.state.phase, AssistantVoicePhase.sending);
      repo.take.add(const AssistantVoiceDone('rice'));
      await flush();
      expect(cubit.state.notice, AssistantVoiceNotice.send);
      expect(cubit.state.noticeText, 'rice');
    });

    test('stop: the words go to the message box to read over', () async {
      await recording();
      cubit
        ..lock()
        ..review();
      expect(cubit.state.phase, AssistantVoicePhase.stopping);
      repo.take.add(const AssistantVoiceDone('eggs'));
      await flush();
      expect(cubit.state.notice, AssistantVoiceNotice.review);
      expect(cubit.state.noticeText, 'eggs');
    });

    test('a screen reader records hands-free from the start', () async {
      await cubit.startHandsFree('en');
      expect(cubit.state.phase, AssistantVoicePhase.locked);
      expect(repo.takes, hasLength(1));
    });

    test('a press while one is going changes nothing', () async {
      await recording();
      await cubit.hold('ar');
      expect(repo.takes, hasLength(1));
      expect(repo.languages, ['en']);
    });
  });

  group('microphone access', () {
    test('refused this time: a hint, and the next press asks again', () async {
      repo.access = const Right(AssistantVoiceAccess.denied);
      await cubit.hold('en');
      expect(cubit.state.phase, AssistantVoicePhase.idle);
      expect(cubit.state.notice, AssistantVoiceNotice.micDenied);
      await cubit.hold('en');
      expect(repo.accessRequests, 2);
      expect(repo.takes, isEmpty);
    });

    test('blocked for good: the settings are offered', () async {
      repo.access = const Right(AssistantVoiceAccess.blocked);
      await cubit.hold('en');
      expect(cubit.state.notice, AssistantVoiceNotice.micBlocked);
      await cubit.openSettings();
      expect(repo.settingsOpened, 1);
    });

    test('no recognizer on the device: the mic goes away', () async {
      repo.access = const Right(AssistantVoiceAccess.unavailable);
      await cubit.hold('en');
      expect(cubit.state.notice, AssistantVoiceNotice.unavailable);
      expect(cubit.state.available, isFalse);
      await cubit.hold('en');
      expect(cubit.state.phase, AssistantVoicePhase.idle);
      expect(repo.accessRequests, 1);
    });

    test('an access failure says so and keeps the mic', () async {
      repo.access = const Left(UnexpectedFailure('boom'));
      await cubit.hold('en');
      expect(cubit.state.notice, AssistantVoiceNotice.failed);
      expect(cubit.state.problem, AssistantVoiceProblem.other);
      expect(cubit.state.available, isTrue);
    });

    test('granted once, never asked again', () async {
      await cubit.hold('en');
      cubit.release();
      await cubit.hold('en');
      expect(repo.accessRequests, 1);
      expect(repo.takes, hasLength(2));
    });

    test('prepared: the first press listens without asking', () async {
      repo.prepared = AssistantVoiceAccess.granted;
      await cubit.prepare();
      await cubit.hold('en');
      expect(repo.accessRequests, 0);
      expect(repo.languages, ['en']);
    });

    test('prepared on a device with no recognizer: no mic at all', () async {
      repo.prepared = AssistantVoiceAccess.unavailable;
      await cubit.prepare();
      expect(cubit.state.available, isFalse);
      expect(cubit.state.notice, isNull);
    });

    test(
      'the permission dialog took the touch: nothing starts behind it',
      () async {
        repo.holdAccess = true;
        unawaited(cubit.hold('en'));
        await flush();
        cubit.interrupt();
        expect(cubit.state.phase, AssistantVoicePhase.idle);
        expect(cubit.state.notice, isNull);

        repo.answerAccess(const Right(AssistantVoiceAccess.granted));
        await flush();
        expect(repo.takes, isEmpty);
        expect(cubit.state.phase, AssistantVoicePhase.idle);
        // Allowed in the dialog: the next press starts at once.
        await cubit.hold('en');
        expect(repo.accessRequests, 1);
        expect(repo.takes, hasLength(1));
      },
    );

    test(
      'let go while the permission dialog is up: no "didn\'t catch that"',
      () async {
        repo.holdAccess = true;
        unawaited(cubit.hold('en'));
        await Future<void>.delayed(testVoicePolicy.accidentalTap * 2);
        cubit.release();
        expect(cubit.state.phase, AssistantVoicePhase.idle);
        expect(cubit.state.notice, isNull);

        repo.answerAccess(const Right(AssistantVoiceAccess.granted));
        await flush();
        expect(repo.takes, isEmpty);
      },
    );
  });

  group('while recording', () {
    test('the clock moves the timer and draws one bar per tick, the loudest '
        'level of the tick', () async {
      await recording();
      repo.take
        ..add(const AssistantVoiceLevel(0.2))
        ..add(const AssistantVoiceLevel(0.8))
        ..add(const AssistantVoiceLevel(0.5));
      await wait(testVoiceTick * 3);
      expect(cubit.state.waveform.levels, contains(0.8));
      expect(cubit.state.waveform.levels, isNot(contains(0.2)));
      expect(cubit.state.elapsed, greaterThan(testVoicePolicy.accidentalTap));
    });

    test('at the length cap it stops; the words wait in the box', () async {
      await recording();
      repo.take.add(const AssistantVoiceHeard('a long list'));
      await wait(testVoicePolicy.maxLength);
      expect(cubit.state.phase, AssistantVoicePhase.stopping);
      expect(repo.finishes, 1);
      repo.take.add(const AssistantVoiceDone('a long list'));
      await flush();
      expect(cubit.state.notice, AssistantVoiceNotice.review);
    });

    test('words that fill a whole message stop it too', () async {
      await recording();
      repo.take.add(AssistantVoiceHeard('a' * AssistantPrompt.maxLength));
      await flush();
      expect(cubit.state.phase, AssistantVoicePhase.stopping);
    });

    test('a failure keeps the words heard', () async {
      await recording();
      repo.take.add(
        const AssistantVoiceFailed(
          AssistantVoiceProblem.network,
          text: 'half a list',
        ),
      );
      await flush();
      expect(cubit.state.phase, AssistantVoicePhase.idle);
      expect(cubit.state.notice, AssistantVoiceNotice.failed);
      expect(cubit.state.problem, AssistantVoiceProblem.network);
      expect(cubit.state.noticeText, 'half a list');
    });

    test('a lost permission asks again on the next press', () async {
      await recording();
      repo.take.add(
        const AssistantVoiceFailed(AssistantVoiceProblem.permission),
      );
      await flush();
      await cubit.hold('en');
      expect(repo.accessRequests, 2);
    });

    test('a failed stop keeps the words', () async {
      repo.finishAnswer = const Left(UnexpectedFailure('stuck'));
      await recording();
      repo.take.add(const AssistantVoiceHeard('bread'));
      await flush();
      cubit.release();
      await flush();
      expect(cubit.state.notice, AssistantVoiceNotice.failed);
      expect(cubit.state.noticeText, 'bread');
    });

    test('the app went away: words wait in the box', () async {
      await recording();
      repo.take.add(const AssistantVoiceHeard('coffee'));
      await flush();
      cubit.interrupt();
      expect(cubit.state.phase, AssistantVoicePhase.stopping);
      repo.take.add(const AssistantVoiceDone('coffee'));
      await flush();
      expect(cubit.state.notice, AssistantVoiceNotice.review);
    });

    test('the app went away before a word: it just stops', () async {
      await recording();
      cubit.interrupt();
      expect(cubit.state.phase, AssistantVoicePhase.idle);
      expect(cubit.state.notice, isNull);
      await flush();
      expect(repo.cancels, 1);
    });

    test('a take closed without its ending keeps what was heard', () async {
      await recording();
      repo.take.add(const AssistantVoiceHeard('tea'));
      await flush();
      await repo.take.close();
      await flush();
      expect(cubit.state.notice, AssistantVoiceNotice.review);
      expect(cubit.state.noticeText, 'tea');
    });

    test('the same notice twice still reaches the listener', () async {
      await cubit.hold('en');
      cubit.release();
      final first = cubit.state.noticeSeq;
      await cubit.hold('en');
      cubit.release();
      expect(cubit.state.notice, AssistantVoiceNotice.tooShort);
      expect(cubit.state.noticeSeq, first + 1);
    });
  });

  test('leaving the chat mid-recording stops the microphone', () async {
    final leaving = voiceCubit(repo);
    unawaited(leaving.hold('en'));
    await flush();
    await leaving.close();
    expect(repo.cancels, 1);
    expect(leaving.isClosed, isTrue);
  });

  group('the language the customer talks in', () {
    test('the app\'s language until the customer chooses one', () async {
      await cubit.prepare();
      await cubit.hold('ar');
      expect(repo.languages, ['ar']);
      expect(cubit.state.language, AssistantVoiceLanguage.arabic);
    });

    test('a chosen language wins over the app\'s — an English app, Arabic '
        'speech', () async {
      repo.storedLanguage = AssistantVoiceLanguage.arabic;
      await cubit.prepare();
      await cubit.hold('en');
      expect(repo.languages, ['ar']);
      expect(cubit.state.language, AssistantVoiceLanguage.arabic);
    });

    test('switching mid-recording listens again in the other language: the '
        'wrong words go, the recording goes on, the choice is kept', () async {
      await recording();
      repo.take.add(const AssistantVoiceHeard('and a bee halib'));
      await flush();
      final elapsed = cubit.state.elapsed;

      cubit.switchLanguage();
      await flush();
      expect(repo.languages, ['en', 'ar']);
      expect(cubit.state.language, AssistantVoiceLanguage.arabic);
      expect(cubit.state.transcript, isEmpty);
      expect(cubit.state.phase, AssistantVoicePhase.holding);
      expect(cubit.state.elapsed, greaterThanOrEqualTo(elapsed));
      expect(repo.savedLanguages, [AssistantVoiceLanguage.arabic]);

      // The English take no longer counts; the Arabic one does.
      repo.takes.first.add(const AssistantVoiceHeard('and a bee halib please'));
      repo.take.add(const AssistantVoiceHeard('أبي حليب'));
      await flush();
      expect(cubit.state.transcript, 'أبي حليب');

      cubit.release();
      repo.take.add(const AssistantVoiceDone('أبي حليب'));
      await flush();
      expect(cubit.state.notice, AssistantVoiceNotice.send);
      expect(cubit.state.noticeText, 'أبي حليب');

      // The next message starts in Arabic, whatever the app's language.
      await cubit.hold('en');
      expect(repo.languages.last, 'ar');
    });

    test('switched while the microphone is still being asked for: it opens '
        'in the new language', () async {
      repo.holdAccess = true;
      unawaited(cubit.hold('en'));
      await flush();
      cubit.switchLanguage();
      repo.answerAccess(const Right(AssistantVoiceAccess.granted));
      await flush();
      expect(repo.languages, ['ar']);
      expect(cubit.state.phase, AssistantVoicePhase.holding);
    });

    test('nothing to switch while the mic rests', () {
      cubit.switchLanguage();
      expect(repo.savedLanguages, isEmpty);
      expect(cubit.state.language, isNull);
    });
  });
}
