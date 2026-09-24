import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/jameia_assets.dart';
import '../../../../../core/domain/entities/address_label.dart';
import '../../cubit/address_edit_cubit.dart';
import '../../cubit/address_edit_state.dart';
import 'label_chip.dart';
import 'section_header.dart';

/// Tag — Home | Work | Gathering | Other (sent as the address `label`).
class TagSection extends StatelessWidget {
  const TagSection({super.key});

  // [textKey] is resolved with .tr() at build time (a const list can't).
  static const List<({AddressLabel label, String textKey, String icon})> _tags =
      [
        (
          label: AddressLabel.home,
          textKey: 'addr.tag.home',
          icon: JameiaAssets.labelHome,
        ),
        (
          label: AddressLabel.work,
          textKey: 'addr.tag.work',
          icon: JameiaAssets.labelOffice,
        ),
        (
          label: AddressLabel.gathering,
          textKey: 'addr.tag.gathering',
          icon: JameiaAssets.labelGathering,
        ),
        (
          label: AddressLabel.other,
          textKey: 'addr.tag.other',
          icon: JameiaAssets.labelOther,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      margin: const EdgeInsets.only(top: AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'addr.tag.label'.tr()),
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.s12,
              end: AppSpacing.s12,
              bottom: AppSpacing.s14,
            ),
            child:
                BlocSelector<AddressEditCubit, AddressEditState, AddressLabel>(
                  selector: (state) => state.draft.label,
                  builder: (context, active) {
                    final cubit = context.read<AddressEditCubit>();
                    return Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        for (final tag in _tags)
                          LabelChip(
                            label: tag.textKey.tr(),
                            iconAsset: tag.icon,
                            selected: tag.label == active,
                            onTap: () => cubit.labelChanged(tag.label),
                          ),
                      ],
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
