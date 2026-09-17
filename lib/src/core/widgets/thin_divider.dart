import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../responsive/app_size.dart';

/// Thin divider matching the token divider color.
class ThinDivider extends StatelessWidget {
  const ThinDivider({super.key, this.indent = 0});
  final double indent;
  @override
  Widget build(BuildContext context) => Divider(
    height: AppSize.s1,
    thickness: AppSize.s1,
    color: AppColors.divider,
    indent: indent,
    endIndent: indent,
  );
}
