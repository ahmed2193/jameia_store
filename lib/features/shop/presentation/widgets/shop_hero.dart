import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/data/jameia/jameia_models.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/design/keeta_assets.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/core_widgets.dart';
import 'rank_rail.dart';
import 'sub_tab_bar.dart';

/// Collapsing-hero geometry shared across the header widgets. The expanded hero
/// shows ONLY the cover (the meta + coupon now scroll away as normal slivers);
/// it collapses to a compact (48dp + top inset) app bar. [kHeroCoverHeight] is
/// the cover photo height when expanded; [kCompactBar] the collapsed app-bar
/// height (excl. top inset).
const double kHeroCoverHeight = 150;
const double kCompactBar = 48;

/// Real KeeTa nav circle: 32×32dp, margin-left 16dp, margin-top 6dp (bb2fcb / ac5a43).
class NavCircle extends StatelessWidget {
  const NavCircle({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // margin-left 16dp, margin-top 6dp — bb2fcb / ac5a43
      padding: const EdgeInsetsDirectional.only(start: 8, top: 6, bottom: 6),
      child: GestureDetector(
        onTap: onTap,
        // Expand the hit area to the full padded box (>=40dp) for a11y, even
        // though the visible circle stays 32dp.
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            // #ffffff14 — semi-transparent white circle on photo (d41098)
            color: AppColors.white.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

/// Hero cover image with the KeeTa top/bottom gradient overlay. Full-width by
/// layout; height is fixed by the caller (a [SizedBox] of [kHeroCoverHeight] +
/// top inset), so [KeetaImage] discovers the painted box via [LayoutBuilder].
class HeroBg extends StatelessWidget {
  const HeroBg({super.key, required this.coverUrl});
  final String coverUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-width × fixed-height cover: width null → LayoutBuilder discovers
        // the painted area for the CDN transform + per-size decode.
        KeetaImage(url: coverUrl, height: kHeroCoverHeight, fit: BoxFit.cover),
        // gradient: real KeeTa uses "linear-gradient(180deg, #F5F6FA 63%, #FFFFFF 100%)"
        // from bottom to fade into page bg, and a subtle overlay at top for nav icons
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.25, 0.63, 1.0],
              colors: [
                AppColors.scrimTop40, // top: protect nav icons
                AppColors.scrimTransparent,
                AppColors.heroFadeStart,
                AppColors.heroFadeEnd, // bottom: bleeds into page bg
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// White rounded card with 9dp horizontal margin (d77aab / e759a4 atoms).
/// border-radius: 16dp (system-borderRadius-r3).
class SectionWrapper extends StatelessWidget {
  const SectionWrapper({
    super.key,
    required this.child,
    this.topPadding = 0,
    this.bottomPadding = 0,
  });
  final Widget child;
  final double topPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      // margin 9dp horizontal (d77aab: margin-left 9dp / margin-right 9dp)
      margin: const EdgeInsetsDirectional.only(start: 9, end: 9, bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r3),
      ),
      child: topPadding > 0 || bottomPadding > 0
          ? Padding(
              padding: EdgeInsetsDirectional.only(
                start: 12,
                end: 12,
                top: topPadding,
                bottom: bottomPadding,
              ),
              child: child,
            )
          : child,
    );
  }
}

/// 2dp bullet/dot separator (fcd401 / d6c398 atoms from css.json).
class _DotSep extends StatelessWidget {
  const _DotSep();
  @override
  Widget build(BuildContext context) => Container(
    width: 2,
    height: 2,
    decoration: const BoxDecoration(
      color: AppColors.disabledText,
      shape: BoxShape.circle,
    ),
  );
}

/// White rounded card directly below hero — shop name, rating, delivery info.
/// Real metrics: border-radius 16dp (r3), margin 9dp h, padding-left 12dp,
/// padding-top/bottom 20dp (afb531 atom).
class ShopMetaCard extends StatelessWidget {
  const ShopMetaCard({super.key, required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return SectionWrapper(
      topPadding: 20,
      bottomPadding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop name: KeeTa-SemiBold 18dp #222222 (e7155c / jcf264 pattern)
          Text(
            shop.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headingLarge.copyWith(
              fontWeight: AppTextStyles.bold,
              fontSize: AppSize.font18,
            ),
          ),
          const SizedBox(height: 4),
          // Tags row: secondary text 12dp (d28ae3)
          Text(
            shop.tags.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.captionLarge.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          // Rating badge + ratingCount + distance
          Row(
            children: [
              RatingBadge(rating: shop.rating, count: shop.ratingCount),
              // dot separator (fcd401 — 2dp circle)
              const Padding(
                padding: EdgeInsetsDirectional.symmetric(horizontal: 6),
                child: _DotSep(),
              ),
              const Icon(
                KeetaIcons.deliveryTime,
                size: 12,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  shop.deliveryTime,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsetsDirectional.symmetric(horizontal: 6),
                child: _DotSep(),
              ),
              const Icon(
                KeetaIcons.location,
                size: 12,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  Formatters.distance(shop.distanceKm),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Delivery info strip: #F5F6FA bg, radius 10dp (j3af84 / r5)
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 8,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: AppColors.mediumBackground,
              borderRadius: BorderRadius.circular(AppRadius.r5),
            ),
            child: Row(
              children: [
                // Delivery icon (real asset: cartDelivery)
                Image.asset(
                  KeetaAssets.cartDelivery,
                  width: 16,
                  height: 16,
                  errorBuilder: (context, error, stack) => const Icon(
                    KeetaIcons.delivery,
                    size: 16,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    shop.freeDelivery
                        ? 'shop.free_delivery'.tr()
                        : 'shop.delivery_price'.tr(
                            namedArgs: {
                              'price': Formatters.price(shop.deliveryFee),
                            },
                          ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.captionLarge.copyWith(
                      color: shop.freeDelivery
                          ? AppColors.freeDelivery
                          : AppColors.secondaryText,
                      fontWeight: shop.freeDelivery
                          ? AppTextStyles.medium
                          : AppTextStyles.regular,
                    ),
                  ),
                ),
                // fdb74f divider — 0.5dp #EBEBEB, margin 0 8dp
                const Padding(
                  padding: EdgeInsetsDirectional.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: 0.5,
                    height: 12,
                    child: ColoredBox(color: AppColors.divider),
                  ),
                ),
                const Icon(
                  KeetaIcons.time,
                  size: 14,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    shop.deliveryTime,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.captionLarge.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
                const Spacer(),
                // Min order — tertiaryText 10dp (e37ccc)
                Text(
                  'shop.min_short'.tr(
                    namedArgs: {'price': Formatters.price(shop.minOrder)},
                  ),
                  style: AppTextStyles.captionMedium.copyWith(
                    color: AppColors.tertiaryText,
                  ),
                ),
              ],
            ),
          ),
          // Promo tag if present (promotionTag chip — gf4e9b, border-radius 6dp)
          if (shop.promo.isNotEmpty) ...[
            const SizedBox(height: 8),
            TagChip(
              label: shop.promo,
              bg: AppColors.promotionTagLightBg,
              fg: AppColors.promotionTagFgOnLight,
              icon: KeetaIcons.rank,
            ),
          ],
        ],
      ),
    );
  }
}

/// Shop coupon / promo strip (`dd6eca`): yellow gradient #FFFBD9→#FFF8AD with a
/// 2.5dp white border (r12 top), brown #713901 copy (h0bc8e) + a brown-bordered
/// "View" chip (cc6af6: 22.5dp, r4, 0.5dp #713901 border).
class ShopCouponStrip extends StatelessWidget {
  const ShopCouponStrip({super.key, required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final text = shop.promo.isNotEmpty
        ? shop.promo
        : (shop.freeDelivery ? 'shop.free_delivery_on_order'.tr() : '');
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(9, 8, 9, 0),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        // dd6eca: linear-gradient(179deg, #FFFBD9 7%, #FFF8AD 91%)
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.couponGradientStart, AppColors.couponGradientEnd],
        ),
        border: Border.all(color: AppColors.white, width: 2.5),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          const Icon(KeetaIcons.rank, size: 14, color: AppColors.skuOptionFg),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppSize.font12,
                color: AppColors.skuOptionFg,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            constraints: const BoxConstraints(minWidth: 40),
            height: 22.5,
            alignment: Alignment.center,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSize.r4),
              border: Border.all(color: AppColors.skuOptionFg, width: 0.5),
            ),
            child: Text(
              'shop.view'.tr(),
              style: const TextStyle(
                fontSize: AppSize.font12,
                color: AppColors.skuOptionFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Collapsing hero sliver ────────────────────────────────────────────────────

/// Pinned, collapsing hero app bar — a [SliverPersistentHeader] delegate showing
/// ONLY the cover photo + the chrome row (back · title · search · share · fav).
/// The meta card + coupon strip are NORMAL scroll-away slivers below it now, so
/// the cover height is short (≈[kHeroCoverHeight]) and the bar collapses natively
/// via `shrinkOffset` — no faked-from-scroll-px collapse notifier any more.
///
/// Collapse interpolation (mirrors the restaurant reference):
///   t = shrinkOffset / (maxExtent − minExtent)
///   cover fades (1 − t); title fades in ((t − 0.3) / 0.7).clamp(0, 1).
class ShopHeroHeader extends StatelessWidget {
  const ShopHeroHeader({super.key, required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _ShopHeroDelegate(
        shop: shop,
        topInset: topInset,
        minExtentValue: topInset + kCompactBar,
        maxExtentValue: topInset + kHeroCoverHeight,
      ),
    );
  }
}

class _ShopHeroDelegate extends SliverPersistentHeaderDelegate {
  _ShopHeroDelegate({
    required this.shop,
    required this.topInset,
    required this.minExtentValue,
    required this.maxExtentValue,
  });

  final Shop shop;
  final double topInset;
  final double minExtentValue;
  final double maxExtentValue;

  @override
  double get minExtent => minExtentValue;

  @override
  double get maxExtent => maxExtentValue;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = math.max(maxExtent - minExtent, 1.0);
    final t = (shrinkOffset / range).clamp(0.0, 1.0);
    final coverOpacity = (1.0 - t).clamp(0.0, 1.0);
    final titleOpacity = ((t - 0.3) / 0.7).clamp(0.0, 1.0);
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Compact white bar background — always present; the cover paints over
          // it while expanded and fades to reveal it on collapse.
          const Positioned.fill(child: ColoredBox(color: AppColors.white)),
          // Cover photo, faded out as the bar collapses.
          if (coverOpacity > 0.01)
            PositionedDirectional(
              start: 0,
              end: 0,
              top: 0,
              height: maxExtent,
              child: IgnorePointer(
                child: Opacity(
                  opacity: coverOpacity,
                  child: HeroBg(coverUrl: shop.cover),
                ),
              ),
            ),
          // Chrome row — visible at all t, pinned just under the status bar.
          PositionedDirectional(
            start: 0,
            end: 0,
            top: topInset,
            height: kCompactBar,
            child: HeaderChromeRow(shop: shop, titleOpacity: titleOpacity),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ShopHeroDelegate old) =>
      old.shop != shop ||
      old.topInset != topInset ||
      old.minExtentValue != minExtentValue ||
      old.maxExtentValue != maxExtentValue;
}

/// Back chevron + (fading) shop-name title + search/share/fav nav circles.
/// Mirrors the restaurant chrome row; reuses the existing [NavCircle] visual.
class HeaderChromeRow extends StatelessWidget {
  const HeaderChromeRow({
    super.key,
    required this.shop,
    required this.titleOpacity,
  });
  final Shop shop;
  final double titleOpacity;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NavCircle(
          child: const Icon(
            KeetaIcons.back,
            size: 18,
            color: AppColors.primaryText,
          ),
          onTap: () => Navigator.maybePop(context),
        ),
        Expanded(
          child: Opacity(
            opacity: titleOpacity,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
              child: Text(
                shop.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headingLarge.copyWith(
                  fontWeight: AppTextStyles.bold,
                  fontSize: AppSize.font17,
                  color: AppColors.primaryText,
                ),
              ),
            ),
          ),
        ),
        NavCircle(
          child: Image.asset(KeetaAssets.shopSearch, width: 18, height: 18),
        ),
        NavCircle(
          child: Image.asset(KeetaAssets.shopShare, width: 18, height: 18),
        ),
        NavCircle(
          child: Image.asset(KeetaAssets.shopEmptyHeart, width: 18, height: 18),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ── Pinned sub-tab bar + rank rail sliver wrappers ───────────────────────────

/// Pins the existing [SubTabBar] under the hero. A JUMP/SWAP control — tapping a
/// sub-tab is handled by the screen (swaps the body + scrolls so this bar stays
/// pinned at the top), the [TabController] only drives the indicator.
class SubTabBarSliver extends StatelessWidget {
  const SubTabBarSliver({
    super.key,
    required this.controller,
    required this.subs,
    this.onTap,
  });
  final TabController controller;
  final List<JameiaSubCategory> subs;

  /// Fires on every sub-tab tap (including the active one) — see [SubTabBar.onTap].
  final ValueChanged<int>? onTap;

  static const double _height = 48;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _FixedHeightHeaderDelegate(
        height: _height,
        rebuildKey: Object.hash(controller, subs.length),
        child: SubTabBar(controller: controller, subs: subs, onTap: onTap),
      ),
    );
  }
}

/// Pins the existing [RankRail] for the ACTIVE sub directly under the sub-tab
/// bar (or under the hero when there's a single sub).
class RankRailSliver extends StatelessWidget {
  const RankRailSliver({
    super.key,
    required this.sections,
    required this.hasImages,
    required this.activeRank,
    required this.controller,
    required this.itemExtent,
    required this.onSelect,
  });

  final List<MenuSection> sections;
  final bool hasImages;
  final ValueListenable<int> activeRank;
  final ScrollController controller;
  final double itemExtent;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final height = hasImages ? 108.0 : 52.0;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _FixedHeightHeaderDelegate(
        height: height,
        // Key on the active sub's sections so swapping subs rebuilds the rail.
        rebuildKey: Object.hash(
          Object.hashAll([for (final s in sections) s.id]),
          hasImages,
        ),
        child: RankRail(
          sections: sections,
          hasImages: hasImages,
          activeRank: activeRank,
          controller: controller,
          itemExtent: itemExtent,
          onSelect: onSelect,
        ),
      ),
    );
  }
}

/// Generic fixed-height pinned-header delegate wrapping an arbitrary [child].
class _FixedHeightHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FixedHeightHeaderDelegate({
    required this.height,
    required this.child,
    required this.rebuildKey,
  });

  final double height;
  final Widget child;
  final Object rebuildKey;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // White background so nothing shows through the pinned bar.
    return SizedBox.expand(
      child: ColoredBox(color: AppColors.white, child: child),
    );
  }

  @override
  bool shouldRebuild(covariant _FixedHeightHeaderDelegate old) =>
      old.height != height || old.rebuildKey != rebuildKey;
}
