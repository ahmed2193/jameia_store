import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/route_args/product_listing_args.dart';
import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/domain/entities/screen_load.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/navigation/screen_failure_listener.dart';
import '../../../../../core/widgets/branded_refresh.dart';
import '../../../../../core/widgets/reconnect_refresh.dart';
import '../../../../../core/widgets/screen_stale_notice.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../cubit/brands_cubit.dart';
import '../../cubit/brands_state.dart';
import 'brand_tile.dart';
import 'brands_skeleton.dart';

/// Body of the brands page: the list's bones (cross-fading into the
/// list), the lazily built list (the saved one
/// first, with the "Updated … ago" note at its top while offline), empty,
/// error + retry or "No connection" when nothing is saved. A returning
/// connection refreshes a saved list. A brand opens its product listing.
class BrandsBody extends StatelessWidget {
  const BrandsBody({super.key});

  static const Object _emptyKey = #empty;

  @override
  Widget build(BuildContext context) {
    return ReconnectRefresh(
      onReconnected: () => context.read<BrandsCubit>().onReconnected(),
      child: ScreenFailureListener<BrandsCubit, BrandsState>(
        child: BlocBuilder<BrandsCubit, BrandsState>(
          buildWhen: (previous, current) =>
              current.load.screenChangedFrom(previous.load) ||
              previous.brands != current.brands,
          builder: (context, state) {
            final cubit = context.read<BrandsCubit>();
            return FadeThroughSwitcher(
              // initial and loading share the bones. Every swap is the
              // same-place cross-fade: the bones land as the list.
              stateKey: switch (state.status) {
                LoadPhase.initial => LoadPhase.loading,
                LoadPhase.loaded when state.isEmpty => _emptyKey,
                final status => status,
              },
              crossFade: true,
              child: switch (state.status) {
                LoadPhase.initial ||
                LoadPhase.loading => const BrandsSkeleton(),
                LoadPhase.error => FailureView(
                  failure: state.failure,
                  onRetry: cubit.load,
                ),
                LoadPhase.loaded => BrandedRefresh(
                  onRefresh: cubit.refresh,
                  child: state.isEmpty
                      ? CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            const SliverToBoxAdapter(
                              child:
                                  ScreenStaleNotice<BrandsCubit, BrandsState>(),
                            ),
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: EmptyStateView(
                                message: 'shop.no_brands'.tr(),
                                art: HeroAssets.emptyShelf,
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsetsDirectional.only(
                            top: AppSpacing.s12,
                            bottom: AppSpacing.s24,
                          ),
                          // The note scrolls away with the list, as on
                          // every other cached screen.
                          itemCount: state.brands.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return const ScreenStaleNotice<
                                BrandsCubit,
                                BrandsState
                              >();
                            }
                            final brand = state.brands[index - 1];
                            return BrandTile(
                              key: ValueKey(brand.id),
                              brand: brand,
                              onTap: () => context.push(
                                Routes.productListing,
                                extra: ProductListingArgs.brand(
                                  slug: brand.slug,
                                  title: brand.name,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              },
            );
          },
        ),
      ),
    );
  }
}
