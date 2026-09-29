import 'dart:async';

import 'package:flutter/material.dart';

import 'motion.dart';
import 'on_screen_gate.dart';
import 'vertical_swap_transition.dart';

/// One entry of a [RotatingLine]: a stable [id] (what the fact IS, not how it
/// reads) and the one-line [child] that shows it. A plain data class.
@immutable
class RotatingLineItem {
  const RotatingLineItem({required this.id, required this.child});

  final Object id;
  final Widget child;
}

/// THE one-line ticker (backlog BX-08: the Home announcement strip, the
/// search pill's hint, the assistant composer's hint, the checkout bar's
/// facts): shows one of [items] at a time; after [dwell] the next one rises
/// into place while the current one leaves above ([VerticalSwapTransition],
/// [AppMotion.entranceRise] of travel, [AppMotion.medium], signature in /
/// exit out). The rest between swaps is a [Timer], so NO frame is drawn while
/// resting.
///
/// Auto-rotation is ambient motion (§9.4 #21, #22), so it follows the
/// ambient rules: it stands still — no timer at all — with one item or
/// none, while [paused], under reduced motion, with a screen reader, with
/// `TickerMode` off (a hidden tab, a covered route), off screen or with the
/// app in the background ([OnScreenGate]); and it rotates for at most
/// [budget] per appearance ([AppMotion.ambientBudget]: a swap happens only
/// when its rest ends inside the budget — the first swap always does).
/// Every new appearance (back on screen, the tab shown again, the app
/// resumed) has a fresh budget. A `null` [budget] rotates for as long as the
/// line is on stage.
///
/// Items are matched by [RotatingLineItem.id], so a list that changes keeps
/// its place; an id that was not there before is shown NEXT, at once, and the
/// dwell restarts (the news goes first — a state change, never held back by
/// the budget).
///
/// While [paused] the line is frozen: the item on screen stays on screen —
/// its content updates in place when its id is still listed, and it is held
/// as it was when its id left — and no swap plays. The list the line
/// resumes with is compared with the one it paused on, so an id that only
/// left for the pause (a figure hidden while the cart re-prices) comes back
/// in place, not as news.
///
/// [onShown] hears the index of the item on screen once it changed (on the
/// frame after), for a position indicator.
///
/// Wrapped in its own [RepaintBoundary]. Excluded from semantics — the host
/// reads every item once through its own `Semantics` label.
class RotatingLine extends StatefulWidget {
  const RotatingLine({
    super.key,
    required this.items,
    this.dwell = AppMotion.carousel,
    this.paused = false,
    this.alignment = AlignmentDirectional.centerStart,
    this.budget = AppMotion.ambientBudget,
    this.onShown,
  });

  final List<RotatingLineItem> items;

  /// How long each item rests before the next one slides in.
  final Duration dwell;

  /// Holds the current item (the cart is updating, a sheet is on top …).
  final bool paused;
  final AlignmentDirectional alignment;

  /// Most rotating time per appearance; `null` = no limit.
  final Duration? budget;

  /// The index (in [items]) of the item now on screen, after it changed.
  final ValueChanged<int>? onShown;

  @override
  State<RotatingLine> createState() => RotatingLineState();
}

