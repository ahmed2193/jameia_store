import 'package:flutter/material.dart';

import '../motion/haptics.dart';
import '../motion/motion_widgets.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import 'branded_loader.dart';

export 'app_outline_button.dart';

/// Jameia primary CTA — brand-yellow pill with black foreground (the signature
/// "Place order" / "Add" button look).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expanded = true,
    this.enabled = true,
    this.loading = false,
    this.height = 48,
    this.color,
    this.foreground,
    this.trailing,
    this.radius,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expanded;
  final bool enabled;
  final bool loading;
  final double height;
  final Color? color;
  final Color? foreground;
  final Widget? trailing;

  /// Corner radius (defaults to [AppRadius.r1] = 32dp). Jameia CTAs vary per
  /// surface — checkout place-order is a 25dp pill, address/settings/save use
  /// 16dp, order-list/help use 24dp — so callers override per the bundle.
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.primary;
    final fg = foreground ?? AppColors.brandForeground;
    final active = enabled && !loading && onPressed != null;
    final r = radius ?? AppRadius.r1;

    final child = Material(
      color: active ? bg : AppColors.divider,
      borderRadius: BorderRadius.circular(r),
      child: InkWell(
        borderRadius: BorderRadius.circular(r),
        onTap: active
            ? () {
                Haptics.tap();
                onPressed!();
              }
            : null,
        child: SizedBox(
          height: height,
          child: Center(
            child: loading
                ? BrandedLoader.inline(size: 22, color: fg)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.headingMedium.copyWith(
                          color: active ? fg : AppColors.tertiaryText,
                          fontWeight: AppTextStyles.bold,
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: AppSpacing.s8),
                        trailing!,
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );

    final sized = expanded
        ? SizedBox(width: double.infinity, child: child)
        : child;
    // Press-scale feel; InkWell keeps the ripple + tap (PressScale stays passive).
    return PressScale(enabled: active, child: sized);
  }
}
