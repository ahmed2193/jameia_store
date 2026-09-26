import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/widgets/jameia_title_bar.dart';
import '../cubit/cart_deals_cubit.dart';
import '../widgets/cart/cart_view.dart';

/// The cart pushed on top of a screen (`Routes.cartPreview`) — from the
/// home / listing cart bar or the product page, where the Cart tab is not in
/// reach. Same content as the tab (clear sits in the header over the lines);
/// here an empty cart goes back to shopping by popping. Provides the "Buy
/// more, save more" sheet's cubit (created when the sheet first opens).
class CartPreviewPage extends StatelessWidget {
  const CartPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CartDealsCubit>(
      create: (_) => sl<CartDealsCubit>(),
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: JameiaTitleBar(title: 'cart.title'.tr()),
        body: CartView(onBrowse: () => context.pop()),
      ),
    );
  }
}
