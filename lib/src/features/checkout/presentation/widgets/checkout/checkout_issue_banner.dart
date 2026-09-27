import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../domain/entities/checkout_thumbs.dart';

/// "2 items unavailable · Review ›" over the order-summary strip while the
/// server flags lines that block the order (out of stock, unavailable); a
/// tap opens the items sheet ([onReview]), where each one can be removed.
/// It folds in and out ([CollapseReveal]); a quantity the server only cut
/// back is not "unavailable", so it shows on its row, not here.
class CheckoutIssueBanner extends StatelessWidget {
  const CheckoutIssueBanner({super.key, required this.onReview});

  final VoidCallback onReview;

  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppSize.r8),
  );

  @override
  Widget build(BuildContext context) {
    final count = context.select<CartCubit, int>(
      (cubit) => CheckoutThumbs.blockingOf(cubit.state.cart),
    );
    return CollapseReveal(
      visible: count > 0,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s12),
        child: MergeSemantics(
          child: Semantics(
            button: true,
            child: Material(
              color: AppColors.errorBg,
              borderRadius: _radius,
              child: InkWell(
                onTap: onReview,
                borderRadius: _radius,
                child: Container(
                  // A full tap target even for a one-line message.
                  constraints: const BoxConstraints(minHeight: AppSize.s44),
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.s8,
                    AppSpacing.s8,
                    AppSpacing.s4,
                    AppSpacing.s8,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: AppSize.s16,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: AppSpacing.s6),
                      Expanded(
                        // One run, so "Review" wraps with the message on a
                        // narrow phone instead of pushing it off.
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'checkout.issues_banner'.plural(count),
                              ),
                              const WidgetSpan(
                                child: SizedBox(width: AppSpacing.s8),
                              ),
                              TextSpan(
                                text: 'checkout.issues_review'.tr(),
                                style: const TextStyle(
                                  fontWeight: AppTextStyles.bold,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.errorDeep,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: AppSize.s16,
                        color: AppColors.errorDeep,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
