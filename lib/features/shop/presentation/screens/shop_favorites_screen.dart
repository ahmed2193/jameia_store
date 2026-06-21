import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/design/keeta_assets.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';

// ── Page cubit (constructed INLINE, never registered in the service locator) ──

/// State for the favourited-shops page.
sealed class ShopFavoritesState {
  const ShopFavoritesState();
}

class ShopFavoritesLoading extends ShopFavoritesState {
  const ShopFavoritesLoading();
}

class ShopFavoritesLoaded extends ShopFavoritesState {
  const ShopFavoritesLoaded(this.shops);
  final List<Shop> shops;
}

class ShopFavoritesError extends ShopFavoritesState {
  const ShopFavoritesError();
}

/// Page-scoped cubit serving the user's favourited shops. Dummy data only — the
/// whole shop catalogue stands in for "favourites" until a real backend exists.
class ShopFavoritesCubit extends Cubit<ShopFavoritesState> {
  ShopFavoritesCubit(this._repo) : super(const ShopFavoritesLoading());

  final KeetaRepository _repo;

  void load() {
    try {
      emit(ShopFavoritesLoaded(_repo.shops));
    } catch (_) {
      emit(const ShopFavoritesError());
    }
  }
}

/// KeeTa `shop_favorites` (bundle 49) — the user's favourited shops list. Plain
/// AppBar titled "Favourites" over a feed of [ShopCard]s; tapping a card opens
/// the shop menu. Empty state shows KeeTa's heart illustration.
class ShopFavoritesScreen extends StatelessWidget {
  const ShopFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ShopFavoritesCubit(sl<KeetaRepository>())..load(),
      child: const _FavoritesView(),
    );
  }
}

class _FavoritesView extends StatelessWidget {
  const _FavoritesView();

  void _openShop(BuildContext context, String shopId) =>
      Navigator.pushNamed(context, Routes.shop, arguments: shopId);

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
          icon: const Icon(KeetaIcons.back, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('Favourites',
            style: AppTextStyles.headingLarge
                .copyWith(fontWeight: AppTextStyles.bold)),
      ),
      body: BlocBuilder<ShopFavoritesCubit, ShopFavoritesState>(
        builder: (context, state) {
          return switch (state) {
            ShopFavoritesLoading() => const AppLoader(),
            ShopFavoritesError() => ErrorView(
                onRetry: () => context.read<ShopFavoritesCubit>().load()),
            ShopFavoritesLoaded(:final shops) => shops.isEmpty
                ? const _EmptyFavorites()
                : _FavoritesList(shops: shops, onOpen: _openShop),
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
      itemBuilder: (_, i) => ShopCard(
        shop: shops[i],
        onTap: () => onOpen(context, shops[i].id),
      ),
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
              KeetaAssets.shopEmptyHeart,
              width: 96,
              height: 96,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: AppSpacing.s16),
            Text('No favourites yet',
                style: AppTextStyles.headingMedium
                    .copyWith(fontWeight: AppTextStyles.bold)),
            const SizedBox(height: AppSpacing.s4),
            Text('Tap the heart on a shop to save it here.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.secondaryText)),
          ],
        ),
      ),
    );
  }
}
