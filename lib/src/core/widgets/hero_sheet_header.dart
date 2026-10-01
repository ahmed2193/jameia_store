import 'package:flutter/material.dart';

import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../motion/entrance_cascade_item.dart';
import '../motion/pop_scale.dart';
import '../responsive/app_size.dart';
import 'hero_close_button.dart';
import 'hero_sheet_handle.dart';

/// Top of a bottom sheet: the drag handle ([HeroSheetHandle]), then the bold
/// title (an optional grey [subtitle] under it, an optional [leading] mark
/// before it) and a ✕ at the end that closes the sheet the same way a
/// barrier tap does. `showHeroBottomSheet` gives every sheet the white
/// surface and the 24 dp top corners ([shape]) by default.
///
/// It arrives with the sheet: the title rises in and the ✕ pops once, on
/// mount; the sheet's rows follow it with `EntranceCascadeItem.single`
/// (index 1 on). Still under reduced motion.
class HeroSheetHeader extends StatelessWidget {
  const HeroSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.showClose = true,
    this.onClose,
  });

  /// White sheet with a 24 dp top radius.
  static const ShapeBorder shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
  );

  /// The ✕ grows from here once, on mount.
  static const double _closeFrom = 0.6;

  final String title;

  /// A grey line under the title.
  final String? subtitle;

  /// A mark before the title (a coupon's ticket disc).
  final Widget? leading;
  final bool showClose;

  /// Defaults to popping the sheet with no result.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final mark = leading;
    final second = subtitle;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const HeroSheetHandle(),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.gutter,
            AppSpacing.s8,
            AppSpacing.s4,
            AppSpacing.s4,
          ),
          child: Row(
            children: [
              if (mark != null) ...[
                mark,
                const SizedBox(width: AppSpacing.s12),
              ],
              Expanded(
                child: EntranceCascadeItem.single(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(title, style: AppTextStyles.groupTitle),
                      ),
                      if (second != null && second.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.s2),
                        Text(second, style: AppTextStyles.meta),
                      ],
                    ],
                  ),
                ),
              ),
              if (showClose)
                PopScale.onMount(
                  from: _closeFrom,
                  child: HeroCloseButton(onPressed: onClose),
                )
              else
                const SizedBox(height: AppSize.s48),
            ],
          ),
        ),
      ],
    );
  }
}
