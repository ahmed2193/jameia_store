import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/motion/entrance_arrival.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/on_screen_gate.dart';
import '../../domain/entities/home_section_entity.dart';
import 'home_category_entrance.dart';
import 'home_category_tile.dart';
import 'home_layout.dart';
import 'home_section_block.dart';

/// "Shop by category": the store's aisles as storefront tiles that scroll
/// sideways. The feed carries the whole tree (parents with their children),
/// so a long shelf runs in two rows — twice the aisles in view — while a
/// short one stays a single row. "View all" opens the full tree.
///
/// The shelf moves by itself: its tiles pop in, column by column, as its
/// block first comes in ([EntranceArrival]); then, in bursts of at most
/// [AppMotion.ambientBudget] with an [AppMotion.carousel] rest before each
/// (BX-03, WCAG 2.2.2), a shelf longer than the screen glides towards its
/// end and back while the tiles' washes drift on one shared clock (a shelf
/// that fits the screen only washes). Between bursts nothing ticks. A
/// finger on the shelf or a scroll of it stops everything; it picks up
/// again after a full rest of quiet. All of it rests while the shelf is off
/// screen, behind another tab or the app is in the background, and none of
/// it runs under reduced motion or with a screen reader on.
class HomeCategoryGrid extends StatefulWidget {
  const HomeCategoryGrid({
    super.key,
    required this.section,
    required this.onOpenCategory,
    required this.onViewAll,
  });

  final HomeCategoryRailSection section;
  final ValueChanged<CatalogCategoryEntity> onOpenCategory;
  final VoidCallback onViewAll;

  /// Up to this many aisles fit one row; more take two.
  static const int singleRowMax = 6;

  /// How fast the shelf glides, in logical pixels a second.
  static const double glideSpeed = 26;

  /// The farthest one burst glides: [glideSpeed] for one ambient budget.
  static final double burstReach =
      glideSpeed *
      AppMotion.ambientBudget.inMicroseconds /
      Duration.microsecondsPerSecond;

  @override
  State<HomeCategoryGrid> createState() => _HomeCategoryGridState();
}

