import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/design/jameia_assets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../domain/entities/jameia_address_entity.dart';
import 'home_notifications_bell.dart';

/// Jameia-store home hero — ported from jm3eia's `StoreHeroAppBar` (jameia
/// branch) + `StoreSearchField` (elevated) + `AddressPill` (jameiaHero), then
/// refactored so the delivery ADDRESS stays visible in the collapsed app bar.
///
/// A pinned, collapsing [SliverPersistentHeader]:
///   * Expanded (top of feed) — everything visible: orange gradient band with
///     the baked-in Jameia banner PNG (AR/EN), a white location pill floating
///     top-trailing, a white 15dp reverse-seam, and an elevated search field
///     overhanging the seam.
///   * Collapsed (scrolled up) — a compact solid bar that KEEPS the address on
///     the leading edge (dark location group, reads on white) and a compact
///     search icon on the trailing edge. The banner + floating search + white
///     pill cross-fade out; the address group + search icon cross-fade in.
///
/// jameia home is a ROOT shell tab, so — unlike jm3eia's pushed screen — there
/// is no leading back button. jameia pins `ThemeMode.light`, so the source's
/// `context.colors.*` map to the light literals (`AppColors.white` /
/// `AppColors.primaryText`).

/// Figma banner aspect (container 402×166) — hero height scales with width.
const double _kBannerAspect = 2.422;

/// Cap the banner width on tablets so the header never grows disproportionately
/// tall; the gradient fills the sides.
const double _kBannerMaxWidth = 640;

/// Collapsed chrome band height (below the status-bar inset).
const double _kChromeHeight = 52;

Widget jameiaHomeHeaderSliver({
  required JameiaAddressEntity address,
  required double topPad,
  required double screenWidth,
  required VoidCallback onAddressTap,
  required VoidCallback onSearch,
  required VoidCallback onNotifications,
  bool hasUnreadNotifications = false,
}) {
  return SliverPersistentHeader(
    pinned: true,
    delegate: _JameiaHeroDelegate(
      address: address,
      topPad: topPad,
      screenWidth: screenWidth,
      onAddressTap: onAddressTap,
      onSearch: onSearch,
      onNotifications: onNotifications,
      hasUnreadNotifications: hasUnreadNotifications,
    ),
  );
}

class _JameiaHeroDelegate extends SliverPersistentHeaderDelegate {
  _JameiaHeroDelegate({
    required this.address,
    required this.topPad,
    required this.screenWidth,
    required this.onAddressTap,
    required this.onSearch,
    required this.onNotifications,
    required this.hasUnreadNotifications,
  });

  final JameiaAddressEntity address;
  final double topPad;
  final double screenWidth;
  final VoidCallback onAddressTap;
  final VoidCallback onSearch;
  final VoidCallback onNotifications;
  final bool hasUnreadNotifications;

  /// Room the always-visible bell takes on the trailing edge of the chrome
  /// band (its disc + the gap); the pill / search icon sit before it.
  static const double _bellSlot =
      HomeNotificationsBell.discSize + AppSpacing.s8;

  /// Built ONCE per delegate: `build` runs for every scroll offset while the
  /// hero collapses, and an identical widget instance is skipped by the
  /// framework. Its own repaint boundary keeps the press / unread-dot
  /// animation from repainting the gradient + banner behind it.
  late final Widget _bell = RepaintBoundary(
    child: HomeNotificationsBell(
      hasUnread: hasUnreadNotifications,
      onTap: onNotifications,
    ),
  );

  double get _bannerW => math.min(screenWidth, _kBannerMaxWidth);
  double get _bannerH => _bannerW / _kBannerAspect;

  // Collapsed bar = 52dp chrome row + the real status-bar inset above it.
  @override
  double get minExtent => topPad + _kChromeHeight;

