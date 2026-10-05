import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/widgets/round_back_button.dart';
import 'address_search_field.dart';

/// The top of the address search: back to the map, and the search pill.
class AddressSearchHeader extends StatelessWidget {
  const AddressSearchHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s12,
        AppSpacing.s8,
        AppSpacing.gutter,
        AppSpacing.s8,
      ),
      child: Row(
        children: [
          const RoundBackButton(),
          const SizedBox(width: AppSpacing.s8),
          const Expanded(child: AddressSearchField()),
        ],
      ),
    );
  }
}
