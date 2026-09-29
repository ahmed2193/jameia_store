import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/widgets/count_badge.dart';

/// The cart count pill of the tab bar and the basket switch ([CountBadge]):
/// static when the shell opens; an add from anywhere in the app bumps it and
/// rolls its number when the flying product lands; 100 and up read `99+`;
/// at zero it fades away. [margin] is the gap to its label, kept only while
/// it shows.
class ShellNavBadge extends StatelessWidget {
  const ShellNavBadge({
    super.key,
    required this.count,
    this.margin = EdgeInsetsDirectional.zero,
  });

  final int count;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return CountBadge(
      count: count,
      color: AppColors.finalPrice,
      borderColor: AppColors.white,
      margin: margin,
      landsWithFlight: true,
    );
  }
}
