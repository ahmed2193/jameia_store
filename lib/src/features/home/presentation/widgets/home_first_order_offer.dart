import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/navigation/navigation.dart';
import '../cubit/home_cubit.dart';
import 'home_first_order_dialog.dart';

/// Opens the first-order free-delivery details over home: the store's own
/// numbers from the launch snapshot (the zone's delivery fee it waives, the
/// minimum order) and whether the customer still has to sign in. The card
/// pops in on the spring (`pop: true`); a tap outside, the ✕ or "Start
/// shopping" closes it — the customer is already where shopping starts.
abstract final class HomeFirstOrderOffer {
  static Future<void> show(BuildContext context) {
    final bootstrap = context.read<HomeCubit>().state.bootstrap;
    final delivery = bootstrap.delivery;
    return showHeroDialog<void>(
      context,
      barrierLabel: 'home.popup_barrier_label'.tr(),
      barrierColor: AppColors.popupScrim,
      pop: true,
      pageBuilder: (dialogContext) => HomeFirstOrderDialog(
        deliveryFeeKd: delivery?.deliveryFeeKd ?? 0,
        minOrderKd: delivery?.minOrderKd ?? 0,
        needsSignIn: !bootstrap.hasCustomer,
        onClose: () => dialogContext.pop(),
      ),
    );
  }
}
