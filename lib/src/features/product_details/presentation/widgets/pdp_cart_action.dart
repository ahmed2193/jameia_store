import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/design/jameia_icons.dart';
import '../../../../core/motion/fly_to_cart.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import 'pdp_circle_button.dart';

/// Cart shortcut of the product page's app bar with the item-count badge. It
/// is also where the fly-to-cart animation lands while this page is on top.
class PdpCartAction extends StatefulWidget {
  const PdpCartAction({super.key});

  @override
  State<PdpCartAction> createState() => _PdpCartActionState();
}

class _PdpCartActionState extends State<PdpCartAction> {
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
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.s8),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          PdpCircleButton(
            onTap: () => context.push(Routes.cartPreview),
            semanticsLabel: 'cart.title'.tr(),
            child: Icon(
              JameiaIcons.cart,
              key: _targetKey,
              size: PdpCircleButton.glyphSize,
              color: AppColors.primaryText,
            ),
          ),
          PositionedDirectional(
            top: 0,
            end: -AppSpacing.s4,
            child: BlocSelector<CartCubit, CartState, int>(
              selector: (cart) => cart.totalQty,
              builder: (context, count) => count <= 0
                  ? const SizedBox.shrink()
                  : Container(
                      constraints: const BoxConstraints(
                        minWidth: AppSize.s16,
                        minHeight: AppSize.s16,
                      ),
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.s4,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.accent1Dark,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: const Border.fromBorderSide(
                          BorderSide(color: AppColors.white, width: AppSize.s1),
                        ),
                      ),
                      child: Text(
                        '$count',
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.white,
                          fontWeight: AppTextStyles.bold,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
