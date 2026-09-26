import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';

/// Inline text link in the brand link color: no visual padding, so it lines
/// up with the text around it, but a padded (48 dp) touch target.
class AuthLinkButton extends StatelessWidget {
  const AuthLinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Base text style; the link color + medium weight are applied on top.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      child: Text(
        label,
        style: (style ?? AppTextStyles.bodyLarge).copyWith(
          color: AppColors.link,
          fontWeight: AppTextStyles.medium,
        ),
      ),
    );
  }
}
