import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/change_bump.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../domain/entities/checkout_thumbs.dart';

/// "12 pcs ›" at the end of the order-summary strip: every piece in the
/// basket, free gifts included (plural-correct in both languages). It
/// bumps when the count changes and rebuilds only then.
class CheckoutPiecesLabel extends StatelessWidget {
  const CheckoutPiecesLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final pieces = context.select<CartCubit, int>(
      (cubit) => CheckoutThumbs.piecesOf(cubit.state.cart),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ChangeBump(
          value: pieces,
          child: Text(
            'checkout.pieces'.plural(pieces),
            maxLines: 1,
            style: AppTextStyles.itemTitle.copyWith(
              color: AppColors.primaryText,
            ),
          ),
        ),
        const HeroIcon(
          HeroIcons.chevronEnd,
          size: AppSize.s20,
          color: AppColors.primaryText,
        ),
      ],
    );
  }
}
