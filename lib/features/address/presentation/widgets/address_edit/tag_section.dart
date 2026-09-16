import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design/keeta_assets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../cubit/address_edit_cubit.dart';
import 'label_chip.dart';
import 'section_header.dart';

/// Tag / label — Home | Work | Hangout | Other (labelType, RE §3.4).
class TagSection extends StatelessWidget {
  const TagSection({super.key});

  // The four user-facing label tags + their KeeTa glyphs. [labelKey] is the
  // i18n key resolved with .tr() at build time (a const list can't call .tr()).
  static const List<({LabelType type, String labelKey, String icon})> _tags = [
    (
      type: LabelType.home,
      labelKey: 'addr.tag.home',
      icon: KeetaAssets.labelHome,
    ),
    (
      type: LabelType.work,
      labelKey: 'addr.tag.work',
      icon: KeetaAssets.labelOffice,
    ),
    (
      type: LabelType.hangout,
      labelKey: 'addr.tag.gathering',
      icon: KeetaAssets.labelGathering,
    ),
    (
      type: LabelType.other,
      labelKey: 'addr.tag.other',
      icon: KeetaAssets.labelOther,
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
            child: BlocSelector<AddressEditCubit, AddressEditState, LabelType>(
              selector: (s) => s.label,
              builder: (context, active) {
                final cubit = context.read<AddressEditCubit>();
                return Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s8,
                  children: [
                    for (final t in _tags)
                      LabelChip(
                        label: t.labelKey.tr(),
                        iconAsset: t.icon,
                        selected: t.type == active,
                        onTap: () => cubit.setLabel(t.type),
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
