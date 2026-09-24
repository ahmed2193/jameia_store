import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../cubit/address_edit_cubit.dart';
import '../../cubit/address_edit_state.dart';

/// Delivery address — the pinned area + "Edit" → back to the map.
class DeliveryAddressCard extends StatelessWidget {
  const DeliveryAddressCard({super.key, required this.onEdit});

  final VoidCallback onEdit;

  static const Size _editButtonMinSize = Size(0, AppSize.s36);
  static const int _maxLines = 2;

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
            JameiaIcons.location,
            size: AppSize.s20,
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
                  selector: (state) => state.draft.city.trim(),
                  builder: (context, city) => Text(
                    city.isEmpty ? 'addr.pinned_location'.tr() : city,
                    maxLines: _maxLines,
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
              minimumSize: _editButtonMinSize,
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
