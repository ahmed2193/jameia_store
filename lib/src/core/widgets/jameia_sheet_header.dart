import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../responsive/app_size.dart';
import 'jameia_close_button.dart';

/// Top of a bottom sheet: a drag handle, then the bold title and a ✕ that
/// closes the sheet the same way a barrier tap does. Pass [shape] and
/// `AppColors.white` to `showJameiaBottomSheet` so every sheet looks alike.
class JameiaSheetHeader extends StatelessWidget {
  const JameiaSheetHeader({
    super.key,
    required this.title,
    this.showClose = true,
    this.onClose,
  });

  /// White sheet with a 24 dp top radius.
  static const ShapeBorder shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
  );

  final String title;
  final bool showClose;

  /// Defaults to popping the sheet with no result.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.s8),
        const ExcludeSemantics(
          child: SizedBox(
            width: AppSize.s36,
            height: AppSize.s4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.disabledText,
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.gutter,
            AppSpacing.s8,
            AppSpacing.s4,
            AppSpacing.s4,
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: AppTextStyles.groupTitle),
                ),
              ),
              if (showClose)
                JameiaCloseButton(onPressed: onClose)
              else
                const SizedBox(height: AppSize.s48),
            ],
          ),
        ),
      ],
    );
  }
}