class _HomeCategoryGridState extends State<HomeCategoryGrid>
    with SingleTickerProviderStateMixin, OnScreenGate<HomeCategoryGrid> {
  static const double _rowGap = AppSpacing.s12;

  /// How close to an end of the shelf counts as there.
  static const double _endSlack = 1;

  /// One full cycle of the tiles' ambient wash (the shared clock).
  static const Duration _washCycle = Duration(milliseconds: 5000);

  final ScrollController _scroll = ScrollController();
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: _washCycle,
  );

  /// The still quiet before the next burst.
  Timer? _rest;

  /// Ends a wash-only burst (nothing to glide to).
  Timer? _burst;
  bool _forward = true;
  bool _gliding = false;
  int _fingers = 0;

  /// The customer is scrolling the shelf: a drag, then its fling.
  bool _scrolling = false;

  /// Not reduced, no screen reader, the tab and route in front.
  bool _allowed = false;

  bool get _live =>
      _allowed && onScreen && widget.section.categories.isNotEmpty;

  bool get _held => _fingers > 0 || _scrolling;

  bool get _bursting => _burst?.isActive ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _allowed = MotionGuard.ambientAllowed(context);
    _sync();
  }

  /// A refresh that changes the shelf's length moves its end: a glide aimed
  /// at the old end would stop short or overshoot, so start over from here.
  @override
  void didUpdateWidget(covariant HomeCategoryGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section.categories.length ==
        widget.section.categories.length) {
      return;
    }
    _rest?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_gliding && _scroll.hasClients) {
        // Ends the glide, which then re-arms itself.
        _scroll.jumpTo(_scroll.offset);
      } else {
        _sync();
      }
    });
  }

  @override
  void onScreenChanged() => _sync();

  @override
  void dispose() {
    _rest?.cancel();
    _burst?.cancel();
    _ambient.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Starts the rhythm, or stops all of it, to match [_live].
  void _sync() {
    if (_live) {
      if (!_gliding && !_bursting && !(_rest?.isActive ?? false)) {
        _restThenMove();
      }
      return;
    }
    _rest?.cancel();
    _pauseWash();
    if (_gliding) {
      // Not from inside a build: stopping a scroll sends notifications.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _gliding && !_live && _scroll.hasClients) {
          _scroll.jumpTo(_scroll.offset);
        }
      });
    }
  }

  void _pauseWash() {
    _burst?.cancel();
    _burst = null;
    _ambient.stop();
  }

  void _restThenMove() {
    _rest?.cancel();
    if (!_live || _held) return;
    _rest = Timer(AppMotion.carousel, _move);
  }

  /// One burst: a glide of at most [HomeCategoryGrid.burstReach] with the
  /// wash on, or the wash alone when the whole shelf is in view.
  Future<void> _move() async {
    if (!mounted || !_live || _held || !_scroll.hasClients) return;
    final position = _scroll.position;
    final start = position.minScrollExtent;
    final end = position.maxScrollExtent;
    if (end - start <= _endSlack) {
      _washBurst();
      return;
    }
    if (position.pixels >= end - _endSlack) {
      _forward = false;
    } else if (position.pixels <= start + _endSlack) {
      _forward = true;
    }
    final reach = HomeCategoryGrid.burstReach;
    final target = _forward
        ? math.min(end, position.pixels + reach)
        : math.max(start, position.pixels - reach);
    final seconds =
        (target - position.pixels).abs() / HomeCategoryGrid.glideSpeed;
    _gliding = true;
    _ambient.repeat();
    await _scroll.animateTo(
      target,
      duration: Duration(
        microseconds: (seconds * Duration.microsecondsPerSecond).round(),
      ),
      curve: AppMotion.linear,
    );
    _gliding = false;
    if (!mounted) return;
    _ambient.stop();
    // A finger or a scroll stopped it: their end re-arms the rest.
    // Otherwise the burst is over, or it was stopped for going off screen:
    // rest, and carry on if the shelf is still live.
    if (!_held) _restThenMove();
  }

  void _washBurst() {
    _ambient.repeat();
    _burst?.cancel();
    _burst = Timer(AppMotion.ambientBudget, () {
      _burst = null;
      if (!mounted) return;
      _ambient.stop();
      _restThenMove();
    });
  }

  void _touch(PointerDownEvent event) {
    _fingers++;
    _rest?.cancel();
    _pauseWash();
  }

  void _lift(PointerEvent event) {
    if (_fingers > 0) _fingers--;
    if (_fingers == 0) _restThenMove();
  }

  /// The customer's own scroll of the shelf (not the glide, which has no
  /// drag) holds the rhythm until it settles.
  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _scrolling = true;
      _rest?.cancel();
      _pauseWash();
    } else if (notification is ScrollEndNotification && _scrolling) {
      _scrolling = false;
      if (_fingers == 0) _restThenMove();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.section.categories;
    if (categories.isEmpty) return const SizedBox.shrink();
    final rows = categories.length > HomeCategoryGrid.singleRowMax ? 2 : 1;
    final cell = HomeCategoryTile.cellHeight(context);
    final reveal = EntranceArrival.of(context);
    return HomeSectionBlock(
      section: widget.section,
      onSeeAll: widget.onViewAll,
      child: SizedBox(
        height: cell * rows + _rowGap * (rows - 1),
        // The scrollable stops a glide on touch by itself; this only counts
        // fingers, so the rhythm waits for the last one to lift.
        child: Listener(
          onPointerDown: _touch,
          onPointerUp: _lift,
          onPointerCancel: _lift,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: GridView.builder(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: HomeLayout.gutter,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: rows,
                mainAxisExtent: HomeCategoryTile.width,
                mainAxisSpacing: HomeLayout.itemGap,
                crossAxisSpacing: _rowGap,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) => HomeCategoryEntrance(
                key: ValueKey<String>(categories[index].id),
                animation: reveal,
                column: index ~/ rows,
                child: HomeCategoryTile(
                  category: categories[index],
                  index: index,
                  ambient: _ambient,
                  onTap: () => widget.onOpenCategory(categories[index]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
