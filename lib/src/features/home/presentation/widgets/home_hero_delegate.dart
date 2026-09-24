import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/responsive/app_size.dart';
import 'home_hero_deliver_to.dart';
import 'home_hero_search_field.dart';
import 'home_notifications_bell.dart';

/// The collapsing home hero.
///
///   * Expanded (top of the feed) — the brand band carrying the delivery line
///     (`Deliver to <place>`) with the notifications bell beside it, the
///     search field under them, and the white seam the feed rises out of.
///   * Collapsed (scrolled up) — the band fades to white, the delivery line
///     goes with it and the search field slides up into the bar and STAYS
///     there, so search is one tap away anywhere in the feed.
///
/// Home is a root shell tab, so there is no leading back button. The app pins
/// `ThemeMode.light`, so the light literals (`AppColors.white` /
/// `AppColors.primaryText`) are the right ones.
class HomeHeroDelegate extends SliverPersistentHeaderDelegate {
  HomeHeroDelegate({
    required this.placeLabel,
    required this.topPad,
    required this.onAddressTap,
    required this.onSearch,
    required this.onNotifications,
    required this.hasUnreadNotifications,
  });

  final String placeLabel;

  /// The status-bar inset the band sits below.
  final double topPad;
  final VoidCallback onAddressTap;
  final VoidCallback onSearch;
  final VoidCallback onNotifications;
  final bool hasUnreadNotifications;

  /// Delivery line + bell.
  static const double _deliverRow = AppSize.s52;

  /// The pinned bar the search field rides in once collapsed.
  static const double _collapsedRow = AppSize.s56;

  static const double _searchTopGap = AppSpacing.s10;
  static const double _searchBottomGap = AppSpacing.s10;

  /// How far the white seam laps up over the brand band.
  static const double _seamHeight = AppSize.r15 + AppSpacing.s6;

  static const double _sideMargin = AppSpacing.s16;

  /// Room the always-visible bell takes on the trailing edge; the collapsed
  /// search field stops before it.
  static const double _bellSlot =
      HomeNotificationsBell.discSize + AppSpacing.s8;

  /// The delivery line is gone by this much of the collapse.
  static const double _fadeOutBy = 0.6;

  /// Past this point the bar reads as collapsed: taps and the status-bar
  /// glyphs switch over.
  static const double _collapsedAt = 0.5;

  static const double _expandedRow =
      _deliverRow +
      _searchTopGap +
      HomeHeroSearchField.height +
      _searchBottomGap +
      _seamHeight;

  /// Scroll distance the hero collapses over.
  static const double _range = _expandedRow - _collapsedRow;

  /// Where the field rests inside the collapsed bar.
  static const double _collapsedSearchTop =
      (_collapsedRow - HomeHeroSearchField.height) / 2;

  static double _at(double expanded, double collapsed, double t) =>
      expanded + (collapsed - expanded) * t;

  /// Built ONCE per delegate: `build` runs for every scroll offset while the
  /// hero collapses, and an identical widget instance is skipped by the
  /// framework. Its own repaint boundary keeps the press / unread-dot
  /// animation from repainting the band behind it.
  late final Widget _bell = RepaintBoundary(
    child: HomeNotificationsBell(
      hasUnread: hasUnreadNotifications,
      onTap: onNotifications,
    ),
  );

  @override
  double get minExtent => topPad + _collapsedRow;

  @override
  double get maxExtent => topPad + _expandedRow;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // t = 0 fully expanded, 1 fully collapsed.
    final t = (shrinkOffset / _range).clamp(0.0, 1.0);
    final isCollapsed = t > _collapsedAt;
    final bandOpacity = 1.0 - t;
    final deliverO = ((_fadeOutBy - t) / _fadeOutBy).clamp(0.0, 1.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light glyphs over the brand band; once collapsed the bar is white, so
      // flip to dark glyphs and keep the clock / battery legible.
      value: isCollapsed
          ? const SystemUiOverlayStyle(
              statusBarColor: AppColors.scrimTransparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            )
          : const SystemUiOverlayStyle(
              statusBarColor: AppColors.scrimTransparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Brand band, whitening as the hero collapses.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kJameiaHeroTop, kJameiaHeroBottom],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: ColoredBox(color: AppColors.white.withValues(alpha: t)),
            ),
            // 2. Reverse seam: the white feed laps UP over the band.
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              height: _seamHeight,
              child: IgnorePointer(
                child: Opacity(
                  opacity: bandOpacity,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadiusDirectional.only(
                        topStart: Radius.circular(AppSize.r15),
                        topEnd: Radius.circular(AppSize.r15),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 3. Delivery line (leading) and the bell (trailing). The bell
            //    stays put while the line fades out.
            Positioned(
              left: 0,
              right: 0,
              top: topPad,
              height: _at(_deliverRow, _collapsedRow, t),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: _sideMargin,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Opacity(
                          opacity: deliverO,
                          child: IgnorePointer(
                            ignoring: isCollapsed,
                            child: HomeHeroDeliverTo(
                              placeLabel: placeLabel,
                              onTap: onAddressTap,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _bell,
                  ],
                ),
              ),
            ),
            // 4. The search field: under the delivery line while expanded,
            //    pinned in the bar (clear of the bell) once collapsed.
            PositionedDirectional(
              start: _sideMargin,
              end: _at(_sideMargin, _sideMargin + _bellSlot, t),
              top: _at(
                topPad + _deliverRow + _searchTopGap,
                topPad + _collapsedSearchTop,
                t,
              ),
              child: HomeHeroSearchField(
                onTap: onSearch,
                fill: Color.lerp(
                  AppColors.white,
                  AppColors.smallBackground,
                  t,
                )!,
                shadowAlpha:
                    HomeHeroSearchField.restingShadowAlpha * bandOpacity,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant HomeHeroDelegate old) =>
      old.topPad != topPad ||
      old.placeLabel != placeLabel ||
      old.onSearch != onSearch ||
      old.onAddressTap != onAddressTap ||
      old.onNotifications != onNotifications ||
      old.hasUnreadNotifications != hasUnreadNotifications;
}
