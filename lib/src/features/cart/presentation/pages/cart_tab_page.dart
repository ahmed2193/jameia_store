import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../widgets/cart/cart_view.dart';

/// The cart as the Cart tab's default view. The tab draws the header (its
/// cart / order-history switch), so the page has no app bar: the item count
/// and "clear" sit over the lines instead.
class CartTabPage extends StatelessWidget {
  const CartTabPage({super.key, required this.onBrowse});

  /// Back to the Home tab from an empty cart.
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      body: CartView(onBrowse: onBrowse, showHeader: true),
    );
  }
}
