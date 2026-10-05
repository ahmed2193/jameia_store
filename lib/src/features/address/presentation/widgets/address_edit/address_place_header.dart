import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../../../core/widgets/hero_text_link.dart';
import '../../../domain/entities/building_type.dart';
import '../../cubit/address_edit_cubit.dart';
import '../../cubit/address_edit_state.dart';
import 'building_type_labels.dart';
import 'pinned_place_text.dart';

/// The top of the address form, Glovo style: the building type's glyph on
/// its own, the address in two lines as the form now reads, and "Change"
/// to pick another type. Rebuilds only when one of those changes.
class AddressPlaceHeader extends StatelessWidget {
  const AddressPlaceHeader({super.key, required this.onChangeType});

  final VoidCallback onChangeType;

  static const double _glyph = AppSize.s28;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return BlocSelector<
      AddressEditCubit,
      AddressEditState,
      ({BuildingType type, String title, String subtitle})
    >(
      selector: (state) => (
        type: state.draft.buildingType,
        title: draftTitle(state.draft, rtl: rtl),
        subtitle: draftSubtitle(state.draft, rtl: rtl),
      ),
      builder: (context, header) => Row(
        children: [
          HeroIcon(buildingTypeIcon(header.type), size: _glyph),
          const SizedBox(width: AppSpacing.s14),
          Expanded(
            child: Semantics(
              container: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    header.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headingLarge,
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    '${buildingTypeName(header.type)}'
                    '${'addr.line.separator'.tr()}${header.subtitle}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          HeroTextLink(
            label: 'addr.type.change'.tr(),
            navigates: false,
            onTap: onChangeType,
          ),
        ],
      ),
    );
  }
}
