import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/navigation/screen_failure_listener.dart';
import '../../../../core/widgets/back_to_top_overlay.dart';
import '../../../../core/widgets/branded_refresh.dart';
import '../../../../core/widgets/collection_frame.dart';
import '../../../../core/widgets/reconnect_refresh.dart';
import '../../../../core/widgets/screen_stale_notice.dart';
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

  @override
  Widget build(BuildContext context) {
    return ReconnectRefresh(
      onReconnected: () => context.read<OffersCubit>().onReconnected(),
      child: ScreenFailureListener<OffersCubit, OffersState>(
        child: BlocBuilder<OffersCubit, OffersState>(
          buildWhen: (previous, current) =>
              current.load.screenChangedFrom(previous.load) ||
              previous.offers != current.offers,
          builder: (context, state) {
            final cubit = context.read<OffersCubit>();
            final content = switch (state.status) {
              LoadPhase.initial || LoadPhase.loading =>
                const SliverToBoxAdapter(child: OffersSkeleton()),
              LoadPhase.error => SliverFillRemaining(
                hasScrollBody: false,
                child: FailureView(failure: state.failure, onRetry: cubit.load),
              ),
              LoadPhase.loaded when state.isEmpty => SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView(
                  message: 'offers.empty'.tr(),
                  icon: Icons.local_offer_outlined,
                ),
              ),
              LoadPhase.loaded => OffersListSliver(offers: state.offers),
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
                        child: ScreenStaleNotice<OffersCubit, OffersState>(),
                      ),
                    content,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