  @override
  double get maxExtent => math.max(topPad + _bannerH, minExtent + 28.0);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = math.max(maxExtent - minExtent, 1.0);
    // t = 0 fully expanded · 1 fully collapsed.
    final t = (shrinkOffset / range).clamp(0.0, 1.0);
    final photoOpacity = (1.0 - t).clamp(0.0, 1.0);
    // Expanded chrome (white pill) and collapsed chrome (dark address group +
    // search icon) cross-fade with an OVERLAP (0.4–0.6) so the address never
    // fully vanishes if the user rests the scroll mid-collapse.
    final expandedO = ((0.6 - t) / 0.6).clamp(0.0, 1.0);
    final collapsedO = ((t - 0.4) / 0.6).clamp(0.0, 1.0);

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final banner = context.locale.languageCode == 'ar'
        ? JameiaAssets.jameiaBannerAr
        : JameiaAssets.jameiaBannerEn;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light glyphs over the orange banner; once collapsed the bar is white, so
      // flip to dark glyphs so the clock/battery stay legible.
      value: t > 0.5
          ? const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            )
          : const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none, // lets the search footer overhang the seam
          children: [
            // 1. Orange brand gradient (Figma: 135°, #FD811F → #FE7618).
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
            // 2. Banner PNG — bottom-anchored, exact aspect (no crop). Fades on
            //    collapse.
            Positioned.fill(
              child: Opacity(
                opacity: photoOpacity,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Image.asset(
                    banner,
                    width: _bannerW,
                    height: _bannerH,
                    fit: BoxFit.contain,
                    cacheWidth: (_bannerW * dpr).round(),
                  ),
                ),
              ),
            ),
            // 3. White cover — alpha = t (clean solid compact bar once collapsed).
            Positioned.fill(
              child: ColoredBox(color: AppColors.white.withValues(alpha: t)),
            ),
            // 4. Reverse seam: white sheet laps UP over the orange with a 15dp
            //    top radius (Figma Rectangle 78); fades with the photo.
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              height: 15.0 + 6.0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: photoOpacity,
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
            // 5. Chrome band — pinned below the status bar (52dp). No back button
            //    (root tab). Expanded: white pill top-trailing. Collapsed: dark
            //    address group (leading) + search icon (trailing).
            Positioned(
              left: 0,
              right: 0,
              top: topPad,
              height: _kChromeHeight,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Collapsed: address group on the leading edge.
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Opacity(
                        opacity: collapsedO,
                        child: IgnorePointer(
                          ignoring: t < 0.5,
                          child: _CollapsedAddressGroup(
                            address: address,
                            maxWidth: screenWidth * 0.62,
                            onTap: onAddressTap,
                          ),
                        ),
                      ),
                    ),
                    // Collapsed: compact search icon, just before the bell.
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: _bellSlot,
                        ),
                        child: Opacity(
                          opacity: collapsedO,
                          child: IgnorePointer(
                            ignoring: t < 0.5,
                            child: _CollapsedSearchIcon(onTap: onSearch),
                          ),
                        ),
                      ),
                    ),
                    // Notifications bell — visible in BOTH states (white disc
                    // reads on the orange banner and on the collapsed bar).
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: _bell,
                    ),
                    // Expanded: white jameia location pill, top-trailing (Figma:
                    // 8dp below the banner top edge).
                    PositionedDirectional(
                      top: 8,
                      end: _bellSlot,
                      child: Opacity(
                        opacity: expandedO,
                        child: IgnorePointer(
                          ignoring: t > 0.5,
                          child: _JameiaAddressPill(
                            address: address,
                            onTap: onAddressTap,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 6. Floating search field — overhangs the hero bottom by 4dp; fades
            //    with the photo and stops taking taps once mostly collapsed.
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: -4,
              child: IgnorePointer(
                ignoring: t > 0.5,
                child: Opacity(
                  opacity: photoOpacity,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 16,
                    ),
                    child: _HeroSearchField(onTap: onSearch),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _JameiaHeroDelegate old) =>
      old.topPad != topPad ||
      old.screenWidth != screenWidth ||
      old.address != address ||
      old.onSearch != onSearch ||
      old.onAddressTap != onAddressTap ||
      old.onNotifications != onNotifications ||
      old.hasUnreadNotifications != hasUnreadNotifications;
}

/// Address shown in the COLLAPSED bar (reads on white): dark location pin + city
/// + chevron, no pill background. Mirrors jameia's compact address group.
class _CollapsedAddressGroup extends StatelessWidget {
  const _CollapsedAddressGroup({
    required this.address,
    required this.maxWidth,
    required this.onTap,
  });
  final JameiaAddressEntity address;
  final double maxWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final city = address.area.isNotEmpty ? address.area : address.label;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_rounded,
              color: kJameiaPillPin,
              size: 18,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                city,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppSize.font16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: kJameiaPillChevron,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact jameia location pill (Figma-exact): white pill, orange pin + city +
/// orange chevron. Ported from `AddressPill._buildJameiaHero`. Shown over the
/// orange banner in the EXPANDED state.
class _JameiaAddressPill extends StatelessWidget {
  const _JameiaAddressPill({required this.address, required this.onTap});
  final JameiaAddressEntity address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final city = address.area.isNotEmpty ? address.area : address.label;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.55,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: kJameiaPillPin,
                  size: 10,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppSize.font12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: kJameiaPillChevron,
                  size: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Search icon shown in the collapsed bar (44×44 hit area). Fades in as the
/// floating search field fades out.
class _CollapsedSearchIcon extends StatelessWidget {
  const _CollapsedSearchIcon({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        icon: const Icon(
          Icons.search_rounded,
          size: 22,
          color: AppColors.primaryText,
        ),
      ),
    );
  }
}

/// Elevated white search field floating over the hero seam. Ported from
/// jm3eia's `StoreSearchField(elevated: true, height: 40, iconSize: 16)`.
class _HeroSearchField extends StatelessWidget {
  const _HeroSearchField({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSize.r12),
        child: Container(
          height: 40,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSize.r12),
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
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                size: 16,
                color: kJameiaSearchHint,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'home.search_products'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppSize.font14,
                    color: kJameiaSearchHint,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SvgPicture.asset(
                JameiaAssets.jameiaScanLine,
                width: 16,
                height: 16,
                colorFilter: const ColorFilter.mode(
                  AppColors.primaryText,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
