import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/design/keeta_assets.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/brand_moment.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/widgets/skeletons.dart';
import '../../domain/entities/shop_entity.dart';
import '../cubit/shop_detail_cubit.dart';
import '../util/shop_display.dart';

/// KeeTa shop-detail panel: collapsing cover hero, info card (name / rating /
/// tags / description), delivery rows, opening hours, address + map placeholder,
/// and a sticky Favourite toggle.
class ShopDetailScreen extends StatelessWidget {
  const ShopDetailScreen({super.key, this.shopId = 's1'});
  final String shopId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ShopDetailCubit>()..load(shopId),
      child: _ShopDetailView(shopId: shopId),
    );
  }
}

class _ShopDetailView extends StatelessWidget {
  const _ShopDetailView({required this.shopId});
  final String shopId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      body: BlocBuilder<ShopDetailCubit, ShopDetailState>(
        builder: (context, state) {
          if (state.status == ShopDetailStatus.loading ||
              state.status == ShopDetailStatus.initial) {
            return const Skeletonized(loading: true, child: ShopMenuSkeleton());
          }
          if (state.status == ShopDetailStatus.error || state.shop == null) {
            return ErrorView(
              onRetry: () => context.read<ShopDetailCubit>().load(shopId),
            );
          }
          return _Loaded(shop: state.shop!, favourite: state.favourite);
        },
      ),
      bottomNavigationBar: const _FavouriteBar(),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.shop, required this.favourite});
  final ShopEntity shop;
  final bool favourite;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _CoverHero(shop: shop, favourite: favourite),
        SliverToBoxAdapter(child: _InfoCard(shop: shop)),
        SliverToBoxAdapter(child: _DeliveryCard(shop: shop)),
        const SliverToBoxAdapter(child: _OpeningHoursCard()),
        SliverToBoxAdapter(child: _AddressCard(shop: shop)),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s24)),
      ],
    );
  }
}

// ── Cover hero ────────────────────────────────────────────────────────────────
class _CoverHero extends StatelessWidget {
  const _CoverHero({required this.shop, required this.favourite});
  final ShopEntity shop;
  final bool favourite;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 220,
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.white,
      elevation: 0,
      leading: _CircleAction(
        icon: KeetaIcons.back,
        onTap: () => Navigator.maybePop(context),
      ),
      actions: [
        _CircleAction(icon: KeetaIcons.share, onTap: () {}),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.s8),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.overlayPrimary,
            child: HeartPopButton(
              liked: favourite,
              onChanged: (_) =>
                  context.read<ShopDetailCubit>().toggleFavourite(),
              size: 17,
            ),
          ),
        ),
        _CircleAction(icon: KeetaIcons.more, onTap: () {}),
        const SizedBox(width: AppSpacing.s8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            KeetaImage(url: shop.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.overlayPrimary, Colors.transparent],
                ),
              ),
            ),
            // Shop logo badge anchored to the bottom-start of the cover.
            PositionedDirectional(
              start: AppSpacing.pageMargin + AppSpacing.s4,
              bottom: AppSpacing.s12,
              child: Container(
                // b5b85d: 2dp white border + r8; ad206e: shadow 0 0.5 2 #0000001f
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppSize.r8),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.overlayDivider,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                // f75b33: logo image 38×49dp, radius 8dp (portrait brand badge)
                child: KeetaImage(
                  url: shop.logo,
                  width: 38,
                  height: 49,
                  radius: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.s8),
      child: GestureDetector(
        onTap: onTap,
        child: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.overlayPrimary,
          child: Icon(icon, size: 17, color: AppColors.white),
        ),
      ),
    );
  }
}

// ── Info card (name, rating, tags, description) ──────────────────────────────
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.shop});
  final ShopEntity shop;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shop.displayName,
            style: AppTextStyles.displaySmall.copyWith(
              fontWeight: AppTextStyles.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Row(
            children: [
              RatingBadge(rating: shop.rating, count: shop.ratingCount),
              const SizedBox(width: AppSpacing.s8),
              Text(
                '·',
                style: AppTextStyles.captionLarge.copyWith(
                  color: AppColors.tertiaryText,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                Formatters.distance(shop.distanceKm),
                style: AppTextStyles.captionLarge.copyWith(
                  color: AppColors.tertiaryText,
                ),
              ),
            ],
          ),
          if (shop.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                for (final tag in shop.tags)
                  TagChip(
                    label: tag,
                    bg: AppColors.smallBackground,
                    fg: AppColors.secondaryText,
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.s12),
          _SubHeader(label: 'shop.about'.tr()),
          const SizedBox(height: AppSpacing.s6),
          Text(
            _description(shop),
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  String _description(ShopEntity shop) {
    final kind = shop.isRestaurant
        ? 'shop.kind_restaurant'.tr()
        : 'shop.kind_store'.tr();
    final tags = shop.tags.isEmpty
        ? ''
        : 'shop.about_specialising'.tr(
            namedArgs: {'tags': shop.tags.join(', ')},
          );
    return 'shop.about_description'.tr(
      namedArgs: {
        'name': shop.name,
        'kind': kind,
        'tags': tags,
        'rating': shop.rating.toStringAsFixed(1),
        'count': '${shop.ratingCount}',
        'time': shop.deliveryTime,
      },
    );
  }
}

// ── Delivery card ─────────────────────────────────────────────────────────────
class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.shop});
  final ShopEntity shop;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SubHeader(label: 'shop.delivery'.tr()),
          const SizedBox(height: AppSpacing.s12),
          _InfoRow(
            icon: KeetaIcons.delivery,
            label: 'shop.delivery_fee'.tr(),
            value: shop.freeDelivery
                ? 'shop.free_delivery'.tr()
                : Formatters.price(shop.deliveryFee),
            valueColor: shop.freeDelivery
                ? AppColors.freeDelivery
                : AppColors.primaryText,
          ),
          const SizedBox(height: AppSpacing.s12),
          _InfoRow(
            icon: KeetaIcons.time,
            label: 'shop.delivery_time'.tr(),
            value: shop.deliveryTime,
          ),
          const SizedBox(height: AppSpacing.s12),
          _InfoRow(
            icon: KeetaIcons.cart,
            label: 'shop.minimum_order'.tr(),
            value: Formatters.price(shop.minOrder),
          ),
        ],
      ),
    );
  }
}

