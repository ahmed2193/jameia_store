import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../domain/entities/address_field.dart';
import 'address_text_field.dart';
import 'section_header.dart';

/// Address details — the location fields the API stores: area, block,
/// street, building, floor and apartment.
class AddressDetailsSection extends StatelessWidget {
  const AddressDetailsSection({super.key});

  static const List<AddressField> _fields = [
    AddressField.city,
    AddressField.block,
    AddressField.street,
    AddressField.building,
    AddressField.floor,
    AddressField.apartment,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      margin: const EdgeInsets.only(top: AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'addr.address_details'.tr(), required: true),
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.s12,
              end: AppSpacing.s12,
              bottom: AppSpacing.s4,
            ),
            child: Column(
              children: [
                for (final field in _fields)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: AppSpacing.s10,
                    ),
                    child: AddressTextField(field: field),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
