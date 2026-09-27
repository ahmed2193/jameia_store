import 'dart:async';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/route_args/assistant_chat_args.dart';
import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/spring_curve.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/assistant_nudge.dart';
import '../../../domain/entities/assistant_nudge_outcome.dart';
import '../../../domain/entities/assistant_starter.dart';
import '../../cubit/assistant_buddy_cubit.dart';
import '../../cubit/assistant_buddy_state.dart';
import '../mascot/assistant_mascot_mood.dart';
import 'assistant_buddy_greeting_card.dart';

/// Drops the greeting in from the top on a soft spring, and takes it away:
/// swiped up or closed ("not now"), tapped (the chat opens), or left alone
/// for [_showFor] after it finished typing — paused while a finger rests on
/// it, and never on its own while a screen reader is on.
class AssistantBuddyGreeting extends StatefulWidget {
  const AssistantBuddyGreeting({super.key});

  @override
  State<AssistantBuddyGreeting> createState() => _AssistantBuddyGreetingState();
}

class _AssistantBuddyGreetingState extends State<AssistantBuddyGreeting>
    with TickerProviderStateMixin {
  static const Duration _showFor = Duration(seconds: 8);
  static const Duration _joyHold = Duration(milliseconds: 1200);
  static const double _hiddenLift = -1.3;
  static const double _enterScale = 0.92;
  static const double _dismissDrag = -AppSize.s40;
  static const double _dismissFling = -700;
  static const double _pullResist = 0.25;
  static const double _maxWidth = AppSize.s520;
  static const Offset _lookAtWords = Offset(0.7, 0.15);

  static final SpringCurve _drop = SpringCurve(
    SpringDescription.withDampingRatio(mass: 1, stiffness: 320, ratio: 0.72),
  );

  late final AnimationController _presence = AnimationController(
    vsync: this,
    duration: _drop.duration,
    reverseDuration: AppMotion.medium,
  );
  late final CurvedAnimation _travel = CurvedAnimation(
    parent: _presence,
    curve: _drop,
    reverseCurve: AppMotion.exit,
  );
  late final AnimationController _countdown = AnimationController(
    vsync: this,
    duration: _showFor,
  );
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
  );

  /// The greeting on screen — kept through its exit.
  AssistantNudge? _nudge;
  bool _typed = false;
  bool _closing = false;
  AssistantMascotMood _mood = AssistantMascotMood.talking;
  double _pull = 0;
  Timer? _joyTimer;

  @override
  void initState() {
    super.initState();
    _countdown.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _close(AssistantNudgeOutcome.ignored);
      }
    });
    _settle.addStatusListener((status) {
      if (status == AnimationStatus.completed) setState(() => _pull = 0);
    });
  }

  void _onBuddy(BuildContext context, AssistantBuddyState state) {
    final nudge = state.nudge;
    if (nudge != null) {
      _enter(nudge);
    } else if (_nudge != null) {
      _leave();
    }
  }

  void _enter(AssistantNudge nudge) {
    _joyTimer?.cancel();
    _countdown.value = 0;
    setState(() {
      _nudge = nudge;
      _typed = false;
      _closing = false;
      _mood = AssistantMascotMood.talking;
      _pull = 0;
    });
    if (MotionGuard.reduced(context)) {
      _presence.value = 1;
    } else {
      _presence.forward(from: 0);
    }
  }

  void _leave() {
    _countdown.stop();
    _joyTimer?.cancel();
    void gone() {
      if (mounted && !_presence.isAnimating) setState(() => _nudge = null);
    }

    if (MotionGuard.reduced(context)) {
      _presence.value = 0;
      gone();
    } else {
      _presence.reverse().then((_) => gone());
    }
  }

  /// Typed out: a happy face, the starters unfold, the countdown starts.
  void _onTyped() {
    setState(() {
      _typed = true;
      _mood = AssistantMascotMood.happy;
    });
    _joyTimer = Timer(_joyHold, () {
      if (mounted) setState(() => _mood = AssistantMascotMood.idle);
    });
    _runCountdown();
  }

  void _runCountdown() {
    if (!_typed || _closing || MediaQuery.accessibleNavigationOf(context)) {
      return;
    }
    _countdown.forward();
  }

  void _close(AssistantNudgeOutcome outcome) {
    if (_closing) return;
    _closing = true;
    _countdown.stop();
    context.read<AssistantBuddyCubit>().greetingClosed(outcome);
  }

  void _open([AssistantStarter? starter]) {
    context.push(
      Routes.assistant,
      extra: starter == null
          ? null
          : AssistantChatArgs(initialPrompt: starter.promptKey.tr()),
    );
    _close(AssistantNudgeOutcome.opened);
  }

  void _dragUpdate(DragUpdateDetails details) {
    final delta = details.delta.dy;
    setState(() => _pull += _pull + delta > 0 ? delta * _pullResist : delta);
  }

  void _dragEnd(DragEndDetails details) {
    final fling = details.velocity.pixelsPerSecond.dy;
    if (_pull < _dismissDrag || fling < _dismissFling) {
      _close(AssistantNudgeOutcome.dismissed);
      return;
    }
    _settle.forward(from: 0);
    _runCountdown();
  }

  @override
  void dispose() {
    _joyTimer?.cancel();
    _travel.dispose();
    _presence.dispose();
    _countdown.dispose();
    _settle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nudge = _nudge;
    final lookAtWords = Directionality.of(context) == TextDirection.ltr
        ? _lookAtWords
        : Offset(-_lookAtWords.dx, _lookAtWords.dy);
    return BlocListener<AssistantBuddyCubit, AssistantBuddyState>(
      listenWhen: (previous, current) => previous.nudge != current.nudge,
      listener: _onBuddy,
      child: nudge == null
          ? const SizedBox.shrink()
          : SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s12,
                  vertical: AppSpacing.s8,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxWidth),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_travel, _settle]),
                      builder: (context, card) {
                        final t = _travel.value;
                        final pull = _pull * (1 - _settle.value);
                        return Transform.translate(
                          offset: Offset(0, pull),
                          child: FractionalTranslation(
                            translation: Offset(0, _hiddenLift * (1 - t)),
                            child: Transform.scale(
                              scale: _enterScale + (1 - _enterScale) * t,
                              alignment: Alignment.topCenter,
                              child: card,
                            ),
                          ),
                        );
                      },
                      // Slides in from fully above the screen: no fade (an
                      // opacity layer each frame) is needed, and the card is
                      // its own layer, so moving it repaints nothing.
                      child: RepaintBoundary(
                        child: Listener(
                          onPointerDown: (_) => _countdown.stop(),
                          onPointerUp: (_) => _runCountdown(),
                          onPointerCancel: (_) => _runCountdown(),
                          child: GestureDetector(
                            onVerticalDragStart: (_) => _settle.stop(),
                            onVerticalDragUpdate: _dragUpdate,
                            onVerticalDragEnd: _dragEnd,
                            child: AssistantBuddyGreetingCard(
                              nudge: nudge,
                              mood: _mood,
                              look: _typed ? Offset.zero : lookAtWords,
                              typed: _typed,
                              countdown: _countdown,
                              showCountdown: !MediaQuery.accessibleNavigationOf(
                                context,
                              ),
                              onTyped: _onTyped,
                              onOpen: _open,
                              onStarter: _open,
                              onClose: () =>
                                  _close(AssistantNudgeOutcome.dismissed),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
