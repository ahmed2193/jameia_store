import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/fly_to_cart.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/count_badge.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';

/// The cart in the chat's app bar, with the unit count badge ([CountBadge]:
/// it bumps and rolls when an added product lands here). While the chat is
/// open it is where an added product flies to, since the chat covers the tab
/// bar's cart.
class AssistantCartButton extends StatefulWidget {
  const AssistantCartButton({super.key});

  @override
  State<AssistantCartButton> createState() => _AssistantCartButtonState();
}

class _AssistantCartButtonState extends State<AssistantCartButton> {
  final GlobalKey _targetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    FlyToCart.pushTarget(_targetKey);
  }

  @override
  void dispose() {
    FlyToCart.popTarget(_targetKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = context.select<CartCubit, int>((cart) => cart.state.totalQty);
    return IconButton(
      tooltip: 'cart.title'.tr(),
      onPressed: () => context.push(Routes.cartPreview),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          HeroIcon(
            HeroIcons.cart,
            key: _targetKey,
            size: AppSize.s22,
            color: AppColors.primaryText,
          ),
          // Always mounted: it fades out at zero instead of cutting.
          PositionedDirectional(
            top: -AppSpacing.s6,
            end: -AppSpacing.s8,
            child: CountBadge(
              count: count,
              color: AppColors.accent1Dark,
              borderColor: AppColors.white,
              landsWithFlight: true,
            ),
          ),
        ],
      ),
    );
  }
}
