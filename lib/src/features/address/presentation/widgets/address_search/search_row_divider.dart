import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import 'suggestion_leading.dart';

/// The hairline between two rows of the address search, Google Maps style:
/// from where the names start to the end of the row.
class SearchRowDivider extends StatelessWidget {
  const SearchRowDivider({super.key});

  static const double _indent =
      AppSpacing.gutter + SuggestionLeading.width + AppSpacing.s12;

  @override
  Widget build(BuildContext context) => const Divider(
    height: AppSize.s1,
    thickness: AppSize.s1,
    color: AppColors.divider,
    indent: _indent,
  );
}
