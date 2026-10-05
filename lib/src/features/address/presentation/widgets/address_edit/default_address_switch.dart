import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../cubit/address_edit_cubit.dart';
import '../../cubit/address_edit_state.dart';

/// "Set as default address" (`isDefault`). Pre-checked for a customer's first
/// address.
class DefaultAddressSwitch extends StatelessWidget {
  const DefaultAddressSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    // A transparent Material under the tile, so its ink paints where it is
    // visible.
    return Material(
      type: MaterialType.transparency,
      child: BlocSelector<AddressEditCubit, AddressEditState, bool>(
        selector: (state) => state.draft.isDefault,
        builder: (context, isDefault) => SwitchListTile.adaptive(
          value: isDefault,
          onChanged: context.read<AddressEditCubit>().defaultChanged,
          activeTrackColor: AppColors.primary,
          contentPadding: EdgeInsetsDirectional.zero,
          title: Text(
            'addr.set_default'.tr(),
            style: AppTextStyles.itemTitleStrong,
          ),
        ),
      ),
    );
  }
}
