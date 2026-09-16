import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../cubit/address_edit_cubit.dart';

/// Delivery address — resolved area + "Edit" → SELECT.
class DeliveryAddressCard extends StatelessWidget {
  const DeliveryAddressCard({super.key, required this.onEdit});
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s14,
      ),
      child: Row(
        children: [
          const Icon(
            KeetaIcons.location,
            size: 20,
            color: AppColors.primaryText,
          ),
          const SizedBox(width: AppSpacing.s10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'addr.delivery_address'.tr(),
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                BlocSelector<AddressEditCubit, AddressEditState, String>(
                  selector: (s) =>
                      s.briefLine.isNotEmpty ? s.briefLine : s.area,
                  builder: (context, line) => Text(
                    line.trim().isEmpty ? 'addr.pinned_location'.tr() : line,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headingSmall.copyWith(
                      fontWeight: AppTextStyles.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          OutlinedButton(
            onPressed: onEdit,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryText,
              side: const BorderSide(color: AppColors.divider),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s14,
                vertical: AppSpacing.s6,
              ),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            child: Text(
              'common.edit'.tr(),
              style: AppTextStyles.captionLarge.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
