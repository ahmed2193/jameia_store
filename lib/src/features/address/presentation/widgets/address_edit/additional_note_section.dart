import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../cubit/address_edit_cubit.dart';
import 'boxed_field.dart';
import 'section_header.dart';

/// Additional note — multi-line field + grey helper line.
class AdditionalNoteSection extends StatefulWidget {
  const AdditionalNoteSection({super.key});

  @override
  State<AdditionalNoteSection> createState() => _AdditionalNoteSectionState();
}

class _AdditionalNoteSectionState extends State<AdditionalNoteSection> {
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController(
      text: context.read<AddressEditCubit>().state.note,
    );
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AddressEditCubit>();
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
                BoxedField(
                  controller: _note,
                  hint: 'addr.field.note'.tr(),
                  maxLines: 3,
                  onChanged: (v) => cubit.setField(AddrField.note, v),
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
