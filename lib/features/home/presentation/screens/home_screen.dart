import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/home_cubit.dart';
import '../widgets/kingkong_grid.dart';

/// KeeTa Home tab — yellow brand header (address + search), KingKong icon grid,
/// banner carousel, filter chips, and the shop feed.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit(sl<KeetaRepository>())..load(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  void _openShop(BuildContext context, String shopId) =>
      Navigator.pushNamed(context, Routes.shop, arguments: shopId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return switch (state) {
            HomeLoading() => const AppLoader(),
            HomeError() =>
              ErrorView(onRetry: () => context.read<HomeCubit>().load()),
            HomeLoaded() => _loaded(context, state),
          };
        },
      ),
    );
  }

  Widget _loaded(BuildContext context, HomeLoaded s) {
    return CustomScrollView(
      slivers: [
        // Brand-yellow header: address bar + search pill.
        SliverToBoxAdapter(child: _Header(address: s.address)),
        // KingKong icon grid.
        SliverToBoxAdapter(
          child: Container(
            color: AppColors.white,
            padding: const EdgeInsets.only(bottom: AppSpacing.s8),
            child: KingKongGrid(items: s.kingkong),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s8)),
        // Banner carousel.
        SliverToBoxAdapter(child: _BannerCarousel(banners: s.banners)),
        // Filter chips.
        SliverToBoxAdapter(
          child: _FilterChips(
            filters: s.filters,
            active: s.activeFilter,
            onSelect: (i) => context.read<HomeCubit>().selectFilter(i),
          ),
        ),
        // Shop feed.
        SliverList.separated(
          itemCount: s.shops.length,
          separatorBuilder: (_, _) => const ThinDivider(indent: AppSpacing.pageMargin),
          itemBuilder: (_, i) => ShopCard(
            shop: s.shops[i],
            onTap: () => _openShop(context, s.shops[i].id),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s24)),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.address});
  final KeetaAddress address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + AppSpacing.s8,
        left: AppSpacing.pageMargin,
        right: AppSpacing.pageMargin,
        bottom: AppSpacing.s12,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.white],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, size: 20, color: AppColors.black),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${address.label} · ${address.area}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingMedium
                      .copyWith(fontWeight: AppTextStyles.bold),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
              const Spacer(),
              const Icon(Icons.notifications_none_rounded, size: 24),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          // Search pill (taps into Search tab/screen).
          InkWell(
            onTap: () => Navigator.pushNamed(context, Routes.search),
            child: Container(
              height: 42,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.r1),
                boxShadow: const [
                  BoxShadow(
                      color: AppColors.overlayDivider,
                      blurRadius: 6,
                      offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      size: 20, color: AppColors.tertiaryText),
                  const SizedBox(width: 8),
                  Text('Search shops & dishes',
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: AppColors.tertiaryText)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.r1)),
                    child: Text('Search',
                        style: AppTextStyles.captionLarge.copyWith(
                            fontWeight: AppTextStyles.bold,
                            color: AppColors.black)),
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

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel({required this.banners});
  final List<HomeBanner> banners;

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 130,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            padEnds: false,
            itemBuilder: (_, i) {
              final b = widget.banners[i];
              return Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.pageMargin),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.r3),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      KeetaImage(url: b.image),
                      Container(color: AppColors.overlayDivider),
                      PositionedDirectional(
                        start: 14,
                        bottom: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.title,
                                style: AppTextStyles.headingLarge.copyWith(
                                    color: AppColors.white,
                                    fontWeight: AppTextStyles.bold)),
                            Text(b.subtitle,
                                style: AppTextStyles.captionLarge
                                    .copyWith(color: AppColors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        SmoothPageIndicator(
          controller: _controller,
          count: widget.banners.length,
          effect: const WormEffect(
            dotHeight: 6,
            dotWidth: 6,
            activeDotColor: AppColors.primaryText,
            dotColor: AppColors.disabledText,
          ),
        ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips(
      {required this.filters, required this.active, required this.onSelect});
  final List<String> filters;
  final int active;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.mediumBackground,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.pageMargin),
          itemCount: filters.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
          itemBuilder: (_, i) {
            final selected = i == active;
            return GestureDetector(
              onTap: () => onSelect(i),
              child: Container(
                padding:
                    const EdgeInsetsDirectional.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.r1),
                  border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.divider),
                ),
                child: Text(filters[i],
                    style: AppTextStyles.captionLarge.copyWith(
                        fontWeight:
                            selected ? AppTextStyles.bold : AppTextStyles.regular,
                        color: AppColors.primaryText)),
              ),
            );
          },
        ),
      ),
    );
  }
}
