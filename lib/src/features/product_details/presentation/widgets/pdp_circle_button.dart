import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/responsive/app_size.dart';

/// Chrome button of the product page: a soft disc that reads on the photo and
/// on the bar the photo collapses into. Fixed size on purpose — the app bar
/// hands its actions the whole toolbar height.
class PdpCircleButton extends StatelessWidget {
  const PdpCircleButton({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticsLabel,
  });

  static const double size = AppSize.s36;
  static const double glyphSize = AppSize.s20;

  final Widget child;
  final VoidCallback onTap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.smallBackground,
            shape: BoxShape.circle,
          ),
          child: child,
        ),
      ),
    );
  }
}
