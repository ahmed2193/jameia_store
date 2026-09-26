import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/widgets/jameia_section_header.dart';
import '../../../../../core/widgets/jameia_text_link.dart';
import '../../cubit/cart_cubit.dart';
import 'cart_clear_dialog.dart';

/// "3 items · Clear cart" over the lines — the page's lead heading, in both
/// hosts (the Cart tab has no bar; the pushed page's bar has no actions).
/// The link stays in place but greys out while nothing can be cleared.
class CartItemsHeader extends StatelessWidget {
  const CartItemsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final (count, canClear) = context.select<CartCubit, (int, bool)>(
      (cubit) => (
        cubit.state.totalQty,
        cubit.state.cart.lines.isNotEmpty && !cubit.state.isBusy,
      ),
    );
    return JameiaSectionHeader(
      title: 'cart.items_count'.tr(namedArgs: {'count': '$count'}),
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.gutter,
        AppSpacing.s16,
        AppSpacing.gutter,
        AppSpacing.s8,
      ),
      trailing: JameiaTextLink(
        label: 'cart.clear'.tr(),
        navigates: false,
        onTap: canClear
            ? () {
                Haptics.selection();
                CartClearDialog.confirmAndClear(context);
              }
            : null,
      ),
    );
  }
}
