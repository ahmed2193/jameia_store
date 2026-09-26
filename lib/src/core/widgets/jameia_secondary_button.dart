import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../responsive/app_size.dart';

/// Secondary button: a white pill with a hairline border and an ink label
/// ([destructive] → red label). [compact] is the 44 dp card-action size with
/// the 14 medium label. The label shrinks to fit instead of wrapping.
class JameiaSecondaryButton extends StatelessWidget {
  const JameiaSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = AppSize.s48,
    this.expanded = false,
    this.compact = false,
    this.icon,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final bool expanded;
  final bool compact;
  final IconData? icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      minimumSize: Size(0, height),
      backgroundColor: AppColors.white,
      foregroundColor: destructive
          ? AppColors.errorDeep
          : AppColors.primaryText,
      disabledForegroundColor: AppColors.tertiaryText,
      side: const BorderSide(color: AppColors.divider),
      shape: const StadiumBorder(),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: compact ? AppSpacing.s12 : AppSpacing.s24,
      ),
      textStyle: compact ? AppTextStyles.label : AppTextStyles.itemTitleStrong,
    );
    final text = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(label, maxLines: 1),
    );
    final button = icon == null
        ? OutlinedButton(onPressed: onPressed, style: style, child: text)
        : OutlinedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: AppSize.s20),
            label: text,
          );
    return SizedBox(
      height: height,
      width: expanded ? double.infinity : null,
      child: button,
    );
  }
}
