import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../motion/haptics.dart';
import '../responsive/app_size.dart';
import 'jameia_radio_mark.dart';

/// A choice row (checkout timing / payment / branch, cancel reasons): an
/// optional 24 dp icon, the title and a grey subtitle, an optional trailing
/// widget and the radio at the end. At least 56 dp tall; announced as a
/// checked / unchecked member of its group, with a selection haptic on tap.
/// Disabled rows are dimmed and ignore taps.
class OptionRow extends StatelessWidget {
  const OptionRow({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.enabled = true,
    this.trailing,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final Widget? trailing;
  final IconData? icon;

  static const double _disabledOpacity = 0.45;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    return MergeSemantics(
      child: Semantics(
        checked: selected,
        inMutuallyExclusiveGroup: true,
        enabled: enabled,
        child: Opacity(
          opacity: enabled ? 1 : _disabledOpacity,
          child: InkWell(
            onTap: enabled
                ? () {
                    Haptics.selection();
                    onTap();
                  }
                : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSize.s56),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.gutter,
                  vertical: AppSpacing.s12,
                ),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: AppSize.s24,
                        color: AppColors.primaryText,
                      ),
                      const SizedBox(width: AppSpacing.s16),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(title, style: AppTextStyles.itemTitle),
                          if (subtitle != null && subtitle.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.s2),
                            Text(subtitle, style: AppTextStyles.meta),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: AppSpacing.s8),
                      trailing!,
                    ],
                    const SizedBox(width: AppSpacing.s12),
                    JameiaRadioMark(selected: selected),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
