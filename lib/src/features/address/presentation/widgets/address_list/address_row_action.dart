import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/press_scale.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// Compact 32dp icon button (RE §5 tap target) for a row action. It presses
/// itself (the small press depth), so the row around it stays still.
class AddressRowAction extends StatelessWidget {
  const AddressRowAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      pressedScale: AppMotion.pressedScaleSmall,
      child: SizedBox(
        width: AppSize.s32,
        height: AppSize.s32,
        child: IconButton(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          tooltip: tooltip,
          icon: HeroIcon(
            icon,
            size: AppSize.s18,
            color: AppColors.secondaryText,
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
