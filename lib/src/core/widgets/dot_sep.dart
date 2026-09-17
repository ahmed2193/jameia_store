import 'package:flutter/material.dart';

import '../responsive/app_size.dart';
import '../../config/theme/app_colors.dart';

/// 2dp bullet/dot separator (`#C2C2C2`, atom `c82c4a`).
class DotSep extends StatelessWidget {
  const DotSep({super.key, this.margin = 6});
  final double margin;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsDirectional.symmetric(horizontal: margin),
    child: Container(
      width: AppSize.s2,
      height: AppSize.s2,
      decoration: const BoxDecoration(
        color: AppColors.dotSep,
        shape: BoxShape.circle,
      ),
    ),
  );
}
