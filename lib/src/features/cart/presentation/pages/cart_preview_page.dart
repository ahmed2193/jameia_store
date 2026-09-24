import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../widgets/cart/cart_app_bar.dart';
import '../widgets/cart/cart_view.dart';

/// The cart pushed on top of a screen (`Routes.cartPreview`) — from the
/// home / listing cart bar or the product page, where the Cart tab is not in
/// reach. Same content as the tab; here an empty cart goes back to shopping by
/// popping.
class CartPreviewPage extends StatelessWidget {
  const CartPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      appBar: const CartAppBar(),
      body: CartView(onBrowse: () => context.pop()),
    );
  }
}
