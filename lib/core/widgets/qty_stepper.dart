import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Add / quantity stepper. When [qty] is 0 it collapses to a single round "+"
/// add button (KeeTa product-card behavior); above 0 it shows − qty +.
class QtyStepper extends StatelessWidget {
  const QtyStepper({
    super.key,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
    this.size = 28,
  });

  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (qty <= 0) {
      return _RoundBtn(
        icon: Icons.add_rounded,
        bg: AppColors.primary,
        fg: AppColors.brandForeground,
        size: size,
        onTap: onAdd,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundBtn(
          icon: Icons.remove_rounded,
          bg: AppColors.smallBackground,
          fg: AppColors.primaryText,
          size: size,
          onTap: onRemove,
        ),
        Container(
          constraints: BoxConstraints(minWidth: size),
          alignment: Alignment.center,
          child: Text('$qty',
              style: AppTextStyles.headingSmall
                  .copyWith(fontWeight: AppTextStyles.bold)),
        ),
        _RoundBtn(
          icon: Icons.add_rounded,
          bg: AppColors.primary,
          fg: AppColors.brandForeground,
          size: size,
          onTap: onAdd,
        ),
      ],
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final Color bg;
  final Color fg;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
            width: size, height: size, child: Icon(icon, size: size * 0.62, color: fg)),
      ),
    );
  }
}
