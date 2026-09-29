import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/motion/fly_to_cart.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/count_badge.dart';
import '../../../../core/widgets/round_outlined_button.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';

/// Cart shortcut of the product page's top bar: a round white button with a
/// small brand-green item-count badge ([CountBadge]) at its top-end corner
/// that bumps when an added product lands. While this page is on top it is
/// where the fly-to-cart thumbnail lands.
class PdpCartAction extends StatefulWidget {
  const PdpCartAction({super.key});

  @override
  State<PdpCartAction> createState() => _PdpCartActionState();
}

class _PdpCartActionState extends State<PdpCartAction> {
  final GlobalKey _targetKey = GlobalKey();

  static const double _badgeInset = -AppSpacing.s2;

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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        RoundOutlinedButton(
          key: _targetKey,
          icon: HeroIcons.cart,
          label: 'cart.title'.tr(),
          onTap: () => context.push(Routes.cartPreview),
        ),
        PositionedDirectional(
          top: _badgeInset,
          end: _badgeInset,
          child: BlocSelector<CartCubit, CartState, int>(
            selector: (cart) => cart.totalQty,
            // Always mounted: it fades out at zero instead of cutting.
            builder: (context, count) => ExcludeSemantics(
              child: CountBadge(
                count: count,
                color: AppColors.primary,
                textColor: AppColors.brandForeground,
                textStyle: AppTextStyles.captionMedium.copyWith(
                  fontWeight: AppTextStyles.bold,
                ),
                borderColor: AppColors.white,
                minSize: AppSize.s18,
                landsWithFlight: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
