import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../domain/entities/address_field.dart';
import '../../../domain/entities/building_type.dart';
import '../../cubit/address_edit_cubit.dart';
import '../../cubit/address_edit_state.dart';
import 'address_form_labels.dart';
import 'address_text_field.dart';
import 'section_header.dart';

/// The address itself, shaped by the building type: area and block side by
/// side, the street, the building (a house's number), then — for anything
/// but a house — the floor beside the flat / office number. Rebuilds only
/// when the building type changes.
class AddressDetailsSection extends StatelessWidget {
  const AddressDetailsSection({super.key});

  static const double _gap = AppSpacing.s16;
  static const double _sideGap = AppSpacing.s12;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AddressEditCubit, AddressEditState, BuildingType>(
      selector: (state) => state.draft.buildingType,
      builder: (context, type) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: 'addr.address_details'.tr()),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AddressTextField(
                  field: AddressField.city,
                  label: addressFieldLabel(AddressField.city, type),
                ),
              ),
              const SizedBox(width: _sideGap),
              Expanded(
                child: AddressTextField(
                  field: AddressField.block,
                  label: addressFieldLabel(AddressField.block, type),
                ),
              ),
            ],
          ),
          const SizedBox(height: _gap),
          AddressTextField(
            field: AddressField.street,
            label: addressFieldLabel(AddressField.street, type),
          ),
          const SizedBox(height: _gap),
          AddressTextField(
            field: AddressField.building,
            label: addressFieldLabel(AddressField.building, type),
          ),
          if (type.hasUnits) ...[
            const SizedBox(height: _gap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AddressTextField(
                    field: AddressField.floor,
                    label: addressFieldLabel(AddressField.floor, type),
                  ),
                ),
                const SizedBox(width: _sideGap),
                Expanded(
                  child: AddressTextField(
                    field: AddressField.apartment,
                    label: addressFieldLabel(AddressField.apartment, type),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
