import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/data_freshness.dart';
import '../../../../core/navigation/jameia_snack_bar.dart';
import '../../../../core/widgets/back_to_top_overlay.dart';
import '../../../../core/widgets/branded_refresh.dart';
import '../../../../core/widgets/collection_frame.dart';
import '../../../../core/widgets/cubit_stale_notice.dart';
import '../../../../core/widgets/reconnect_refresh.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/offers_cubit.dart';
import '../cubit/offers_state.dart';
import 'offers_list_sliver.dart';
import 'offers_skeleton.dart';

/// The scroll view of the offers page: the collection frame's
/// [headerSlivers] (top bar + hero) first, then skeleton cards, the lazily
/// built list (the saved one at once, with the "Updated … ago" note while
/// offline), empty, or error + retry — "No connection" when nothing is
/// saved. Pull to refresh; a failed refresh keeps the list and says so in a
/// snack bar (never offline: the banner speaks). A returning connection
/// refreshes a saved or failed list.
class OffersBody extends StatelessWidget {
  const OffersBody({super.key, required this.headerSlivers});

  final List<Widget> headerSlivers;

  static DataFreshness _freshnessOf(OffersState state) => state.freshness;

  @override
  Widget build(BuildContext context) {
    return ReconnectRefresh(
      onReconnected: () => context.read<OffersCubit>().onReconnected(),
      child: BlocConsumer<OffersCubit, OffersState>(
        listenWhen: (previous, current) =>
            current.failure != null &&
            current.isLoaded &&
            previous.failure != current.failure,
        listener: (context, state) =>
            showFailureSnackBar(context, state.failure!),
        buildWhen: (previous, current) =>
            previous.status != current.status ||
            previous.offers != current.offers,
        builder: (context, state) {
          final cubit = context.read<OffersCubit>();
          final content = switch (state.status) {
            OffersStatus.initial || OffersStatus.loading =>
              const SliverToBoxAdapter(child: OffersSkeleton()),
            OffersStatus.error => SliverFillRemaining(
              hasScrollBody: false,
              child: FailureView(failure: state.failure, onRetry: cubit.load),
            ),
            OffersStatus.loaded when state.isEmpty => SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateView(
                message: 'offers.empty'.tr(),
                icon: Icons.local_offer_outlined,
              ),
            ),
            OffersStatus.loaded => OffersListSliver(offers: state.offers),
          };
          return BackToTopOverlay(
            child: BrandedRefresh(
              onRefresh: cubit.refresh,
              edgeOffset: CollectionFrame.pinnedExtent(context),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  ...headerSlivers,
                  if (state.isLoaded)
                    const SliverToBoxAdapter(
                      child: CubitStaleNotice<OffersCubit, OffersState>(
                        freshnessOf: _freshnessOf,
                      ),
                    ),
                  content,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
