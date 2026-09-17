import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/entities/jameia_category_entity.dart';
import '../util/category_display.dart';

/// "Shop by category" — ported 1:1 from jm3eia's `HomeCategoriesWidget`.
///
/// A horizontally-scrolling carousel of COLUMNS: each column stacks
/// [_kRowsPerColumn] tiles, a visible "page" is [_kVisibleColumns] columns, and
/// extra categories scroll horizontally with paging dots underneath. Each tile
/// is a white rounded card with the category's network artwork (contain, never
/// cropped) and a width-scaled 2-line label. Auto-advances one column at a
/// time, pausing while the user drags and when backgrounded.
class JameiaCategoriesRail extends StatefulWidget {
  const JameiaCategoriesRail({
    super.key,
    required this.categories,
    required this.onOpenCategory,
    this.onViewAll,
  });

  final List<JameiaCategoryEntity> categories;

  /// (categoryId) → open that category's shop.
  final ValueChanged<String> onOpenCategory;

  /// Header "View all" action; hidden when null.
  final VoidCallback? onViewAll;

  @override
  State<JameiaCategoriesRail> createState() => _JameiaCategoriesRailState();
}

const int _kRowsPerColumn = 3;
const int _kVisibleColumns = 4;
const double _kCellAspect = 0.96;
const Duration _kAutoScrollEvery = Duration(milliseconds: 1600);
const Duration _kAutoScrollAnim = Duration(milliseconds: 400);
const Duration _kResumeUserIdle = Duration(seconds: 3);

