import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../cubit/address_edit_cubit.dart';
import 'address_choice_chip.dart';
import 'address_form_labels.dart';
import 'boxed_field.dart';

/// Drop-spot chips + the REQUIRED alt-location input shown when leave-at-spot.
class DropSpotPicker extends StatefulWidget {
  const DropSpotPicker({
    super.key,
    required this.altError,
    required this.onClearAltError,
  });

  final bool altError;
  final VoidCallback onClearAltError;

  @override
  State<DropSpotPicker> createState() => _DropSpotPickerState();
}

class _DropSpotPickerState extends State<DropSpotPicker> {
  late final TextEditingController _alt;

  @override
  void initState() {
    super.initState();
    _alt = TextEditingController(
      text: context.read<AddressEditCubit>().state.altLocation,
    );
  }

  @override
  void dispose() {
    _alt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AddressEditCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'dropoff.cant_reach'.tr(),
          style: AppTextStyles.captionLarge.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        BlocSelector<AddressEditCubit, AddressEditState, String>(
          selector: (s) => s.dropSpot,
          builder: (context, active) => Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (final spot in dropSpots)
                AddressChoiceChip(
                  label: dropSpotLabel(spot),
                  selected: spot == active,
                  onTap: () => cubit.setDropSpot(spot),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s10),
        BoxedField(
          controller: _alt,
          hint: 'dropoff.designated'.tr(),
          errorText: widget.altError ? 'addr.field_required'.tr() : null,
          onChanged: (v) {
            cubit.setAltLocation(v);
            widget.onClearAltError();
          },
        ),
      ],
    );
  }
}
