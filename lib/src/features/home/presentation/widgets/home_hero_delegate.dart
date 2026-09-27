import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/responsive/app_size.dart';
import 'home_assistant_button.dart';
import 'home_hero_deliver_to.dart';
import 'home_hero_search_field.dart';
import 'home_layout.dart';
import 'home_notifications_bell.dart';
import 'home_store_identity.dart';

/// The collapsing home header, white like the storefront it follows.
///
///   * Open (top of the feed) — the store row (badge, "pro" tag, name and the
///     delivery-time pill) with the assistant disc (when the store runs the
///     assistant) and the notifications bell beside it, the delivery
///     line (`Deliver to <place>`) under it, then the search pill.
///   * Collapsed (scrolled up) — the delivery line, then the store row, fade
///     where they are while the search pill glides up over them into the
///     pinned bar and STAYS there beside the bell, so search is one tap away
///     anywhere in the feed. A hairline under the bar parts it from the feed
///     passing beneath.
///
/// Home is a root shell tab, so there is no back button. Every row is sized
/// from the reader's text scale, so the header never clips its own text.
class HomeHeroDelegate extends SliverPersistentHeaderDelegate {
  HomeHeroDelegate({
    required this.storeName,
    required this.isPro,
    required this.etaMinutes,
    required this.placeLabel,
    required this.topPad,
    required this.textScaler,
    required this.onAddressTap,
    required this.onSearch,
    required this.onNotifications,
    required this.hasUnreadNotifications,
    this.onAssistant,
  });

  final String storeName;

  /// The customer is a Jm3eia Pro member: the "pro" tag shows.
  final bool isPro;

  /// The zone's delivery time; `0` while unknown (no pill).
  final int etaMinutes;
  final String placeLabel;

  /// The status-bar inset the header sits below.
  final double topPad;

  /// The reader's text scale; the rows grow with it.
  final TextScaler textScaler;
  final VoidCallback onAddressTap;
  final VoidCallback onSearch;
  final VoidCallback onNotifications;
  final bool hasUnreadNotifications;

  /// Opens the assistant; `null` hides its disc (the store has it off).
  final VoidCallback? onAssistant;

  static const double _topGap = AppSpacing.s8;
  static const double _rowGap = AppSpacing.s10;
  static const double _bottomGap = AppSpacing.s12;

  /// The pinned bar the search pill rides in once collapsed.
  static const double _collapsedRow = AppSize.s56;

  static const double _sideMargin = HomeLayout.gutter;

  static const double _discGap = AppSpacing.s8;

  /// Room the always-visible trailing discs (the bell, and the assistant
  /// beside it) take; the store row and the collapsed search pill stop
  /// before it.
  late final double _bellSlot =
      HomeNotificationsBell.discSize +
      (onAssistant == null ? 0 : HomeAssistantButton.discSize + _discGap) +
      AppSpacing.s10;

  /// The delivery line is gone by this much of the collapse — the search pill
  /// is sliding over it by then — and the store row by [_storeFadeBy].
  static const double _addressFadeBy = 0.35;
  static const double _storeFadeBy = 0.6;

  /// Where the pill rests inside the collapsed bar.
  static const double _collapsedSearchTop =
      (_collapsedRow - HomeHeroSearchField.height) / 2;

  static const double _collapsedBellTop =
      (_collapsedRow - HomeNotificationsBell.discSize) / 2;

  late final double _storeRow = HomeStoreIdentity.heightFor(textScaler);
  late final double _addressTop = _topGap + _storeRow + _rowGap;
  late final double _addressRow = HomeHeroDeliverTo.heightFor(textScaler);
  late final double _searchTop = _addressTop + _addressRow + _rowGap;
  late final double _expandedRow =
      _searchTop + HomeHeroSearchField.height + _bottomGap;
  late final double _openBellTop =
      _topGap + (_storeRow - HomeNotificationsBell.discSize) / 2;

  /// Scroll distance the header collapses over.
  late final double _range = _expandedRow - _collapsedRow;

