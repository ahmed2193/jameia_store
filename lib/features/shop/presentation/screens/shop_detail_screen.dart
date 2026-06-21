import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/design/keeta_assets.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/core_widgets.dart';

/// ── ShopDetail cubit (page-scoped) ──────────────────────────────────────────
/// KeeTa `shop_detail` (bundle 48) — the read-only "Shop info / detail panel"
/// reached from the shop menu's `•••` more button. Loads one [Shop] and holds a
/// local (dummy) favourite toggle.
class ShopDetailState extends Equatable {
  const ShopDetailState({
    this.loading = true,
    this.error = false,
    this.shop,
    this.favourite = false,
  });

  final bool loading;
  final bool error;
  final Shop? shop;
  final bool favourite;

  ShopDetailState copyWith({
    bool? loading,
    bool? error,
    Shop? shop,
    bool? favourite,
  }) =>
      ShopDetailState(
        loading: loading ?? this.loading,
        error: error ?? this.error,
        shop: shop ?? this.shop,
        favourite: favourite ?? this.favourite,
      );

  @override
  List<Object?> get props => [loading, error, shop, favourite];
}

class ShopDetailCubit extends Cubit<ShopDetailState> {
  ShopDetailCubit(this._repo) : super(const ShopDetailState());
  final KeetaRepository _repo;

  void load(String shopId) {
    emit(const ShopDetailState(loading: true));
    try {
      final shop = _repo.shopById(shopId);
      emit(ShopDetailState(loading: false, shop: shop));
    } catch (_) {
      emit(const ShopDetailState(loading: false, error: true));
    }
  }

  void toggleFavourite() =>
      emit(state.copyWith(favourite: !state.favourite));
}

/// KeeTa shop-detail panel: collapsing cover hero, info card (name / rating /
/// tags / description), delivery rows, opening hours, address + map placeholder,
/// and a sticky Favourite toggle.
class ShopDetailScreen extends StatelessWidget {
  const ShopDetailScreen({super.key, this.shopId = 's1'});
  final String shopId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ShopDetailCubit(sl<KeetaRepository>())..load(shopId),
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
          if (state.loading) return const AppLoader();
          if (state.error || state.shop == null) {
            return ErrorView(
                onRetry: () => context.read<ShopDetailCubit>().load(shopId));
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
  final Shop shop;
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
  final Shop shop;
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
        _CircleAction(
          icon: KeetaIcons.share,
          onTap: () {},
        ),
        _CircleAction(
          icon: KeetaIcons.favorite,
          color: favourite ? AppColors.accent1 : AppColors.white,
          onTap: () => context.read<ShopDetailCubit>().toggleFavourite(),
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
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.r4),
                  boxShadow: const [
                    BoxShadow(
                        color: AppColors.overlayDivider,
                        blurRadius: 6,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: KeetaImage(
                    url: shop.logo,
                    width: 56,
                    height: 56,
                    radius: AppRadius.r5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.onTap,
    this.color = AppColors.white,
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.s8),
      child: GestureDetector(
        onTap: onTap,
        child: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.overlayPrimary,
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }
}

// ── Info card (name, rating, tags, description) ──────────────────────────────
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(shop.name,
              style: AppTextStyles.displaySmall
                  .copyWith(fontWeight: AppTextStyles.bold)),
          const SizedBox(height: AppSpacing.s8),
          Row(
            children: [
              RatingBadge(rating: shop.rating, count: shop.ratingCount),
              const SizedBox(width: AppSpacing.s8),
              Text('·',
                  style: AppTextStyles.captionLarge
                      .copyWith(color: AppColors.tertiaryText)),
              const SizedBox(width: AppSpacing.s8),
              Text(Formatters.distance(shop.distanceKm),
                  style: AppTextStyles.captionLarge
                      .copyWith(color: AppColors.tertiaryText)),
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
          _SubHeader(label: 'About'),
          const SizedBox(height: AppSpacing.s6),
          Text(_description(shop),
              style: AppTextStyles.bodyLarge
                  .copyWith(color: AppColors.secondaryText)),
        ],
      ),
    );
  }

  String _description(Shop shop) {
    final kind = shop.isRestaurant ? 'restaurant' : 'store';
    final tags = shop.tags.isEmpty ? '' : ' specialising in ${shop.tags.join(', ')}';
    return '${shop.name} is a popular $kind$tags. '
        'Rated ${shop.rating.toStringAsFixed(1)} by ${shop.ratingCount} customers, '
        'with delivery in ${shop.deliveryTime}.';
  }
}

// ── Delivery card ─────────────────────────────────────────────────────────────
class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SubHeader(label: 'Delivery'),
          const SizedBox(height: AppSpacing.s12),
          _InfoRow(
            icon: KeetaIcons.delivery,
            label: 'Delivery fee',
            value: shop.freeDelivery
                ? 'Free delivery'
                : Formatters.price(shop.deliveryFee),
            valueColor:
                shop.freeDelivery ? AppColors.freeDelivery : AppColors.primaryText,
          ),
          const SizedBox(height: AppSpacing.s12),
          _InfoRow(
            icon: KeetaIcons.time,
            label: 'Delivery time',
            value: shop.deliveryTime,
          ),
          const SizedBox(height: AppSpacing.s12),
          _InfoRow(
            icon: KeetaIcons.cart,
            label: 'Minimum order',
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
              _SubHeader(label: 'Opening hours'),
              const Spacer(),
              TagChip(
                label: 'Open now',
                bg: AppColors.freeDeliveryBg,
                fg: AppColors.freeDelivery,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          for (final day in _days) ...[
            Padding(
              padding:
                  const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.s6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(day,
                        style: AppTextStyles.bodyLarge
                            .copyWith(color: AppColors.secondaryText)),
                  ),
                  Text(day == 'Sunday' ? '10:00 - 22:00' : '09:00 - 23:00',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.primaryText)),
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
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SubHeader(label: 'Location'),
          const SizedBox(height: AppSpacing.s12),
          _InfoRow(
            icon: KeetaIcons.location,
            label: '${shop.name} Branch',
            value: Formatters.distance(shop.distanceKm),
          ),
          const SizedBox(height: AppSpacing.s12),
          ClipRRect(
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
                  child: Icon(KeetaIcons.storeLocation,
                      size: 34, color: AppColors.accent1),
                ),
              ],
            ),
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
              label: fav ? 'Saved to favourites' : 'Add to favourites',
              onPressed: () => context.read<ShopDetailCubit>().toggleFavourite(),
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
      margin: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.pageMargin, AppSpacing.s8, AppSpacing.pageMargin, 0),
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
    return Text(label,
        style:
            AppTextStyles.headingMedium.copyWith(fontWeight: AppTextStyles.bold));
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
        Icon(icon, size: 18, color: AppColors.secondaryText),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Text(label,
              style: AppTextStyles.bodyLarge
                  .copyWith(color: AppColors.secondaryText)),
        ),
        Text(value,
            style: AppTextStyles.headingSmall
                .copyWith(color: valueColor, fontWeight: AppTextStyles.bold)),
      ],
    );
  }
}
