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
  });

  final IconData icon;
  final Color bg;
  final Color fg;
  final double size;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: PressScale(
        onTap: onTap,
        haptic: HapticKind.selection,
        child: Material(
          color: bg,
          shape: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: size * 0.62, color: fg),
          ),
        ),
      ),
    );
  }
}
