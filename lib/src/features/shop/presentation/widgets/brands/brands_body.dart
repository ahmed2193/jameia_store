import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/route_args/product_listing_args.dart';
import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/screen_load.dart';
import '../../../../../core/navigation/screen_failure_listener.dart';
import '../../../../../core/widgets/branded_refresh.dart';
import '../../../../../core/widgets/reconnect_refresh.dart';
import '../../../../../core/widgets/screen_stale_notice.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../cubit/brands_cubit.dart';
import '../../cubit/brands_state.dart';
import 'brand_tile.dart';

/// Body of the brands page: loader, the lazily built list (the saved one
/// first, with the "Updated … ago" note at its top while offline), empty,
/// error + retry or "No connection" when nothing is saved. A returning
/// connection refreshes a saved list. A brand opens its product listing.
class BrandsBody extends StatelessWidget {
  const BrandsBody({super.key});

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
            switch (state.status) {
              case LoadPhase.initial:
              case LoadPhase.loading:
                return const AppLoader();
              case LoadPhase.error:
                return FailureView(failure: state.failure, onRetry: cubit.load);
              case LoadPhase.loaded:
                return BrandedRefresh(
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
                                icon: Icons.workspace_premium_outlined,
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
                );
            }
          },
        ),
      ),
    );
  }
}
