import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_icon.dart';

/// One − / + of the buy bar's stepper pill: a 40 dp touch target that sinks
/// under the finger with a selection tick (the − side: a remove's tap). When it cannot move any further
/// it is dimmed and fully inert — no tap, no haptic, no press.
class PdpStepButton extends StatelessWidget {
  const PdpStepButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = true,
    this.color = AppColors.primaryText,
    this.disabledColor = AppColors.disabledText,
    this.removes = false,
  });

  final IconData icon;

  /// Accessibility label.
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color color;
  final Color disabledColor;

  /// The − side: a remove's tap instead of an add's click (§9.5).
  final bool removes;

  static const double size = AppSize.s40;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: active,
      label: label,
      excludeSemantics: true,
      onTap: active ? onTap : null,
      child: PressScale(
        onTap: active ? onTap : null,
        enabled: active,
        haptic: removes ? HapticKind.tap : HapticKind.selection,
        child: SizedBox.square(
          dimension: size,
          child: HeroIcon(
            icon,
            size: AppSize.s22,
            color: active ? color : disabledColor,
          ),
        ),
      ),
    );
  }
}