// ── Opening hours (dummy) ─────────────────────────────────────────────────────
class _OpeningHoursCard extends StatelessWidget {
  const _OpeningHoursCard();

  static const _days = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SubHeader(label: 'shop.opening_hours'.tr()),
              const Spacer(),
              // g705b7/jdc7fe: neutral tag — #F0F1F5 bg, #555 (secondary) text
              TagChip(
                label: 'shop.open_now'.tr(),
                bg: AppColors.smallBackground,
                fg: AppColors.secondaryText,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          for (final day in _days) ...[
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: AppSpacing.s6,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'shop.day_${day.toLowerCase()}'.tr(),
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                  Text(
                    day == 'Sunday' ? '10:00 - 22:00' : '09:00 - 23:00',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
            ),
            if (day != _days.last) const ThinDivider(),
          ],
        ],
      ),
    );
  }
}

// ── Address + map placeholder ─────────────────────────────────────────────────
class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.shop});
  final ShopEntity shop;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SubHeader(label: 'shop.location'.tr()),
          const SizedBox(height: AppSpacing.s12),
          _InfoRow(
            icon: KeetaIcons.location,
            label: 'shop.branch'.tr(namedArgs: {'name': shop.displayName}),
            value: Formatters.distance(shop.distanceKm),
          ),
          const SizedBox(height: AppSpacing.s12),
          // Tappable map preview → opens the full-screen shop map.
          GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              Routes.shopMap,
              arguments: shop.id,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.r4),
              child: Stack(
                children: [
                  Image.asset(
                    KeetaAssets.userLocationIcon,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 140,
                      width: double.infinity,
                      color: AppColors.smallBackground,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(color: AppColors.overlayOnContent),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Icon(
                      KeetaIcons.storeLocation,
                      size: 34,
                      color: AppColors.accent1,
                    ),
                  ),
                  // "View map" affordance.
                  const PositionedDirectional(
                    bottom: AppSpacing.s8,
                    end: AppSpacing.s8,
                    child: _ViewMapChip(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewMapChip extends StatelessWidget {
  const _ViewMapChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r6),
        boxShadow: const [
          BoxShadow(
            color: AppColors.overlayDivider,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'shop.view_map'.tr(),
            style: AppTextStyles.captionLarge.copyWith(
              fontWeight: AppTextStyles.bold,
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          const Icon(
            KeetaIcons.arrowRight,
            size: 12,
            color: AppColors.primaryText,
          ),
        ],
      ),
    );
  }
}

// ── Sticky favourite bar ──────────────────────────────────────────────────────
class _FavouriteBar extends StatelessWidget {
  const _FavouriteBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShopDetailCubit, ShopDetailState>(
      builder: (context, state) {
        if (state.shop == null) return const SizedBox.shrink();
        final fav = state.favourite;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s12),
            child: AppButton(
              label: fav
                  ? 'shop.saved_to_favourites'.tr()
                  : 'shop.add_to_favourites'.tr(),
              onPressed: () =>
                  context.read<ShopDetailCubit>().toggleFavourite(),
              color: fav ? AppColors.accent1Light : AppColors.primary,
              foreground: fav ? AppColors.accent1 : AppColors.brandForeground,
              trailing: Icon(
                KeetaIcons.favorite,
                size: 18,
                color: fav ? AppColors.accent1 : AppColors.brandForeground,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Shared local building blocks ──────────────────────────────────────────────
class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      // fcb6fb: card margin-left/right 16dp
      margin: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s16,
        AppSpacing.s8,
        AppSpacing.s16,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: child,
    );
  }
}

class _SubHeader extends StatelessWidget {
  const _SubHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.headingMedium.copyWith(
        fontWeight: AppTextStyles.bold,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = AppColors.primaryText,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.secondaryText), // f76a3d 16dp
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.headingSmall.copyWith(
            color: valueColor,
            fontWeight: AppTextStyles.bold,
          ),
        ),
      ],
    );
  }
}
