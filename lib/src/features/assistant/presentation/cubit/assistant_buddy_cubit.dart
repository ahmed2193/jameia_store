import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/assistant_nudge_outcome.dart';
import '../../domain/usecases/claim_assistant_nudge_usecase.dart';
import '../../domain/usecases/complete_assistant_onboarding_usecase.dart';
import '../../domain/usecases/get_assistant_launcher_hidden_usecase.dart';
import '../../domain/usecases/get_assistant_onboarded_usecase.dart';
import '../../domain/usecases/hide_assistant_launcher_usecase.dart';
import '../../domain/usecases/record_assistant_nudge_outcome_usecase.dart';
import 'assistant_buddy_scene.dart';
import 'assistant_buddy_state.dart';

/// The assistant's buddy over the main shell: the floating launcher and the
/// greeting that drops in from the top.
///
/// The greeting waits for a calm moment — never on arrival (NN/g): the
/// customer has been on a screen that may greet for [dwell], has touched or
/// scrolled at least once, and has left the screen alone for [quiet]. It
/// is asked for at most once per shell, and the domain policy decides
/// whether today is a day for it at all. The launcher steps aside while the
/// customer scrolls down and comes back on the way up or on another tab.
///
/// A customer who never met the assistant gets its tour instead: from the
/// first greeting (an invitation) or the first tap on the launcher. While
/// the tour is up the launcher steps aside; afterwards it says for
/// [coachFor] where it lives.
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
    this.coachFor = defaultCoachFor,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const AssistantBuddyState());

  static const Duration defaultDwell = Duration(seconds: 10);
  static const Duration defaultQuiet = Duration(seconds: 4);
  static const Duration defaultCoachFor = Duration(seconds: 4);

  final ClaimAssistantNudgeUseCase _claim;
  final RecordAssistantNudgeOutcomeUseCase _record;
  final GetAssistantLauncherHiddenUseCase _getHidden;
  final HideAssistantLauncherUseCase _hide;
  final GetAssistantOnboardedUseCase _getOnboarded;
  final CompleteAssistantOnboardingUseCase _completeOnboarding;
  final DateTime Function() _clock;

  /// Time on a greeting screen before the greeting may come.
  final Duration dwell;

  /// Time without touching or scrolling before the greeting may come.
  final Duration quiet;

  /// How long the launcher says where it lives after the tour.
  final Duration coachFor;

  Timer? _due;
  Timer? _coach;
  DateTime? _greetableSince;
  DateTime? _lastActivity;
  bool _scrolling = false;
  bool _touched = false;

  /// The greeting was asked for (or made pointless by opening the chat):
  /// this shell asks no more.
  bool _asked = false;

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
  }

  void setScene(AssistantBuddyScene scene) {
    if (scene == state.scene) return;
    final newPlace = scene.place != state.scene.place;
    safeEmit(
      state.copyWith(scene: scene, scrolledAway: newPlace ? false : null),
    );
    if (newPlace) _greetableSince = null;
    _arm();
  }

  /// A finger went down anywhere over the shell: the greeting waits for
  /// [quiet] after it, so it never looks like the answer to that tap.
  void touched() {
    if (state.coaching) coachDone();
    _touched = true;
    _lastActivity = _clock();
    _arm();
  }

  /// The customer started dragging the content, [towardsEnd] = down the
  /// list (the launcher steps aside) or back up (it returns).
  void scrollStarted({required bool towardsEnd}) {
    _touched = true;
    _scrolling = true;
    _lastActivity = _clock();
    _due?.cancel();
    if (towardsEnd != state.scrolledAway) {
      safeEmit(state.copyWith(scrolledAway: towardsEnd));
    }
  }

  void scrollStopped() {
    _scrolling = false;
    _lastActivity = _clock();
    _arm();
  }

  /// The mascot hops (the cart just grew) — only worth it when it is seen.
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
    await _record(
      RecordAssistantNudgeOutcomeParams(outcome: outcome, at: _clock()),
    );
  }

  /// The customer opened the chat from the launcher: no greeting today.
  Future<void> launcherOpened() async {
    _asked = true;
    _due?.cancel();
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
    safeEmit(state.copyWith(touring: true, onboarded: true));
    await _completeOnboarding(CompleteAssistantOnboardingParams(at: _clock()));
  }

  /// The tour closed. The launcher hops back and — when the customer is
  /// not off to the chat — says where it lives ([coach]).
  void tourEnded({required bool coach}) {
    _coach?.cancel();
    safeEmit(
      state.copyWith(touring: false, cheers: state.cheers + 1, coaching: coach),
    );
    if (coach) _coach = Timer(coachFor, coachDone);
  }

  /// The "I'm right here" bubble goes.
  void coachDone() {
    _coach?.cancel();
    if (state.coaching) safeEmit(state.copyWith(coaching: false));
  }

  /// "Hide for today". The launcher goes at once, whatever the device log
  /// answers.
  Future<void> hideLauncher() async {
    safeEmit(state.copyWith(launcherHidden: true));
    await _hide(HideAssistantLauncherParams(at: _clock()));
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
    safeEmit(state.copyWith(nudge: () => nudge));
  }

  @override
  Future<void> close() {
    _due?.cancel();
    _coach?.cancel();
    return super.close();
  }
}