class _JameiaCategoriesRailState extends State<JameiaCategoriesRail>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  Timer? _resumeTimer;
  bool _userInteracting = false;

  // Whether this rail is actually on-screen. The home tab lives inside the
  // shell's IndexedStack, so it stays mounted (and ticking) while the user is on
  // other tabs; off-tab children are Offstage and report 0% visible. Auto-scroll
  // is paused whenever this is false so the timer does not burn CPU off-screen.
  bool _visible = true;

  // Latest layout metrics from build, so the visibility handler can restart the
  // timer with the right column geometry when the rail becomes visible again.
  int _lastColumnCount = 0;
  double _lastColumnWidth = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _autoScrollTimer?.cancel();
      _autoScrollTimer = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoScrollTimer?.cancel();
    _resumeTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _ensureAutoScroll(int columnCount, double columnWidth) {
    _lastColumnCount = columnCount;
    _lastColumnWidth = columnWidth;
    // Pause off-screen (tab switch) or when there is nothing to scroll.
    if (!_visible || columnCount <= _kVisibleColumns) {
      _autoScrollTimer?.cancel();
      _autoScrollTimer = null;
      return;
    }
    if (_autoScrollTimer != null) return;
    _autoScrollTimer = Timer.periodic(_kAutoScrollEvery, (_) {
      if (!mounted || !_scrollController.hasClients || _userInteracting) return;
      final pos = _scrollController.position;
      final next = pos.pixels + columnWidth;
      final target = next >= pos.maxScrollExtent - 1 ? 0.0 : next;
      _scrollController.animateTo(
        target,
        duration: _kAutoScrollAnim,
        curve: AppMotion.machEaseInOut,
      );
    });
  }

  void _onUserDown() {
    _userInteracting = true;
    _resumeTimer?.cancel();
  }

  void _onUserUp() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(_kResumeUserIdle, () {
      if (!mounted) return;
      _userInteracting = false;
    });
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;
    final visible = info.visibleFraction > 0;
    if (visible == _visible) return;
    _visible = visible;
    if (_visible) {
      _ensureAutoScroll(_lastColumnCount, _lastColumnWidth);
    } else {
      _autoScrollTimer?.cancel();
      _autoScrollTimer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = widget.categories;
    if (cats.isEmpty) return const SizedBox.shrink();

    return VisibilityDetector(
      key: const ValueKey('jameia-categories-rail-visibility'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _CategoriesHeader(onViewAll: widget.onViewAll),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final columnWidth = availableWidth / _kVisibleColumns;
              final cellHeight = columnWidth * _kCellAspect;
              final containerHeight = cellHeight * _kRowsPerColumn;
              final labelFontSize = (columnWidth * 0.1)
                  .clamp(9.0, 11.0)
                  .toDouble();
              final columnCount = (cats.length / _kRowsPerColumn).ceil();
              final pageCount = (columnCount / _kVisibleColumns).ceil();

              _ensureAutoScroll(columnCount, columnWidth);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: availableWidth,
                    height: containerHeight,
                    child: Listener(
                      onPointerDown: (_) => _onUserDown(),
                      onPointerUp: (_) => _onUserUp(),
                      onPointerCancel: (_) => _onUserUp(),
                      child: ListView.builder(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: columnCount,
                        itemExtent: columnWidth,
                        addAutomaticKeepAlives: false,
                        addRepaintBoundaries: false,
                        itemBuilder: (context, index) {
                          final start = index * _kRowsPerColumn;
                          final end = math.min(
                            start + _kRowsPerColumn,
                            cats.length,
                          );
                          return _CategoriesColumn(
                            key: ValueKey('cats_col_$index'),
                            width: columnWidth,
                            itemHeight: cellHeight,
                            labelFontSize: labelFontSize,
                            slice: cats.sublist(start, end),
                            onOpenCategory: widget.onOpenCategory,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _CategoryPageDots(
                    controller: _scrollController,
                    pageCount: pageCount,
                    pageWidth: availableWidth,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// "Shop by category" header — bold title on the leading edge, orange "View all"
/// action on the trailing edge (hidden when no handler is supplied).
class _CategoriesHeader extends StatelessWidget {
  const _CategoriesHeader({this.onViewAll});
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'home.shop_by_category'.tr(),
            style: const TextStyle(
              fontSize: AppSize.font16,
              fontWeight: FontWeight.w700,
              color: kJameiaSectionTitle,
            ),
          ),
        ),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: Text(
                'home.view_all'.tr(),
                style: const TextStyle(
                  fontSize: AppSize.font14,
                  fontWeight: FontWeight.w600,
                  color: kJameiaViewAll,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoriesColumn extends StatelessWidget {
  const _CategoriesColumn({
    super.key,
    required this.width,
    required this.itemHeight,
    required this.labelFontSize,
    required this.slice,
    required this.onOpenCategory,
  });

  final double width;
  final double itemHeight;
  final double labelFontSize;
  final List<JameiaCategoryEntity> slice;
  final ValueChanged<String> onOpenCategory;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final c in slice)
            SizedBox(
              key: ValueKey('cat_${c.id}'),
              width: width,
              height: itemHeight,
              child: _CategoryCard(
                category: c,
                labelFontSize: labelFontSize,
                onTap: () => onOpenCategory(c.id),
              ),
            ),
        ],
      ),
    );
  }
}

/// One "Shop by category" tile — a floating white card (soft shadow, rounded
/// corners) with the category artwork on top (flex 2) and a bold centred label
/// beneath (flex 1). The image uses `contain` so the whole product is always
/// visible; [labelFontSize] is width-scaled so long names never clip.
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.labelFontSize,
    required this.onTap,
  });

  final JameiaCategoryEntity category;
  final double labelFontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsetsDirectional.symmetric(
          horizontal: 6,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSize.r14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryText.withValues(alpha: 0.10),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
            BoxShadow(
              color: AppColors.primaryText.withValues(alpha: 0.10),
              blurRadius: 2,
              spreadRadius: -1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: category.image.isEmpty
                  ? const SizedBox.shrink()
                  : JameiaImage(
                      url: category.image,
                      fit: BoxFit.contain,
                      radius: 8,
                    ),
            ),
            const SizedBox(height: 4),
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  category.displayName,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                    fontSize: labelFontSize,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paging dots under the carousel: one 6dp dot per page (a page =
/// [_kVisibleColumns] columns). Active dot derived from the scroll offset.
class _CategoryPageDots extends StatelessWidget {
  const _CategoryPageDots({
    required this.controller,
    required this.pageCount,
    required this.pageWidth,
  });

  final ScrollController controller;
  final int pageCount;
  final double pageWidth;

  @override
  Widget build(BuildContext context) {
    if (pageCount <= 1 || pageWidth <= 0) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final pixels = controller.hasClients ? controller.position.pixels : 0.0;
        final active = (pixels / pageWidth).round().clamp(0, pageCount - 1);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < pageCount; i++)
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == active ? kJameiaDotActive : kJameiaDotInactive,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
