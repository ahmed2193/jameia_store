import 'package:flutter/material.dart';

import '../../../../core/design/keeta_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Grouped settings card — a white rounded container that hosts a column of
/// settings rows (KeeTa's grouped-cell look on the Mine → Settings surface).
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// Hairline divider between cells, inset to align with the cell label.
class SettingsCellDivider extends StatelessWidget {
  const SettingsCellDivider({super.key});

  @override
  Widget build(BuildContext context) => const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.divider,
        indent: AppSpacing.s16,
        endIndent: AppSpacing.s16,
      );
}

/// Navigation cell: label + optional trailing text + chevron, tappable.
class SettingsNavCell extends StatelessWidget {
  const SettingsNavCell({
    super.key,
    required this.label,
    required this.onTap,
    this.trailingText,
  });

  final String label;
  final VoidCallback onTap;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s16, vertical: AppSpacing.s14),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: AppTextStyles.headingMedium),
            ),
            if (trailingText != null) ...[
              Text(trailingText!,
                  style: AppTextStyles.captionLarge
                      .copyWith(color: AppColors.tertiaryText)),
              const SizedBox(width: AppSpacing.s6),
            ],
            const Icon(KeetaIcons.arrowRight,
                size: 16, color: AppColors.tertiaryText),
          ],
        ),
      ),
    );
  }
}

/// Switch cell: label + trailing Material switch.
class SettingsSwitchCell extends StatelessWidget {
  const SettingsSwitchCell({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
          start: AppSpacing.s16, end: AppSpacing.s8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTextStyles.headingMedium),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.brandForeground,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
