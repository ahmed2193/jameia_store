import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/motion/change_bump.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';

/// A 48 dp icon action under a reply. A toggle (thumbs) shows its state by
/// shape — filled vs outlined — not only colour (docs/motion §9.6 §2.10):
/// the outline and the fill cross-fade over `fast`, and only a RATING (off
/// → on) bumps the icon ([ChangeBump]); un-rating, or the other thumb
/// letting go, just fades. One selection tick per tap, whatever it does.
class AssistantThumbButton extends StatefulWidget {
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
  State<AssistantThumbButton> createState() => _AssistantThumbButtonState();
}

class _AssistantThumbButtonState extends State<AssistantThumbButton> {
  /// Bumps once per rating (never on un-rate or on the first build).
  int _ratings = 0;

  @override
  void didUpdateWidget(AssistantThumbButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) _ratings++;
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return Semantics(
      button: true,
      toggled: widget.toggles ? selected : null,
      label: widget.label,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: Tooltip(
        message: widget.label,
        child: PressScale(
          onTap: widget.onTap,
          pressedScale: AppMotion.pressedScaleSmall,
          haptic: widget.toggles ? HapticKind.selection : HapticKind.tap,
          child: SizedBox.square(
            dimension: SuiSize.minTouchTarget,
            child: Center(
              child: ChangeBump(
                value: _ratings,
                child: AnimatedSwitcher(
                  duration: MotionGuard.duration(context, AppMotion.fast),
                  child: Icon(
                    selected ? widget.selectedIcon : widget.icon,
                    key: ValueKey<bool>(selected),
                    size: AppSize.s18,
                    color: selected ? AppColors.primaryDark : widget.color,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
