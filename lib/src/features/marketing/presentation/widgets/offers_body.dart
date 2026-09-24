import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/navigation/jameia_snack_bar.dart';
import '../../../../core/utils/failure_message.dart';
import '../../../../core/widgets/branded_refresh.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/offers_cubit.dart';
import '../cubit/offers_state.dart';
import 'offer_tile.dart';

/// Body of the offers page: loader, the lazily built list, empty, error +
/// retry (offline = the error view). A failed pull-to-refresh keeps the list.
class OffersBody extends StatelessWidget {
  const OffersBody({super.key});

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
        switch (state.status) {
          case OffersStatus.initial:
          case OffersStatus.loading:
            return const AppLoader();
          case OffersStatus.error:
            return ErrorView(
              message: state.failure?.localizedMessage,
              onRetry: cubit.load,
            );
          case OffersStatus.loaded:
            return BrandedRefresh(
              onRefresh: cubit.refresh,
              child: state.isEmpty
                  ? EmptyStateView(
                      message: 'offers.empty'.tr(),
                      icon: Icons.local_offer_outlined,
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsetsDirectional.only(
                        top: AppSpacing.s12,
                        bottom: AppSpacing.s24,
                      ),
                      itemCount: state.offers.length,
                      itemBuilder: (context, index) => OfferTile(
                        key: ValueKey(state.offers[index].id),
                        offer: state.offers[index],
                      ),
                    ),
            );
        }
      },
    );
  }
}
