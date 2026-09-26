import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/widgets/thin_divider.dart';

/// A cart row with the hairline above it (none on the first row). The
/// hairline travels with its row, so it opens and folds with it — an
/// animated list has no separators of its own.
class CartLineSeparated extends StatelessWidget {
  const CartLineSeparated({
    super.key,
    required this.first,
    required this.child,
  });

  final bool first;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!first) const ThinDivider(indent: AppSpacing.gutter),
        child,
      ],
    );
  }
}
