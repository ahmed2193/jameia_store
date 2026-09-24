import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../cubit/address_edit_cubit.dart';
import '../../cubit/address_edit_state.dart';

/// "Set as default address" (`isDefault`). Pre-checked for a customer's first
/// address.
class DefaultAddressSwitch extends StatelessWidget {
  const DefaultAddressSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    // A Material (not a coloured Container) under the tile, so its ink and
    // background paint where they are visible.
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s8),
      child: Material(
        color: AppColors.white,
        child: BlocSelector<AddressEditCubit, AddressEditState, bool>(
          selector: (state) => state.draft.isDefault,
          builder: (context, isDefault) => SwitchListTile.adaptive(
            value: isDefault,
            onChanged: context.read<AddressEditCubit>().defaultChanged,
            activeTrackColor: AppColors.primary,
            contentPadding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s12,
            ),
            title: Text(
              'addr.set_default'.tr(),
              style: AppTextStyles.headingSmall.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
