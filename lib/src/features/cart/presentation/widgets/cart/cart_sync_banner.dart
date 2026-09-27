import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_surface_card.dart';
import '../../../../../core/widgets/hero_text_link.dart';
import '../../cubit/cart_cubit.dart';

/// Shown while taps could not reach the server (offline): they are kept and
/// retried; the link retries now. Opens and folds with its height.
class CartSyncBanner extends StatelessWidget {
  const CartSyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final unsynced = context.select<CartCubit, bool>(
      (cubit) => cubit.state.isUnsynced,
    );
    return CollapseReveal(
      visible: unsynced,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.gutter,
          AppSpacing.s8,
          AppSpacing.gutter,
          0,
        ),
        child: HeroSurfaceCard(
          tone: HeroSurfaceTone.muted,
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.s16,
            AppSpacing.s8,
            AppSpacing.s8,
            AppSpacing.s8,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: AppSize.s20,
                color: AppColors.warn,
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Text(
                  'cart.unsynced'.tr(),
                  style: AppTextStyles.meta.copyWith(
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              HeroTextLink(
                label: 'cart.retry'.tr(),
                navigates: false,
                onTap: () => context.read<CartCubit>().prepareCheckout(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
