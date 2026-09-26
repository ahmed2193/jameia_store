import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/motion/motion.dart';
import '../../domain/entities/home_section_entity.dart';
import 'home_category_entrance.dart';
import 'home_category_tile.dart';
import 'home_layout.dart';
import 'home_reveal_scope.dart';
import 'home_section_block.dart';

/// "Shop by category": the store's aisles as storefront tiles that scroll
/// sideways. The feed carries the whole tree (parents with their children),
/// so a long shelf runs in two rows — twice the aisles in view — while a
/// short one stays a single row. "View all" opens the full tree.
///
/// The shelf moves by itself: its tiles pop in, column by column, as its
/// block comes in ([HomeRevealScope]); their washes drift on one shared
/// clock; and a shelf longer than the screen glides to its end, rests, and
/// glides back. A finger on the shelf stops it; it picks up again after
/// [AppMotion.carousel] of quiet. All of it rests while the block is off
/// screen or behind another tab, and none of it runs under reduced motion
/// or with a screen reader on.
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

  @override
  State<HomeCategoryGrid> createState() => _HomeCategoryGridState();
}

class _HomeCategoryGridState extends State<HomeCategoryGrid>
    with SingleTickerProviderStateMixin {
  static const double _rowGap = AppSpacing.s12;

  /// How close to an end of the shelf counts as there.
  static const double _endSlack = 1;

  final ScrollController _scroll = ScrollController();
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: AppMotion.glowPulse,
  );
  Timer? _rest;
  bool _forward = true;
  bool _gliding = false;
  int _fingers = 0;

  /// Reduced motion, or a screen reader walking the page.
  bool _still = false;

  /// On screen, with the tab and the route in front.
  bool _onScreen = true;

  bool get _live =>
      !_still && _onScreen && widget.section.categories.isNotEmpty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still =
        MotionGuard.reduced(context) ||
        MediaQuery.accessibleNavigationOf(context);
    _onScreen =
        HomeRevealScope.onScreenOf(context) &&
        TickerMode.valuesOf(context).enabled;
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
  void dispose() {
    _rest?.cancel();
    _ambient.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Starts or stops the wash and the glide to match [_live].
  void _sync() {
    if (_live) {
      if (!_ambient.isAnimating) _ambient.repeat();
      if (!_gliding && !(_rest?.isActive ?? false)) _restThenGlide();
      return;
    }
    _ambient.stop();
    _rest?.cancel();
    if (_gliding) {
      // Not from inside a build: stopping a scroll sends notifications.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _gliding && !_live && _scroll.hasClients) {
          _scroll.jumpTo(_scroll.offset);
        }
      });
    }
  }

  void _restThenGlide() {
    _rest?.cancel();
    if (!_live || _fingers > 0) return;
    _rest = Timer(AppMotion.carousel, _glide);
  }

  Future<void> _glide() async {
    if (!mounted || !_live || _fingers > 0 || !_scroll.hasClients) return;
    final position = _scroll.position;
    final start = position.minScrollExtent;
    final end = position.maxScrollExtent;
    // The whole shelf is in view: nothing to glide to.
    if (end - start <= _endSlack) return;
    if (position.pixels >= end - _endSlack) {
      _forward = false;
    } else if (position.pixels <= start + _endSlack) {
      _forward = true;
    }
    final target = _forward ? end : start;
    final seconds =
        (target - position.pixels).abs() / HomeCategoryGrid.glideSpeed;
    _gliding = true;
    await _scroll.animateTo(
      target,
      duration: Duration(
        microseconds: (seconds * Duration.microsecondsPerSecond).round(),
      ),
      curve: Curves.linear,
    );
    _gliding = false;
    // A finger stopped it: lifting the finger re-arms the glide. Otherwise
    // it reached an end, or was stopped for going off screen: rest, and
    // carry on if the shelf is still live.
    if (mounted && _fingers == 0) _restThenGlide();
  }

  void _touch(PointerDownEvent event) {
    _fingers++;
    _rest?.cancel();
  }

  void _lift(PointerEvent event) {
    if (_fingers > 0) _fingers--;
    if (_fingers == 0) _restThenGlide();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.section.categories;
    if (categories.isEmpty) return const SizedBox.shrink();
    final rows = categories.length > HomeCategoryGrid.singleRowMax ? 2 : 1;
    final cell = HomeCategoryTile.cellHeight(context);
    final reveal = HomeRevealScope.revealOf(context);
    return HomeSectionBlock(
      section: widget.section,
      onSeeAll: widget.onViewAll,
      child: SizedBox(
        height: cell * rows + _rowGap * (rows - 1),
        // The scrollable stops a glide on touch by itself; this only counts
        // fingers, so the glide waits for the last one to lift.
        child: Listener(
          onPointerDown: _touch,
          onPointerUp: _lift,
          onPointerCancel: _lift,
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
    );
  }
}
