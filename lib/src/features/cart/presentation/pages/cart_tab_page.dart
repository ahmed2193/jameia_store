import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../cubit/cart_deals_cubit.dart';
import '../widgets/cart/cart_view.dart';

/// The cart as the Cart tab's default view. The tab draws the header (its
/// cart / order-history switch), so the page has no bar of its own: the
/// "n items · Clear cart" header over the lines carries clear, as it does on
/// the pushed cart page. Provides the "Buy more, save more" sheet's cubit
/// (created when the sheet first opens).
class CartTabPage extends StatelessWidget {
  const CartTabPage({super.key, required this.onBrowse});

  /// Back to the Home tab from an empty cart.
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CartDealsCubit>(
      create: (_) => sl<CartDealsCubit>(),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: CartView(onBrowse: onBrowse),
      ),
    );
  }
}
