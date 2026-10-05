import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/entrance_cascade_item.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/arc_top_border.dart';
import '../../../../../core/widgets/hero_sheet_header.dart';
import '../../../domain/entities/building_type.dart';
import 'building_type_tile.dart';

/// Asks what kind of place the pin is ([BuildingTypeSheet]); `null` when
/// the sheet was dismissed. [overMap]: the map picker's panel, Glovo style —
/// an arched top over the map, nothing dimmed, no close button (a tap on
/// the map or back closes it).
Future<BuildingType?> showBuildingTypeSheet(
  BuildContext context, {
  BuildingType? selected,
  bool overMap = false,
}) => showHeroBottomSheet<BuildingType>(
  context,
  barrierColor: overMap ? AppColors.scrimTransparent : null,
  shape: overMap ? const ArcTopBorder() : null,
  elevation: overMap ? _panelElevation : null,
  builder: (_) => BuildingTypeSheet(selected: selected, closable: !overMap),
);

/// The panel's shadow on the map it rises over.
const double _panelElevation = AppSize.s8;

/// "Choose your building type" — the panel over the map once the pin is
/// confirmed: four outlined tiles, two by two; a tap answers with that type
/// (the form then asks only what that building has). Dismissed, the
/// customer stays on the map.
class BuildingTypeSheet extends StatelessWidget {
  const BuildingTypeSheet({super.key, this.selected, this.closable = true});

  /// The type already chosen (a change from the address form).
  final BuildingType? selected;

  /// Shows the header's close button.
  final bool closable;

  static const List<List<BuildingType>> _rows = [
    [BuildingType.house, BuildingType.apartment],
    [BuildingType.office, BuildingType.other],
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HeroSheetHeader(
              title: 'addr.type.title'.tr(),
              subtitle: 'addr.type.subtitle'.tr(),
              showClose: closable,
            ),
            const SizedBox(height: AppSpacing.s8),
            for (final (index, row) in _rows.indexed)
              EntranceCascadeItem.single(
                index: index + 1,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.gutter,
                    0,
                    AppSpacing.gutter,
                    AppSpacing.s12,
                  ),
                  child: Row(
                    children: [
                      for (final (column, type) in row.indexed) ...[
                        if (column > 0) const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: BuildingTypeTile(
                            type: type,
                            selected: type == selected,
                            onTap: () => context.pop(type),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
