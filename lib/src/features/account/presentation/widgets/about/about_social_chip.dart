import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/responsive/app_size.dart';
import '../settings/settings_card.dart';
import 'about_social.dart';

/// One social profile tile: tinted glyph over the network's name. A tap
/// copies the profile address (there is no browser hand-off in the app).
class AboutSocialChip extends StatelessWidget {
  const AboutSocialChip({super.key, required this.social});

  static const double _pressedScale = 0.97;

  final AboutSocial social;

  Future<void> _copy(BuildContext context) async {
    final message = 'settings.social_copied'.tr(
      namedArgs: {'handle': social.handle},
    );
    await Clipboard.setData(ClipboardData(text: social.handle));
    if (!context.mounted) return;
    showHeroSnackBar(context, message, behavior: SnackBarBehavior.floating);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: PressScale(
        pressedScale: _pressedScale,
        haptic: HapticKind.selection,
        onTap: () => _copy(context),
        child: SettingsCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s8,
            vertical: AppSpacing.s14,
          ),
          child: Column(
            children: [
              SizedBox.square(
                dimension: AppSize.s40,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: social.fill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    social.icon,
                    size: AppSize.s22,
                    color: social.tint,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                social.labelKey.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.subheadingMedium.copyWith(
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
