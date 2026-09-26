import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/navigation/jameia_snack_bar.dart';
import '../../../../core/utils/failure_message.dart';
import '../../../../core/widgets/back_to_top_overlay.dart';
import '../../../../core/widgets/branded_refresh.dart';
import '../../../../core/widgets/collection_frame.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/offers_cubit.dart';
import '../cubit/offers_state.dart';
import 'offers_list_sliver.dart';
import 'offers_skeleton.dart';

/// The scroll view of the offers page: the collection frame's
/// [headerSlivers] (top bar + hero) first, then skeleton cards, the lazily
/// built list, empty, or error + retry (offline = the error view). Pull to
/// refresh; a failed refresh keeps the list and says so in a snack bar.
class OffersBody extends StatelessWidget {
  const OffersBody({super.key, required this.headerSlivers});

  final List<Widget> headerSlivers;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OffersCubit, OffersState>(
      listenWhen: (previous, current) =>
          current.failure != null &&
          current.isLoaded &&
          previous.failure != current.failure,
      listener: (context, state) =>
          showJameiaSnackBar(context, state.failure!.localizedMessage),
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
            child: ErrorView(
              message: state.failure?.localizedMessage,
              onRetry: cubit.load,
            ),
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
              slivers: [...headerSlivers, content],
            ),
          ),
        );
      },
    );
  }
}
