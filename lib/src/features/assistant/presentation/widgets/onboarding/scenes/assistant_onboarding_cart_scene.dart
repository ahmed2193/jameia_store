import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_spacing.dart';
import '../../../../../../core/motion/fly_to_cart.dart';
import '../../../../../../core/motion/haptics.dart';
import '../../../../../../core/motion/motion.dart';
import '../../../../../../core/responsive/app_size.dart';
import '../assistant_onboarding_cue.dart';
import '../assistant_onboarding_timeline.dart';
import 'assistant_onboarding_cart_badge.dart';
import 'assistant_onboarding_ghost_finger.dart';
import 'assistant_onboarding_item.dart';
import 'assistant_onboarding_item_glyph.dart';
import 'assistant_onboarding_proposal_card.dart';

/// "I fill the cart — you decide": the assistant proposes the items (the
/// mascot talks) and waits. The customer can tap Confirm themselves; when
/// they do not, a ghost finger shows how. Confirmed, the items go into the
/// cart the way every add does in the app — and the real chat's confirm
/// now does too (docs/motion §9.6 §2.6, §2.12): up to three thumbnails fly
/// from the lines to the demo's cart ([FlyToCart], `staggerStep` apart), its
/// count waits for the first landing, and on that landing the mascot cheers
/// (and the customer's own confirm ticks once, like an add). No confetti.
/// The demo plays once per opening of the tour. Reduced motion: no flight,
/// the count changes at once.
class AssistantOnboardingCartScene extends StatefulWidget {
  const AssistantOnboardingCartScene({
    super.key,
    required this.active,
    this.played = false,
    required this.onCue,
  });

  final bool active;

  /// Its demo already played in this opening of the tour: its end, at once.
  final bool played;
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
  static const double _thumb = AppSize.s32;

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

  late final AnimationController _ghost = AnimationController(
    vsync: this,
    duration: _ghostLength,
  )..addListener(_onGhost);

  /// Where the flights land: the demo's own cart, while this demo is up.
  final GlobalKey _cart = GlobalKey();
  final Map<AssistantOnboardingItem, GlobalKey> _lines = {
    for (final item in AssistantOnboardingItem.values) item: GlobalKey(),
  };
  final List<Timer> _flights = [];

  Timer? _ghostDue;
  bool _confirmed = false;
  bool _waitingLanding = false;
  bool _byCustomer = false;

  @override
  void initState() {
    super.initState();
    FlyToCart.pushTarget(_cart);
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
    _ghostDue?.cancel();
    if (!byGhost) {
      _ghost
        ..stop()
        ..value = 0;
    }
    _byCustomer = !byGhost;
    final flew = _fly();
    setState(() => _confirmed = true);
    if (flew) {
      _waitingLanding = true;
      FlyToCart.landings.addListener(_onLanding);
    } else {
      _landed();
    }
  }

  /// Up to three thumbnails, `staggerStep` apart; whether the first took off.
  bool _fly() {
    final items = AssistantOnboardingItem.values.take(FlyToCart.maxFlights);
    var first = false;
    for (final (index, item) in items.indexed) {
      void launch() {
        if (!mounted) return;
        final took = FlyToCart.fly(
          context,
          sourceKey: _lines[item]!,
          thumbSize: _thumb,
          thumbnail: AssistantOnboardingItemGlyph(item: item, size: _thumb),
        );
        if (index == 0) first = took;
      }

      if (index == 0) {
        launch();
      } else {
        _flights.add(Timer(AppMotion.staggerStep * index, launch));
      }
    }
    return first;
  }

  void _onLanding() {
    if (!_waitingLanding) return;
    _waitingLanding = false;
    FlyToCart.landings.removeListener(_onLanding);
    _landed();
  }

  /// In the cart: the customer's own confirm ticks like an add, and the
  /// mascot cheers (while this step is in front).
  void _landed() {
    if (!mounted) return;
    if (_byCustomer) Haptics.cartAdd();
    if (widget.active) widget.onCue(AssistantOnboardingCue.cheer);
  }

  @override
  void dispose() {
    FlyToCart.popTarget(_cart);
    FlyToCart.landings.removeListener(_onLanding);
    for (final flight in _flights) {
      flight.cancel();
    }
    _ghostDue?.cancel();
    _ghost.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AssistantOnboardingTimeline(
      active: widget.active,
      played: widget.played,
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
                  cartKey: _cart,
                  count: _confirmed ? AssistantOnboardingItem.totalQuantity : 0,
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
                  lineKeys: _lines,
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
    );
  }
}
