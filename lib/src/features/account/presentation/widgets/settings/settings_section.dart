import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import 'settings_card.dart';
import 'settings_divider.dart';

/// A titled group of settings rows: an optional small heading above one
/// rounded card, the rows split by inset hairlines.
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final heading = title;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (heading != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.s4,
              0,
              AppSpacing.s4,
              AppSpacing.s8,
            ),
            child: Semantics(
              header: true,
              child: Text(
                heading,
                style: AppTextStyles.subheadingMedium.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          ),
        SettingsCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SettingsDivider(),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
