import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_colors.dart';
import '../../../../../../config/theme/app_spacing.dart';
import '../../../../../../core/motion/haptics.dart';
import '../../../../../../core/motion/motion.dart';
import '../../../../../../core/motion/motion_widgets.dart';
import '../../../../../../core/motion/spring_curve.dart';
import '../assistant_onboarding_cue.dart';
import '../assistant_onboarding_timeline.dart';
import 'assistant_onboarding_cart_badge.dart';
import 'assistant_onboarding_ghost_finger.dart';
import 'assistant_onboarding_item.dart';
import 'assistant_onboarding_proposal_card.dart';

/// "I fill the cart — you decide": the assistant proposes the items (the
/// mascot talks) and waits. The customer can tap Confirm themselves; when
/// they do not, a ghost finger shows how. Confirmed, the items land in the
/// cart — it bumps, confetti flies and the mascot cheers. Played again, it
/// starts over unconfirmed.
class AssistantOnboardingCartScene extends StatefulWidget {
  const AssistantOnboardingCartScene({
    super.key,
    required this.active,
    required this.onCue,
  });

  final bool active;
  final ValueChanged<AssistantOnboardingCue> onCue;

  @override
  State<AssistantOnboardingCartScene> createState() =>
      _AssistantOnboardingCartSceneState();
}

class _AssistantOnboardingCartSceneState
    extends State<AssistantOnboardingCartScene>
    with SingleTickerProviderStateMixin {
  static const Duration _length = Duration(milliseconds: 1400);
  static const Duration _ghostAfter = Duration(milliseconds: 1600);
  static const Duration _ghostLength = Duration(milliseconds: 1500);
  static const List<AssistantOnboardingBeat> _beats = [
    (0.05, AssistantOnboardingCue.talk),
    (0.75, AssistantOnboardingCue.rest),
  ];
  static const double _cardStart = AppSpacing.s16;
  static const double _cardTop = AppSpacing.s15;
  static const double _badgeInset = AppSpacing.s14;
  static const double _badgeIn = 0.3;

  /// The ghost enters from below the stage's end corner and aims at the
  /// middle of Confirm (start-based design space).
  static const Offset _ghostFrom = Offset(292, 214);
  static const Offset _confirmAt = Offset(
    _cardStart + AssistantOnboardingProposalCard.width / 2,
    _cardTop +
        AssistantOnboardingProposalCard.height -
        AssistantOnboardingProposalCard.padding -
        AssistantOnboardingProposalCard.buttonHeight / 2,
  );

  /// The part of the ghost's run that holds Confirm down.
  static const double _pressFrom = 0.58;
  static const double _pressTo = 0.8;

  /// The confetti flies from the cart (end-top), in fractions of the stage.
  static const Offset _burstFrom = Offset(0.89, 0.17);
  static const int _burstCount = 36;
  static const List<Color> _confetti = [
    AppColors.primary,
    AppColors.accent3,
    AppColors.accent1,
    AppColors.proAmber,
    AppColors.accentViolet,
  ];

  late final AnimationController _ghost = AnimationController(
    vsync: this,
    duration: _ghostLength,
  )..addListener(_onGhost);

  Timer? _ghostDue;
  bool _confirmed = false;
  int _bursts = 0;

  @override
  void didUpdateWidget(AssistantOnboardingCartScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active && !widget.active) _reset();
  }

  /// Left for another step: back to an unconfirmed proposal for next time.
  void _reset() {
    _ghostDue?.cancel();
    _confirmed = false;
    _ghost
      ..stop()
      ..value = 0;
  }

  /// The proposal is in: when the customer does not try it, the ghost does.
  void _onIntroDone() {
    if (!widget.active || _confirmed || MotionGuard.reduced(context)) return;
    _ghostDue?.cancel();
    _ghostDue = Timer(_ghostAfter, () {
      if (mounted && widget.active && !_confirmed) _ghost.forward(from: 0);
    });
  }

  void _onGhost() {
    if (!_confirmed && _ghost.value >= AssistantOnboardingGhostFinger.tapAt) {
      _confirm(byGhost: true);
    }
  }

  void _confirm({bool byGhost = false}) {
    if (_confirmed) return;
    _confirmed = true;
    _ghostDue?.cancel();
    if (!byGhost) {
      Haptics.success();
      _ghost
        ..stop()
        ..value = 0;
    }
    setState(() => _bursts++);
    widget.onCue(AssistantOnboardingCue.cheer);
  }

  @override
  void dispose() {
    _ghostDue?.cancel();
    _ghost.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return ConfettiBurst(
      playKey: _bursts == 0 ? null : _bursts,
      colors: _confetti,
      origin: rtl ? Offset(1 - _burstFrom.dx, _burstFrom.dy) : _burstFrom,
      count: _burstCount,
      child: AssistantOnboardingTimeline(
        active: widget.active,
        length: _length,
        beats: _beats,
        onCue: widget.onCue,
        onDone: _onIntroDone,
        builder: (context, t) => AnimatedBuilder(
          animation: _ghost,
          builder: (context, _) {
            final ghost = _ghost.value;
            return Stack(
              children: [
                PositionedDirectional(
                  top: _badgeInset,
                  end: _badgeInset,
                  child: AssistantOnboardingCartBadge(
                    count: _confirmed
                        ? AssistantOnboardingItem.totalQuantity
                        : 0,
                    appear: t.span(0, _badgeIn, AppSprings.snappy),
                  ),
                ),
                PositionedDirectional(
                  start: _cardStart,
                  top: _cardTop,
                  child: AssistantOnboardingProposalCard(
                    progress: t,
                    confirmed: _confirmed,
                    pressed: ghost > _pressFrom && ghost < _pressTo,
                    onConfirm: _confirm,
                  ),
                ),
                AssistantOnboardingGhostFinger(
                  progress: ghost,
                  from: _ghostFrom,
                  to: _confirmAt,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
