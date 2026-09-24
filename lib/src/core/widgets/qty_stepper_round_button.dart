import 'package:flutter/material.dart';

import '../motion/haptics.dart';
import '../motion/motion_widgets.dart';

/// Round "+" / "−" button of [QtyStepper] with press-scale + selection haptic.
class QtyStepperRoundButton extends StatelessWidget {
  const QtyStepperRoundButton({
    super.key,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.size,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final Color bg;
  final Color fg;
  final double size;
  final String label;
  final VoidCallback onTap;

  /// A disabled button is dimmed and takes no tap, so a control that would
  /// do nothing (a line already at its maximum) does not look live.
  final bool enabled;

  static const double _disabledOpacity = 0.4;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: bg,
      shape: const CircleBorder(),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, size: size * 0.62, color: fg),
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: enabled
          ? PressScale(
              onTap: onTap,
              haptic: HapticKind.selection,
              child: button,
            )
          : Opacity(opacity: _disabledOpacity, child: button),
    );
  }
}
