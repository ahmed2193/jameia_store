import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/design/jameia_assets.dart';
import '../../../../core/design/jameia_icons.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/widgets/skeletons.dart';
import '../cubit/shop_favorites_cubit.dart';

/// Jameia `shop_favorites` (bundle 49) — the user's favourited shops list. Plain
/// AppBar titled "Favourites" over a feed of [ShopCard]s; tapping a card opens
/// the shop menu. Empty state shows Jameia's heart illustration.
class ShopFavoritesPage extends StatelessWidget {
  const ShopFavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ShopFavoritesCubit>(),
      child: const _FavoritesView(),
    );
  }
}

class _FavoritesView extends StatelessWidget {
  const _FavoritesView();

  void _openShop(BuildContext context, String shopId) =>
      context.push(Routes.shop, extra: shopId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(JameiaIcons.back, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'shop.favourites'.tr(),
          style: AppTextStyles.headingLarge.copyWith(
            fontWeight: AppTextStyles.bold,
          ),
        ),
      ),
      body: BlocBuilder<ShopFavoritesCubit, ShopFavoritesState>(
        builder: (context, state) {
          return switch (state.status) {
            ShopFavoritesStatus.initial ||
            ShopFavoritesStatus.loading => const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s12,
              ),
              child: Skeletonized(loading: true, child: ListSkeleton(count: 6)),
            ),
            ShopFavoritesStatus.error => ErrorView(
              onRetry: () => context.read<ShopFavoritesCubit>().load(),
            ),
            ShopFavoritesStatus.empty => const _EmptyFavorites(),
            ShopFavoritesStatus.loaded => _FavoritesList(
              shops: state.shops,
              onOpen: _openShop,
            ),
          };
        },
      ),
    );
  }
}

class _FavoritesList extends StatelessWidget {
  const _FavoritesList({required this.shops, required this.onOpen});

  final List<Shop> shops;
  final void Function(BuildContext, String) onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s24),
      itemCount: shops.length,
      separatorBuilder: (_, _) =>
          const ThinDivider(indent: AppSpacing.pageMargin),
      itemBuilder: (_, i) =>
          ShopCard(shop: shops[i], onTap: () => onOpen(context, shops[i].id)),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              JameiaAssets.shopEmptyHeart,
              width: 96,
              height: 96,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              'shop.no_favourites_yet'.tr(),
              style: AppTextStyles.displaySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'shop.favourites_empty_hint'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
