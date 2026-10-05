import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../domain/entities/address_field.dart';
import '../../../domain/entities/building_type.dart';
import '../../cubit/address_edit_cubit.dart';
import '../../cubit/address_edit_state.dart';
import 'address_form_labels.dart';
import 'address_text_field.dart';

/// Directions for the courier (a gate code, a landmark, which door) and
/// the grey line that keeps order requests out of them.
class NotesSection extends StatelessWidget {
  const NotesSection({super.key});

  static const int _lines = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlocSelector<AddressEditCubit, AddressEditState, BuildingType>(
          selector: (state) => state.draft.buildingType,
          builder: (context, type) => AddressTextField(
            field: AddressField.notes,
            label: addressFieldLabel(AddressField.notes, type),
            hint: 'addr.details.notes_hint'.tr(),
            lines: _lines,
          ),
        ),
        const SizedBox(height: AppSpacing.s6),
        Text(
          'addr.note_no_order_requests'.tr(),
          style: AppTextStyles.captionLarge.copyWith(
            color: AppColors.tertiaryText,
          ),
        ),
      ],
    );
  }
}
