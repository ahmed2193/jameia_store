import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../domain/entities/place_suggestion.dart';
import 'place_suggestion_row.dart';
import 'search_row_divider.dart';
import 'use_my_location_row.dart';

/// The address search before anything is typed: "Use my current location",
/// a line on how to search, and the districts Hero delivers to, A to Z
/// (jm3eia_mobile's "choose from the list": the way back for a pin outside
/// Kuwait), each over its governorate with how far it is, hairlines
/// between them. A tapped district goes the way of any answer.
class AddressSearchIdle extends StatelessWidget {
  const AddressSearchIdle({
    super.key,
    required this.areas,
    required this.lookingUpId,
    required this.onPick,
    required this.onMyLocation,
  });

  final List<PlaceSuggestion> areas;
  final String? lookingUpId;
  final ValueChanged<PlaceSuggestion> onPick;
  final VoidCallback onMyLocation;

  /// The rows before the districts: my location, the tip, the heading.
  static const int _lead = 3;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s24),
      itemCount: areas.isEmpty ? _lead - 1 : _lead + areas.length,
      itemBuilder: (context, index) => switch (index) {
        0 => UseMyLocationRow(onTap: onMyLocation),
        1 => Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.gutter,
            AppSpacing.s12,
            AppSpacing.gutter,
            AppSpacing.s16,
          ),
          child: Text('addr.search.tip'.tr(), style: AppTextStyles.meta),
        ),
        2 => Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.gutter,
            AppSpacing.s8,
            AppSpacing.gutter,
            AppSpacing.s4,
          ),
          child: Semantics(
            header: true,
            child: Text(
              'addr.search.areas_title'.tr(),
              style: AppTextStyles.groupTitle,
            ),
          ),
        ),
        _ => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index > _lead) const SearchRowDivider(),
            PlaceSuggestionRow(
              suggestion: areas[index - _lead],
              lookingUp: lookingUpId == areas[index - _lead].id,
              onTap: () => onPick(areas[index - _lead]),
            ),
          ],
        ),
      },
    );
  }
}
