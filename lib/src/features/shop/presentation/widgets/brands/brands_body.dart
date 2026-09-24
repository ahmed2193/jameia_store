import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/route_args/product_listing_args.dart';
import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/navigation/jameia_snack_bar.dart';
import '../../../../../core/utils/failure_message.dart';
import '../../../../../core/widgets/branded_refresh.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../cubit/brands_cubit.dart';
import '../../cubit/brands_state.dart';
import 'brand_tile.dart';

/// Body of the brands page: loader, the lazily built list, empty, error +
/// retry (offline = the error view). A brand opens its product listing.
class BrandsBody extends StatelessWidget {
  const BrandsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BrandsCubit, BrandsState>(
      listenWhen: (previous, current) =>
          current.failure != null &&
          current.isLoaded &&
          previous.failure != current.failure,
      listener: (context, state) =>
          showJameiaSnackBar(context, state.failure!.localizedMessage),
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.brands != current.brands,
      builder: (context, state) {
        final cubit = context.read<BrandsCubit>();
        switch (state.status) {
          case BrandsStatus.initial:
          case BrandsStatus.loading:
            return const AppLoader();
          case BrandsStatus.error:
            return ErrorView(
              message: state.failure?.localizedMessage,
              onRetry: cubit.load,
            );
          case BrandsStatus.loaded:
            return BrandedRefresh(
              onRefresh: cubit.refresh,
              child: state.isEmpty
                  ? EmptyStateView(
                      message: 'shop.no_brands'.tr(),
                      icon: Icons.workspace_premium_outlined,
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsetsDirectional.only(
                        top: AppSpacing.s12,
                        bottom: AppSpacing.s24,
                      ),
                      itemCount: state.brands.length,
                      itemBuilder: (context, index) {
                        final brand = state.brands[index];
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
    );
  }
}
