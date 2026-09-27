import 'dart:async';

import 'package:flutter/material.dart';

import 'motion.dart';

/// One entry of a [RotatingLine]: a stable [id] (what the fact IS, not how it
/// reads) and the one-line [child] that shows it. A plain data class.
@immutable
class RotatingLineItem {
  const RotatingLineItem({required this.id, required this.child});

  final Object id;
  final Widget child;
}

/// A one-line ticker: shows one of [items] at a time; after [dwell] the next
/// one slides up from below while the current one leaves above (clipped,
/// [AppMotion.flip], signature in / exit out). The rest between swaps is a
/// [Timer], so NO frame is drawn while resting (the `LightSweep` pattern). It
/// stands still — no timer at all — with one item or none, while [paused],
/// under reduced motion, or with `TickerMode` off (a covered route, a placed
/// checkout).
///
/// Items are matched by [RotatingLineItem.id], so a list that changes keeps
/// its place; an id that was not there before is shown NEXT, at once, and the
/// dwell restarts (the news goes first).
///
/// While [paused] the line is frozen: the item on screen stays on screen —
/// its content updates in place when its id is still listed, and it is held
/// as it was when its id left — and no swap plays. The list the line
/// resumes with is compared with the one it paused on, so an id that only
/// left for the pause (a figure hidden while the cart re-prices) comes back
/// in place, not as news.
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
  });

  final List<RotatingLineItem> items;

  /// How long each item rests before the next one slides in.
  final Duration dwell;

  /// Holds the current item (the cart is updating, a sheet is on top …).
  final bool paused;
  final AlignmentDirectional alignment;

  @override
  State<RotatingLine> createState() => RotatingLineState();
}

class RotatingLineState extends State<RotatingLine> {
  static const Offset _below = Offset(0, 1);
  static const Offset _above = Offset(0, -1);

  Timer? _rest;
  int _index = 0;

  /// Whether the page is on stage and motion is allowed.
  bool _onStage = false;

  /// What the last build showed.
  RotatingLineItem? _shown;

  /// The item on screen whose id left the list while paused: shown as it
  /// was until the line resumes.
  RotatingLineItem? _held;

  /// The ids of the last list the line got while running: what the list it
  /// resumes with is compared with.
  Set<Object> _settledIds = const <Object>{};

  /// A rest timer is pending (the line will swap when it fires).
  @visibleForTesting
  bool get debugResting => _rest != null;

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
    _onStage =
        TickerMode.valuesOf(context).enabled && !MotionGuard.reduced(context);
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

  /// Arms the rest when the line may run, cancels it otherwise. Right after
  /// a swap the dwell starts once the incoming item has landed, so every item
  /// rests a full [RotatingLine.dwell] in place.
  void _sync({bool afterSwap = false}) {
    if (!_mayRun) {
      _stop();
      return;
    }
    _rest ??= Timer(
      afterSwap ? AppMotion.flip + widget.dwell : widget.dwell,
      _advance,
    );
  }

  void _advance() {
    _rest = null;
    if (!mounted || widget.items.isEmpty) return;
    setState(() => _index = (_index + 1) % widget.items.length);
    _sync(afterSwap: true);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final item = _held ?? (items.isEmpty ? null : items[_index % items.length]);
    _shown = item;
    if (item == null) return const SizedBox.shrink();
    final shown = ValueKey<Object>(item.id);
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: ClipRect(
          child: AnimatedSwitcher(
            duration: MotionGuard.duration(context, AppMotion.flip),
            switchInCurve: AppMotion.signature,
            switchOutCurve: AppMotion.exit,
            layoutBuilder: (incoming, previous) => Stack(
              alignment: widget.alignment,
              children: <Widget>[...previous, ?incoming],
            ),
            transitionBuilder: (child, animation) {
              // The outgoing child runs its animation backwards (1 → 0), so
              // it travels from its place to [_above].
              final begin = child.key == shown ? _below : _above;
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: animation.drive(
                    Tween<Offset>(begin: begin, end: Offset.zero),
                  ),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(key: shown, child: item.child),
          ),
        ),
      ),
    );
  }
}