  static double _at(double expanded, double collapsed, double t) =>
      expanded + (collapsed - expanded) * t;

  /// 1 while open, 0 once [t] has passed [by].
  static double _fade(double t, double by) => ((by - t) / by).clamp(0.0, 1.0);

  /// Built ONCE per delegate: `build` runs for every scroll offset while the
  /// header collapses, and an identical widget instance is skipped by the
  /// framework. The bell's own repaint boundary keeps its press / unread-dot
  /// animation from repainting the header behind it.
  late final Widget _bell = RepaintBoundary(
    child: HomeNotificationsBell(
      hasUnread: hasUnreadNotifications,
      onTap: onNotifications,
    ),
  );

  late final Widget? _assistant = onAssistant == null
      ? null
      : HomeAssistantButton(onTap: onAssistant!);

  late final Widget _identity = HomeStoreIdentity(
    storeName: storeName,
    isPro: isPro,
    etaMinutes: etaMinutes,
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
    // t = 0 fully open, 1 fully collapsed.
    final t = (shrinkOffset / _range).clamp(0.0, 1.0);
    final addressOpacity = _fade(t, _addressFadeBy);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // White open or collapsed: dark status-bar glyphs throughout.
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.scrimTransparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: RepaintBoundary(
        child: ColoredBox(
          color: AppColors.white,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. The store row, fading where it is. It has no taps.
              PositionedDirectional(
                start: _sideMargin,
                end: _sideMargin + _bellSlot,
                top: topPad + _topGap,
                height: _storeRow,
                child: Opacity(
                  opacity: _fade(t, _storeFadeBy),
                  child: _identity,
                ),
              ),
              // 2. The delivery line — first to go, the pill slides over it.
              PositionedDirectional(
                start: _sideMargin,
                end: _sideMargin,
                top: topPad + _addressTop,
                height: _addressRow,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Opacity(
                    opacity: addressOpacity,
                    child: IgnorePointer(
                      ignoring: addressOpacity == 0,
                      child: HomeHeroDeliverTo(
                        placeLabel: placeLabel,
                        onTap: onAddressTap,
                      ),
                    ),
                  ),
                ),
              ),
              // 3. The bell: beside the store row while open, in the bar once
              //    collapsed.
              PositionedDirectional(
                end: _sideMargin,
                top: topPad + _at(_openBellTop, _collapsedBellTop, t),
                child: _bell,
              ),
              // 3b. The assistant, just before the bell, moving with it.
              if (_assistant case final assistant?)
                PositionedDirectional(
                  end:
                      _sideMargin +
                      HomeNotificationsBell.discSize +
                      _discGap -
                      HomeAssistantButton.inset,
                  top:
                      topPad +
                      _at(_openBellTop, _collapsedBellTop, t) -
                      HomeAssistantButton.inset,
                  child: assistant,
                ),
              // 4. The search pill: under the delivery line while open, pinned
              //    in the bar (clear of the bell) once collapsed.
              PositionedDirectional(
                start: _sideMargin,
                end: _at(_sideMargin, _sideMargin + _bellSlot, t),
                top: topPad + _at(_searchTop, _collapsedSearchTop, t),
                child: HomeHeroSearchField(onTap: onSearch),
              ),
              // 5. The hairline under the collapsed bar.
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                height: AppSize.s1,
                child: ColoredBox(
                  color: AppColors.divider.withValues(alpha: t),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant HomeHeroDelegate old) =>
      old.topPad != topPad ||
      old.textScaler != textScaler ||
      old.storeName != storeName ||
      old.isPro != isPro ||
      old.etaMinutes != etaMinutes ||
      old.placeLabel != placeLabel ||
      old.onSearch != onSearch ||
      old.onAddressTap != onAddressTap ||
      old.onNotifications != onNotifications ||
      old.hasUnreadNotifications != hasUnreadNotifications ||
      (old.onAssistant == null) != (onAssistant == null);
}
