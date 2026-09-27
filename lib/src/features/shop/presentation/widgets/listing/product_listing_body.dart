import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/screen_load.dart';
import '../../../../../core/navigation/screen_failure_listener.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/back_to_top_overlay.dart';
import '../../../../../core/widgets/branded_refresh.dart';
import '../../../../../core/widgets/reconnect_refresh.dart';
import '../../../../../core/widgets/screen_stale_notice.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../cubit/product_listing_cubit.dart';
import '../../cubit/product_listing_state.dart';
import 'listing_grid_skeleton.dart';
import 'listing_load_more_footer.dart';
import 'listing_results_count.dart';
import 'listing_reveal.dart';
import 'listing_reveal_item.dart';
import 'listing_toolbar.dart';
import 'listing_viewport_skeleton.dart';
import 'product_grid_sliver.dart';

/// Body shared by every product listing (category, brand, collection, offers):
/// [headerSlivers] (a category's chips, a collection page's bar, hero and
/// tabs, nothing for a plain listing) → sort + filters → result count → the
/// lazily built grid → load-more footer. Loading, empty, error + retry and
/// offline ("No connection" when nothing is saved) live below the toolbar,
/// so the customer can always change a filter that emptied the list. A saved
/// first page shows with the "Updated … ago" note while offline; a returning
/// connection refreshes it (or the page that failed to load more). A
/// collection page has no toolbar and no count ([showsToolbar] = false).
///
/// Motion: while loading, shimmering card bones stand where the cards will
/// be; as a list arrives the count and the first cards come in one after
/// another ([ListingReveal]), and so does an empty or error view. Well down
/// the list a round button takes the customer back to the top.
class ProductListingBody extends StatelessWidget {
  const ProductListingBody({
    super.key,
    this.headerSlivers = const <Widget>[],
    this.onRefresh,
    this.showsToolbar = true,
    this.reservesViewportWhileLoading = false,
    this.refreshEdgeOffset = 0,
  });

  final List<Widget> headerSlivers;

  /// The sort / filter toolbar and the result count. A collection page
  /// (hero + category tabs) shows neither.
  final bool showsToolbar;

  /// While the list (re)loads, keep at least a screenful of bones below the
  /// headers, so a list restarted from pinned tabs keeps its scroll position
  /// instead of dragging the hero back into view.
  final bool reservesViewportWhileLoading;

  /// Where the pull-to-refresh spinner starts: below a bar pinned over the
  /// list (a collection page), else at the top.
  final double refreshEdgeOffset;

  /// Pull-to-refresh. Defaults to reloading the list; a page whose header
  /// has its own backend read (the category rows) refreshes both.
  final Future<void> Function()? onRefresh;

  /// Fetch the next page this far before the end, so scrolling rarely stalls.
  static const double _loadMoreThreshold = AppSize.s500;

  @override
  Widget build(BuildContext context) {
    return ReconnectRefresh(
      onReconnected: () => context.read<ProductListingCubit>().onReconnected(),
      child: ScreenFailureListener<ProductListingCubit, ProductListingState>(
        child: BlocBuilder<ProductListingCubit, ProductListingState>(
          // A new freshness (the same page, now the server's), a transient
          // failure or the next page's progress (the footer selects that
          // itself) change nothing in the grid: never rebuild it for them.
          buildWhen: (previous, current) =>
              current.load.screenChangedFrom(previous.load) ||
              previous.products != current.products,
          builder: (context, state) {
            final cubit = context.read<ProductListingCubit>();
            return ListingReveal(
              settled:
                  state.status == LoadPhase.loaded ||
                  state.status == LoadPhase.error,
              child: BackToTopOverlay(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.axis == Axis.vertical &&
                        notification.metrics.extentAfter < _loadMoreThreshold) {
                      cubit.loadMore();
                    }
                    return false;
                  },
                  child: BrandedRefresh(
                    onRefresh: onRefresh ?? cubit.refresh,
                    edgeOffset: refreshEdgeOffset,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        ...headerSlivers,
                        if (showsToolbar)
                          const SliverToBoxAdapter(child: ListingToolbar()),
                        ...switch (state.status) {
                          LoadPhase.initial || LoadPhase.loading => [
                            if (reservesViewportWhileLoading)
                              const ListingViewportSkeleton()
                            else
                              const SliverToBoxAdapter(
                                child: ListingGridSkeleton(),
                              ),
                          ],
                          LoadPhase.error => [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: ListingRevealItem(
                                index: 0,
                                child: FailureView(
                                  failure: state.failure,
                                  onRetry: cubit.load,
                                ),
                              ),
                            ),
                          ],
                          LoadPhase.loaded when state.isEmpty => [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: ListingRevealItem(
                                index: 0,
                                child: EmptyStateView(
                                  message: 'shop.no_products_here'.tr(),
                                  icon: Icons.search_off_rounded,
                                ),
                              ),
                            ),
                          ],
                          LoadPhase.loaded => [
                            const SliverToBoxAdapter(
                              child:
                                  ScreenStaleNotice<
                                    ProductListingCubit,
                                    ProductListingState
                                  >(),
                            ),
                            if (showsToolbar)
                              SliverToBoxAdapter(
                                child: ListingRevealItem(
                                  index: 0,
                                  child: ListingResultsCount(
                                    total: state.products.total,
                                  ),
                                ),
                              )
                            else
                              const SliverToBoxAdapter(
                                child: SizedBox(height: AppSpacing.s8),
                              ),
                            ProductGridSliver(
                              products: state.products.products,
                              firstRevealIndex: showsToolbar ? 1 : 0,
                            ),
                            const SliverToBoxAdapter(
                              child: ListingLoadMoreFooter(),
                            ),
                          ],
                        },
                        const SliverToBoxAdapter(
                          child: SizedBox(height: AppSpacing.s24),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
