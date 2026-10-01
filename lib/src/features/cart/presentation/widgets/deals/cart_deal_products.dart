import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/utils/failure_message.dart';
import '../../../../../core/widgets/app_loader.dart';
import '../../../../../core/widgets/hero_state_view.dart';
import '../../cubit/cart_deals_cubit.dart';
import '../../cubit/cart_deals_state.dart';
import 'cart_deal_grid.dart';

/// What the sheet lists under the selected deal: a loader, the error with a
/// retry (offline → "no internet"), "no deals right now", or the grid.
/// Cross-fades only when that changes.
class CartDealProducts extends StatelessWidget {
  const CartDealProducts({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartDealsCubit, CartDealsState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.products != current.products ||
          previous.selectedOfferId != current.selectedOfferId,
      builder: (context, state) {
        final failure = state.failure;
        return FadeThroughSwitcher(
          stateKey: (state.status, state.selectedOfferId),
          alignment: AlignmentDirectional.topCenter,
          child: state.isLoading
              ? const AppLoader()
              : failure != null
              ? HeroStateView.error(
                  message: failure.localizedMessage,
                  onRetry: () => context.read<CartDealsCubit>().retry(),
                )
              : state.isEmpty
              ? HeroStateView(
                  message: 'cart.deals_empty'.tr(),
                  art: HeroAssets.emptyCoupons,
                )
              : CartDealGrid(products: state.products),
        );
      },
    );
  }
}
