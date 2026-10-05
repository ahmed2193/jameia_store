import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/address_label.dart';
import '../../cubit/address_edit_cubit.dart';
import '../../cubit/address_edit_state.dart';
import 'label_chip.dart';
import 'section_header.dart';

/// "Add a label" — Home | Work | Gathering | Other (sent as the address
/// `label`), Glovo style: word chips in one grey track. Rebuilds only when
/// the pick changes.
class TagSection extends StatelessWidget {
  const TagSection({super.key});

  // [textKey] is resolved with .tr() at build time (a const list can't).
  static const List<({AddressLabel label, String textKey})> _tags = [
    (label: AddressLabel.home, textKey: 'addr.tag.home'),
    (label: AddressLabel.work, textKey: 'addr.tag.work'),
    (label: AddressLabel.gathering, textKey: 'addr.tag.gathering'),
    (label: AddressLabel.other, textKey: 'addr.tag.other'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'addr.details.label_title'.tr(),
          hint: 'addr.details.label_hint'.tr(),
        ),
        BlocSelector<AddressEditCubit, AddressEditState, AddressLabel>(
          selector: (state) => state.draft.label,
          builder: (context, active) {
            final cubit = context.read<AddressEditCubit>();
            // The track hugs its chips (a single run of a Wrap).
            return Align(
              alignment: AlignmentDirectional.centerStart,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.smallBackground,
                  borderRadius: BorderRadius.circular(AppRadius.r1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s4),
                  child: Wrap(
                    spacing: AppSpacing.s4,
                    runSpacing: AppSpacing.s4,
                    children: [
                      for (final tag in _tags)
                        LabelChip(
                          label: tag.textKey.tr(),
                          selected: tag.label == active,
                          onTap: () => cubit.labelChanged(tag.label),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
