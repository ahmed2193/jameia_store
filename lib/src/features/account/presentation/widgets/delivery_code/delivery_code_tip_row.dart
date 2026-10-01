import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../settings/settings_tone.dart';

/// One delivery-code tip: a tinted glyph disc and the sentence.
class DeliveryCodeTipRow extends StatelessWidget {
  const DeliveryCodeTipRow({
    super.key,
    required this.icon,
    required this.tone,
    required this.text,
  });

  final IconData icon;
  final SettingsTone tone;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox.square(
          dimension: AppSize.s32,
          child: DecoratedBox(
            decoration: BoxDecoration(color: tone.fill, shape: BoxShape.circle),
            child: HeroIcon(icon, size: AppSize.s16, color: tone.ink),
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: AppSpacing.s6),
            child: Text(
              text,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