class RotatingLineState extends State<RotatingLine>
    with OnScreenGate<RotatingLine> {
  Timer? _rest;
  int _index = 0;

  /// Whether the line is on stage and ambient motion is allowed.
  bool _onStage = false;

  /// Rotating time spent in this appearance, and the swaps it played.
  Duration _spent = Duration.zero;
  int _swaps = 0;

  /// What the last build showed, and the index last told to [RotatingLine.onShown].
  RotatingLineItem? _shown;
  int _reported = 0;

  /// The item on screen whose id left the list while paused: shown as it
  /// was until the line resumes.
  RotatingLineItem? _held;

  /// The ids of the last list the line got while running: what the list it
  /// resumes with is compared with.
  Set<Object> _settledIds = const <Object>{};

  /// A rest timer is pending (the line will swap when it fires).
  @visibleForTesting
  bool get debugResting => _rest != null;

  /// The line may rotate here (on screen, ambient motion allowed), budget
  /// aside.
  @visibleForTesting
  bool get debugOnStage => _onStage;

  bool get _mayRun => _onStage && !widget.paused && widget.items.length > 1;

  static Set<Object> _idsOf(List<RotatingLineItem> items) => <Object>{
    for (final item in items) item.id,
  };

  @override
  void initState() {
    super.initState();
    _settledIds = _idsOf(widget.items);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restage();
  }

  @override
  void onScreenChanged() => _restage();

  /// Re-reads whether the line may move; coming back on stage is a new
  /// appearance, with a fresh budget.
  void _restage() {
    final onStage = MotionGuard.ambientAllowed(context) && onScreen;
    if (onStage && !_onStage) {
      _spent = Duration.zero;
      _swaps = 0;
    }
    _onStage = onStage;
    _sync();
  }

  @override
  void didUpdateWidget(RotatingLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    final items = widget.items;
    final shownId = _shown?.id;
    final at = shownId == null
        ? -1
        : items.indexWhere((item) => item.id == shownId);
    if (widget.paused) {
      // Frozen: keep what is on screen, in place or held as it was.
      if (at >= 0) {
        _index = at;
        _held = null;
      } else {
        _held = _shown;
      }
      _sync();
      return;
    }
    _held = null;
    final settled = _settledIds;
    _settledIds = _idsOf(items);
    final news = items.indexWhere((item) => !settled.contains(item.id));
    if (news >= 0) {
      _index = news;
      _stop();
      _sync(afterSwap: true);
      return;
    }
    _index = at < 0 ? 0 : at;
    if (widget.dwell != oldWidget.dwell) _stop();
    _sync();
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _stop() {
    _rest?.cancel();
    _rest = null;
  }

  /// Arms the rest when the line may run and the budget allows it, cancels
  /// it otherwise. Right after a swap the dwell starts once the incoming item
  /// has landed, so every item rests a full [RotatingLine.dwell] in place.
  void _sync({bool afterSwap = false}) {
    if (!_mayRun) {
      _stop();
      return;
    }
    if (_rest != null) return;
    final wait = afterSwap ? AppMotion.medium + widget.dwell : widget.dwell;
    final budget = widget.budget;
    if (budget != null && _swaps > 0 && _spent + wait > budget) return;
    _rest = Timer(wait, () => _advance(wait));
  }

  void _advance(Duration waited) {
    _rest = null;
    if (!mounted || widget.items.isEmpty) return;
    _spent += waited;
    _swaps++;
    setState(() => _index = (_index + 1) % widget.items.length);
    _sync(afterSwap: true);
  }

  /// Tells [RotatingLine.onShown] about a new index, after this frame.
  void _report(int index) {
    if (index == _reported || widget.onShown == null) return;
    _reported = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && index == _reported) widget.onShown?.call(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final item = _held ?? (items.isEmpty ? null : items[_index % items.length]);
    _shown = item;
    if (item == null) return const SizedBox.shrink();
    if (_held == null) _report(_index % items.length);
    final shown = ValueKey<Object>(item.id);
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: ClipRect(
          child: AnimatedSwitcher(
            duration: MotionGuard.duration(context, AppMotion.medium),
            switchInCurve: AppMotion.signature,
            switchOutCurve: AppMotion.exit,
            layoutBuilder: (incoming, previous) => Stack(
              alignment: widget.alignment,
              children: <Widget>[...previous, ?incoming],
            ),
            transitionBuilder: (child, animation) => VerticalSwapTransition(
              animation: animation,
              incoming: child.key == shown,
              child: child,
            ),
            child: KeyedSubtree(key: shown, child: item.child),
          ),
        ),
      ),
    );
  }
}
