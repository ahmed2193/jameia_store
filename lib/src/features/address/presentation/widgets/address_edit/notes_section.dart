import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../domain/entities/address_field.dart';
import 'address_text_field.dart';
import 'section_header.dart';

/// Note for the courier (directions, gate code …) + the grey helper line.
class NotesSection extends StatelessWidget {
  const NotesSection({super.key});

  static const int _lines = 3;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      margin: const EdgeInsets.only(top: AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'addr.field.note'.tr()),
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.s12,
              end: AppSpacing.s12,
              bottom: AppSpacing.s14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AddressTextField(
                  field: AddressField.notes,
                  maxLines: _lines,
                ),
                const SizedBox(height: AppSpacing.s6),
                Text(
                  'addr.note_no_order_requests'.tr(),
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.tertiaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
