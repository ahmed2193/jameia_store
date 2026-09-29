import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/assistant_day_part.dart';
import '../../domain/entities/assistant_nudge_outcome.dart';
import '../../domain/entities/assistant_thought.dart';
import '../../domain/entities/assistant_thought_deck.dart';
import '../../domain/entities/assistant_thought_place.dart';
import '../../domain/usecases/claim_assistant_nudge_usecase.dart';
import '../../domain/usecases/complete_assistant_onboarding_usecase.dart';
import '../../domain/usecases/get_assistant_launcher_hidden_usecase.dart';
import '../../domain/usecases/get_assistant_onboarded_usecase.dart';
import '../../domain/usecases/hide_assistant_launcher_usecase.dart';
import '../../domain/usecases/record_assistant_nudge_outcome_usecase.dart';
import 'assistant_buddy_scene.dart';
import 'assistant_buddy_state.dart';

/// The assistant's buddy over the main shell: the floating launcher, the
/// line it thinks out loud above its head, and the greeting that drops in
/// from the top.
///
/// The greeting waits for a calm moment — never on arrival (NN/g): the
/// customer has been on a screen that may greet for [dwell], has touched or
/// scrolled at least once, and has left the screen alone for [quiet]. It
/// is asked for at most once per shell, and the domain policy decides
/// whether today is a day for it at all. The launcher steps aside while the
/// customer scrolls down and comes back on the way up or on another tab.
///
/// The thoughts are lighter: once the launcher has been on screen for
/// [thinkAfter] and nothing was touched for [thinkQuiet], it thinks out loud.
/// Every visit — each opening of the app, or coming back after [visitGap]
/// away — opens with a greeting ("How can I help you today?") and one more
/// line in the same bubble; then at most ONE follow-up, [thinkEvery] after
/// the last line ended and only on a screen that browses or searches, and
/// it rests until the next visit ([maxSessionsPerVisit]; docs/motion §9.6
/// §3.4). Back from the chat, that follow-up asks whether there is anything
/// else. The lines come from the [AssistantThoughtDeck]: varied, fitting
/// the screen, the cart and the time of day, never the same topic twice in
/// a row. A line yields to the customer: a touch or a scroll sends it away
/// at once (it counts as said, and no second line follows it). None starts
/// — and one on screen goes, never to come back — behind a dialog, sheet or
/// page, on a hidden tab, with the keyboard up, while the app is away or
/// with a screen reader (the launcher says what it does).
///
/// A customer who never met the assistant gets its tour instead of the
/// chat: from the first greeting (an invitation) or the first tap on the
/// launcher. While the tour is up the launcher steps aside; afterwards it
/// thinks out loud where it lives.
class AssistantBuddyCubit extends Cubit<AssistantBuddyState>
    with SafeCubitMixin<AssistantBuddyState> {
  AssistantBuddyCubit({
    required this._claim,
    required this._record,
    required this._getHidden,
    required this._hide,
    required this._getOnboarded,
    required this._completeOnboarding,
    this.dwell = defaultDwell,
    this.quiet = defaultQuiet,
    this.thinkAfter = defaultThinkAfter,
    this.thinkQuiet = defaultThinkQuiet,
    this.thinkEvery = defaultThinkEvery,
    this.visitGap = defaultVisitGap,
    Random? random,
    DateTime Function()? clock,
  }) : _random = random ?? Random(),
       _clock = clock ?? DateTime.now,
       super(const AssistantBuddyState());

  static const Duration defaultDwell = Duration(seconds: 10);
  static const Duration defaultQuiet = Duration(seconds: 4);
  static const Duration defaultThinkAfter = Duration(seconds: 3);
  static const Duration defaultThinkQuiet = Duration(seconds: 2);
  static const Duration defaultThinkEvery = Duration(seconds: 90);
  static const Duration defaultVisitGap = Duration(minutes: 30);

  /// Times the launcher thinks out loud in one visit — the opening pair,
  /// then one follow-up; then it rests until the next visit.
  static const int maxSessionsPerVisit = 2;

  final ClaimAssistantNudgeUseCase _claim;
  final RecordAssistantNudgeOutcomeUseCase _record;
  final GetAssistantLauncherHiddenUseCase _getHidden;
  final HideAssistantLauncherUseCase _hide;
  final GetAssistantOnboardedUseCase _getOnboarded;
  final CompleteAssistantOnboardingUseCase _completeOnboarding;
  final Random _random;
  final DateTime Function() _clock;

  /// Time on a greeting screen before the greeting may come.
  final Duration dwell;

  /// Time without touching or scrolling before the greeting may come.
  final Duration quiet;

  /// Time the launcher has been on screen before it may think out loud.
  final Duration thinkAfter;

  /// Time without touching or scrolling before it may think out loud.
  final Duration thinkQuiet;

  /// Time from the end of the opening lines to the follow-up.
  final Duration thinkEvery;

  /// Time away from the app after which coming back counts as opening it.
  final Duration visitGap;

  Timer? _due;
  Timer? _think;
  DateTime? _greetableSince;
  DateTime? _shownSince;
  DateTime? _lastThoughtEnd;
  DateTime? _awaySince;
  DateTime? _lastActivity;
  bool _scrolling = false;
  bool _touched = false;

  /// The greeting was asked for (or made pointless by opening the chat):
  /// this shell asks no more.
  bool _asked = false;

  /// Times the launcher thought out loud this visit.
  int _sessions = 0;

  /// One more line follows the one on screen (the visit's opening pair).
  bool _pairing = false;

  /// The customer went to the chat: the next thought asks if there is
  /// anything else.
  bool _backFromChat = false;

  AssistantThoughtDeck _deck = const AssistantThoughtDeck();

  /// Reads whether the customer hid the launcher for today and whether
  /// they met the assistant yet.
  Future<void> start() async {
    final hidden = await _getHidden(
      GetAssistantLauncherHiddenParams(at: _clock()),
    );
    final onboarded = await _getOnboarded(const NoParams());
    // Unreadable device log: show the launcher, and no tour to insist on.
    safeEmit(
      state.copyWith(
        launcherHidden: hidden.fold((_) => false, (h) => h),
        onboarded: onboarded.fold((_) => true, (o) => o),
      ),
    );
    _armThought();
  }

  void setScene(AssistantBuddyScene scene) {
    if (scene == state.scene) return;
    final newPlace = scene.place != state.scene.place;
    safeEmit(
      state.copyWith(scene: scene, scrolledAway: newPlace ? false : null),
    );
    if (newPlace) _greetableSince = null;
    // Covered, tucked away, typing, a screen reader: a line on screen goes
    // and is not said again.
    if (!_launcherSeen || scene.screenReader) _yieldThought();
    _arm();
    _armThought();
  }

  /// A finger went down anywhere over the shell: the greeting waits for
  /// [quiet] after it, so it never looks like the answer to that tap, and a
  /// thought on screen makes way.
  void touched() {
    _touched = true;
    _lastActivity = _clock();
    _yieldThought();
    _arm();
    _armThought();
  }

  /// The customer started dragging the content, [towardsEnd] = down the
  /// list (the launcher steps aside) or back up (it returns).
  void scrollStarted({required bool towardsEnd}) {
    _touched = true;
    _scrolling = true;
    _lastActivity = _clock();
    _due?.cancel();
    _think?.cancel();
    _yieldThought();
    if (towardsEnd != state.scrolledAway) {
      safeEmit(state.copyWith(scrolledAway: towardsEnd));
    }
  }

  void scrollStopped() {
    _scrolling = false;
    _lastActivity = _clock();
    _arm();
    _armThought();
  }

  /// The app went to the background: a line on screen goes, and none
  /// starts while nobody sees.
  void appPaused() {
    _awaySince ??= _clock();
    _yieldThought();
    _armThought();
  }

  /// The app is back. After [visitGap] away it is a new visit: a line left
  /// over from before goes, and the hello comes first again, as when the
  /// app opens.
  void appResumed() {
    final away = _awaySince;
    _awaySince = null;
    if (away != null && !_clock().isBefore(away.add(visitGap))) {
      _sessions = 0;
      _pairing = false;
      _lastThoughtEnd = null;
      safeEmit(state.copyWith(thought: () => null, visit: state.visit + 1));
    }
    _armThought();
  }

  /// The mascot may hop (the cart just grew) — only worth it when it is
  /// seen; how often it really hops is the launcher's to decide.
  void cheer() {
    if (state.launcherShown) {
      safeEmit(state.copyWith(cheers: state.cheers + 1));
    }
  }

  /// The greeting went away with [outcome]; the launcher takes over again
  /// with a hop.
  Future<void> greetingClosed(AssistantNudgeOutcome outcome) async {
    if (state.nudge == null) return;
    safeEmit(state.copyWith(nudge: () => null, cheers: state.cheers + 1));
    // The greeting counts as something said: the next thought waits.
    _lastThoughtEnd = _clock();
    _armThought();
    await _record(
      RecordAssistantNudgeOutcomeParams(outcome: outcome, at: _clock()),
    );
  }

  /// The customer opened the chat from the launcher (or one of its
  /// thoughts): no greeting today, and the thought on screen was answered.
  Future<void> launcherOpened() async {
    _asked = true;
    _due?.cancel();
    _think?.cancel();
    _pairing = false;
    _backFromChat = true;
    if (state.thought != null) safeEmit(state.copyWith(thought: () => null));
    _lastThoughtEnd = _clock();
    await _record(
      RecordAssistantNudgeOutcomeParams(
        outcome: AssistantNudgeOutcome.opened,
        at: _clock(),
      ),
    );
  }

  /// The tour opens: it counts as met right away (leaving half-way too),
  /// the launcher steps aside and no greeting comes after it.
  Future<void> tourStarted() async {
    _asked = true;
    _due?.cancel();
    _think?.cancel();
    _pairing = false;
    safeEmit(
      state.copyWith(touring: true, onboarded: true, thought: () => null),
    );
    await _completeOnboarding(CompleteAssistantOnboardingParams(at: _clock()));
  }

  /// The tour closed. The launcher hops back and — when the customer is
  /// not off to the chat — thinks out loud where it lives ([coach]).
  void tourEnded({required bool coach}) {
    _pairing = false;
    _lastThoughtEnd = _clock();
    safeEmit(
      state.copyWith(
        touring: false,
        cheers: state.cheers + 1,
        thought: () => coach ? AssistantThought.coach : null,
      ),
    );
    _armThought();
  }

  /// [thought] has been read. The visit's opening line hands over to one
  /// more in the same bubble — unless the customer scrolled on, or anything
  /// else took the launcher's place; otherwise the bubble goes by itself.
  void thoughtSaid(AssistantThought thought) {
    if (state.thought != thought || !_pairing) return;
    _pairing = false;
    if (_scrolling ||
        state.scrolledAway ||
        !_launcherSeen ||
        state.nudge != null ||
        state.touring ||
        state.scene.screenReader) {
      return;
    }
    final next = _dealt();
    _deck = _deck.said(next);
    safeEmit(state.copyWith(thought: () => next));
  }

  /// [thought] has gone (said, or its launcher went away); only that one
  /// goes, and the next thought comes after a while.
  void thoughtDone(AssistantThought thought) {
    if (state.thought != thought) return;
    _pairing = false;
    _lastThoughtEnd = _clock();
    safeEmit(state.copyWith(thought: () => null));
    _arm();
    _armThought();
  }

  /// "Hide for today". The launcher goes at once, whatever the device log
  /// answers.
  Future<void> hideLauncher() async {
    _think?.cancel();
    _pairing = false;
    safeEmit(state.copyWith(launcherHidden: true, thought: () => null));
    await _hide(HideAssistantLauncherParams(at: _clock()));
  }

  /// The customer acted (or the launcher went out of sight): the line on
  /// screen goes at once. It counts as said — the visit's opening pair ends
  /// there — and it is never said again.
  void _yieldThought() {
    _pairing = false;
    if (state.thought == null) return;
    _lastThoughtEnd = _clock();
    safeEmit(state.copyWith(thought: () => null));
  }

  /// (Re)plans the greeting for the first moment every condition can hold.
  void _arm() {
    _due?.cancel();
    if (_asked || state.nudge != null) return;
    if (!state.scene.canGreet) {
      _greetableSince = null;
      return;
    }
    final now = _clock();
    final since = _greetableSince ??= now;
    if (!_touched || _scrolling) return;
    var due = since.add(dwell);
    final lastActivity = _lastActivity;
    if (lastActivity != null && lastActivity.add(quiet).isAfter(due)) {
      due = lastActivity.add(quiet);
    }
    final wait = due.difference(now);
    _due = Timer(wait.isNegative ? Duration.zero : wait, _greet);
  }

  Future<void> _greet() async {
    if (_asked || _scrolling || !state.scene.canGreet) return;
    // A line on screen is finished first; its end plans the greeting again.
    if (state.thought != null) return;
    _asked = true;
    final result = await _claim(
      ClaimAssistantNudgeParams(
        at: _clock(),
        hasCartItems: state.scene.hasCartItems,
      ),
    );
    final nudge = result.fold((_) => null, (nudge) => nudge);
    // The customer may have moved on while the log was read.
    if (nudge == null || !state.scene.canGreet) return;
    _pairing = false;
    safeEmit(state.copyWith(nudge: () => nudge, thought: () => null));
    _armThought();
  }

  /// (Re)plans the next thought for the first moment the launcher has been
  /// seen long enough, the last thought is far enough behind and the screen
  /// is calm.
  void _armThought() {
    _think?.cancel();
    // Seen again after being tucked away, covered or out of the app: it
    // waits a moment anew.
    if (!_launcherSeen) {
      _shownSince = null;
      return;
    }
    if (!_canThink || _sessions >= maxSessionsPerVisit) return;
    // The follow-up only where the customer browses or searches.
    if (_sessions > 0 && !_followsUpHere) return;
    final now = _clock();
    final since = _shownSince ??= now;
    if (_scrolling) return;
    var due = since.add(thinkAfter);
    final lastEnd = _lastThoughtEnd;
    if (lastEnd != null) {
      final next = lastEnd.add(thinkEvery);
      if (next.isAfter(due)) due = next;
    }
    final lastActivity = _lastActivity;
    if (lastActivity != null && lastActivity.add(thinkQuiet).isAfter(due)) {
      due = lastActivity.add(thinkQuiet);
    }
    final wait = due.difference(now);
    _think = Timer(wait.isNegative ? Duration.zero : wait, _thinkOutLoud);
  }

  /// The launcher is on screen with nothing over the shell, in an app that
  /// is in front.
  bool get _launcherSeen =>
      state.launcherShown && state.scene.inFront && _awaySince == null;

  bool get _followsUpHere => switch (state.scene.thoughtPlace) {
    AssistantThoughtPlace.browsing || AssistantThoughtPlace.searching => true,
    AssistantThoughtPlace.account || AssistantThoughtPlace.elsewhere => false,
  };

  bool get _canThink =>
      state.thought == null &&
      state.nudge == null &&
      !state.touring &&
      !state.scene.screenReader;

  /// A visit opens with a greeting and one more line; back from the chat
  /// it asks if there is anything else; otherwise one line.
  void _thinkOutLoud() {
    if (_scrolling || !_launcherSeen || !_canThink) return;
    final opening = _sessions == 0;
    if (!opening && !_followsUpHere) return;
    final askedLately = _deck.recent.contains(AssistantThought.anythingElse);
    final line = switch (opening) {
      true => _deck.opener(
        _random,
        firstMeeting: !state.onboarded,
        dayPart: AssistantDayPart.of(_clock()),
      ),
      false when _backFromChat && !askedLately => AssistantThought.anythingElse,
      false => _dealt(),
    };
    _backFromChat = false;
    _deck = _deck.said(line);
    _sessions++;
    _pairing = opening;
    safeEmit(state.copyWith(thought: () => line));
  }

  /// The deck's next line for this screen, cart and time of day.
  AssistantThought _dealt() => _deck.next(
    _random,
    place: state.scene.thoughtPlace,
    hasCartItems: state.scene.hasCartItems,
    dayPart: AssistantDayPart.of(_clock()),
  );

  @override
  Future<void> close() {
    _due?.cancel();
    _think?.cancel();
    return super.close();
  }
}
