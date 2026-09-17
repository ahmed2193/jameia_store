import 'package:flutter/material.dart';

import '../responsive/app_size.dart';
import '../../config/theme/app_colors.dart';

/// 1×15dp vertical bar separator (`#A5A5A5`, atom `je25a6`).
class VBarSep extends StatelessWidget {
  const VBarSep({super.key, this.height = 12, this.margin = 8});
  final double height;
  final double margin;
  @override
  Widget build(BuildContext context) => Container(
    margin: EdgeInsetsDirectional.symmetric(horizontal: margin),
    width: AppSize.s1,
    height: height,
    color: AppColors.vBarSep,
  );
}
