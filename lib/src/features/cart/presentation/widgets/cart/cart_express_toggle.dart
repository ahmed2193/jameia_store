import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/jameia_list_row.dart';
import '../../../domain/entities/cart_snapshot.dart';
import '../../cubit/cart_cubit.dart';

/// Express delivery switch; the options section shows it only when the
/// server offers it for this cart (`expressOffered`). The surcharge and ETA
/// come with the offer. The whole row toggles, like a switch list tile, and
/// is read out as one labelled switch.
class CartExpressToggle extends StatelessWidget {
  const CartExpressToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final (selected, minutes, surchargeKd) = context
        .select<CartCubit, (bool, int?, double)>(
          (cubit) => (
            cubit.state.cart.expressSelected,
            cubit.state.cart.expressEtaMinutes,
            cubit.state.cart.expressSurchargeOfferedKd,
          ),
        );
    final busy = context.select<CartCubit, bool>(
      (cubit) => cubit.state.busyAction == CartAction.express,
    );
    void toggle(bool enabled) {
      Haptics.selection();
      context.read<CartCubit>().setExpress(enabled: enabled);
    }

    return JameiaListRow(
      icon: Icons.bolt_rounded,
      title: 'cart.express_title'.tr(),
      subtitle: 'cart.express_subtitle'.tr(
        namedArgs: {
          'minutes': '${minutes ?? 0}',
          'amount': Formatters.price(surchargeKd),
        },
      ),
      trailing: Switch.adaptive(
        value: selected,
        onChanged: busy ? null : toggle,
        activeTrackColor: AppColors.primary,
      ),
      onTap: busy ? null : () => toggle(!selected),
      showChevron: false,
    );
  }
}
