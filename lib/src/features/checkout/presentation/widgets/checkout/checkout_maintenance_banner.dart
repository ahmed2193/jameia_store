import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../cubit/checkout_cubit.dart';

/// "The store is closed for maintenance" at the top of the page, only while
/// the store says so (`GET /v1/init` → `store.maintenanceMode`): the
/// server's own text, or the app's line when it sent none. Opens and closes
/// in place; the place button stays blocked meanwhile (its reason is
/// `maintenance`).
class CheckoutMaintenanceBanner extends StatelessWidget {
  const CheckoutMaintenanceBanner({super.key});

  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppRadius.card),
  );

  @override
  Widget build(BuildContext context) {
    final (
      maintenance,
      message,
    ) = context.select<CheckoutCubit, (bool, String)>(
      (cubit) =>
          (cubit.state.rules.maintenance, cubit.state.rules.maintenanceMessage),
    );
    return CollapseReveal(
      visible: maintenance,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.s12,
          AppSpacing.s12,
          AppSpacing.s12,
          0,
        ),
        child: Semantics(
          container: true,
          liveRegion: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.warnBg,
              borderRadius: _radius,
              border: Border.all(color: AppColors.warn, width: AppSize.s1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: AppSize.s20,
                    color: AppColors.warn,
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: Text(
                      message.isEmpty
                          ? 'checkout.blocked_maintenance'.tr()
                          : message,
                      style: AppTextStyles.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
