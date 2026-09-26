import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';

/// A 48 dp icon action under a reply. A toggle (thumbs) shows its state by
/// shape — filled vs outlined — not only colour, and pops when selected.
class AssistantThumbButton extends StatelessWidget {
  const AssistantThumbButton({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.toggles = true,
    this.color = AppColors.labelGrey,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// A two-state button (announced as toggled) rather than a plain action.
  final bool toggles;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: toggles ? selected : null,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: label,
        child: PressScale(
          onTap: onTap,
          haptic: toggles ? HapticKind.selection : HapticKind.tap,
          child: SizedBox.square(
            dimension: SuiSize.minTouchTarget,
            child: Center(
              child: PopScale(
                popKey: selected,
                child: Icon(
                  selected ? selectedIcon : icon,
                  size: AppSize.s18,
                  color: selected ? AppColors.primaryDark : color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
