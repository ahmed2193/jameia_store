import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/navigation/jameia_snack_bar.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/failure_message.dart';
import '../../../../../core/widgets/branded_refresh.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../cubit/product_listing_cubit.dart';
import '../../cubit/product_listing_state.dart';
import 'listing_load_more_footer.dart';
import 'listing_toolbar.dart';
import 'product_grid_sliver.dart';

/// Body shared by every product listing (category, brand, collection, offers):
/// [headerSlivers] (a category's chips, nothing for a plain listing) → sort +
/// filters → result count → the lazily built grid → load-more footer. Loading,
/// empty, error + retry and offline (= the error view) live below the toolbar,
/// so the customer can always change a filter that emptied the list.
class ProductListingBody extends StatelessWidget {
  const ProductListingBody({
    super.key,
    this.headerSlivers = const <Widget>[],
    this.onRefresh,
  });

  final List<Widget> headerSlivers;

  /// Pull-to-refresh. Defaults to reloading the list; a page whose header
  /// has its own backend read (the category rows) refreshes both.
  final Future<void> Function()? onRefresh;

  /// Fetch the next page this far before the end, so scrolling rarely stalls.
  static const double _loadMoreThreshold = AppSize.s500;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductListingCubit, ProductListingState>(
      listenWhen: (previous, current) =>
          current.failure != null &&
          current.isLoaded &&
          previous.failure != current.failure,
      listener: (context, state) =>
          showJameiaSnackBar(context, state.failure!.localizedMessage),
      builder: (context, state) {
        final cubit = context.read<ProductListingCubit>();
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.axis == Axis.vertical &&
                notification.metrics.extentAfter < _loadMoreThreshold) {
              cubit.loadMore();
            }
            return false;
          },
          child: BrandedRefresh(
            onRefresh: onRefresh ?? cubit.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                ...headerSlivers,
                const SliverToBoxAdapter(child: ListingToolbar()),
                ...switch (state.status) {
                  ProductListingStatus.initial ||
                  ProductListingStatus.loading => const [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppLoader(),
                    ),
                  ],
                  ProductListingStatus.error => [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ErrorView(
                        message: state.failure?.localizedMessage,
                        onRetry: cubit.load,
                      ),
                    ),
                  ],
                  ProductListingStatus.loaded when state.isEmpty => [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateView(
                        message: 'shop.no_products_here'.tr(),
                        icon: Icons.search_off_rounded,
                      ),
                    ),
                  ],
                  ProductListingStatus.loaded => [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpacing.pageMargin,
                        ),
                        child: Text(
                          'shop.results_count'.tr(
                            namedArgs: {'count': '${state.products.total}'},
                          ),
                          style: AppTextStyles.captionLarge.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ),
                    ProductGridSliver(products: state.products.products),
                    SliverToBoxAdapter(
                      child: ListingLoadMoreFooter(
                        isLoading: state.isLoadingMore,
                        hasFailed: state.loadMoreFailed,
                        onRetry: () => cubit.loadMore(retry: true),
                      ),
                    ),
                  ],
                },
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.s24),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
