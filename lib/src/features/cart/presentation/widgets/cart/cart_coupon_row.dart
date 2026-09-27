import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/cart_coupon_entity.dart';
import '../../../../../core/motion/change_bump.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_list_row.dart';
import '../../../../../core/widgets/hero_sheet_header.dart';
import '../../../domain/entities/cart_snapshot.dart';
import '../../cubit/cart_cubit.dart';
import 'cart_coupon_sheet.dart';
import 'cart_discount_amount.dart';

/// The applied coupon (code + discount, removable) or the entry to add one.
/// The ticket fills in deep green with a bump when a coupon lands or leaves.
class CartCouponRow extends StatefulWidget {
  const CartCouponRow({super.key});

  @override
  State<CartCouponRow> createState() => _CartCouponRowState();
}

class _CartCouponRowState extends State<CartCouponRow> {
  // The row is read as one element without a coupon and as separate parts
  // with one (its ✕ must stay reachable), so the list row rebuilds its
  // subtree when a coupon lands; this key carries the ticket's bump across.
  final GlobalKey _ticket = GlobalKey(debugLabel: 'coupon ticket');

  void _open(BuildContext context) => showHeroBottomSheet<void>(
    context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: HeroSheetHeader.shape,
    builder: (_) => const CartCouponSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final coupon = context.select<CartCubit, CartCouponEntity?>(
      (cubit) => cubit.state.cart.coupon,
    );
    final busy = context.select<CartCubit, bool>(
      (cubit) => cubit.state.busyAction == CartAction.coupon,
    );
    return HeroListRow(
      // No coupon glyph in wm_c_iconfont — its 0xe014 is the WORD 賞 — so this
      // is the same Material ticket the Mine menu and the coupon notification
      // already use.
      leading: ChangeBump(
        key: _ticket,
        value: coupon?.code,
        child: Icon(
          coupon == null
              ? Icons.confirmation_number_outlined
              : Icons.confirmation_number_rounded,
          size: AppSize.s24,
          color: coupon == null ? AppColors.primaryText : AppColors.brandDeep,
        ),
      ),
      title: coupon == null
          ? 'cart.coupon_add'.tr()
          : 'cart.coupon_applied'.tr(namedArgs: {'code': coupon.code}),
      subtitleWidget: coupon == null
          ? null
          : CartDiscountAmount(
              kd: coupon.discountKd,
              style: AppTextStyles.meta,
            ),
      trailing: coupon == null
          ? null
          : IconButton(
              tooltip: 'cart.coupon_remove'.tr(),
              onPressed: busy
                  ? null
                  : () {
                      Haptics.selection();
                      context.read<CartCubit>().removeCoupon();
                    },
              icon: const Icon(Icons.close_rounded, size: AppSize.s20),
            ),
      showChevron: coupon == null,
      mergeSemantics: coupon == null,
      onTap: coupon == null && !busy ? () => _open(context) : null,
    );
  }
}
