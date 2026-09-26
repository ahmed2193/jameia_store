import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../responsive/app_size.dart';

/// Underlined text link — "View all", "Change", "Clear cart", "Load more".
/// A 44 dp tall tap target, announced on its own (never merged into the row
/// around it). [navigates] = false announces it as a button (an action that
/// stays on the page); `onTap == null` greys it out and disables it.
class JameiaTextLink extends StatelessWidget {
  const JameiaTextLink({
    super.key,
    required this.label,
    required this.onTap,
    this.color = AppColors.primaryText,
    this.navigates = true,
    this.style,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final bool navigates;

  /// Defaults to [AppTextStyles.label].
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final ink = enabled ? color : AppColors.tertiaryText;
    return Semantics(
      link: navigates,
      button: !navigates,
      enabled: enabled,
      container: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.s44),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s4,
            ),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (style ?? AppTextStyles.label).copyWith(
                  color: ink,
                  decoration: TextDecoration.underline,
                  decorationColor: ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
