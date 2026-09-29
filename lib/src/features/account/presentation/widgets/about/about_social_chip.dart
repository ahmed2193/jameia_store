import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../settings/settings_card.dart';
import 'about_social.dart';

/// One social profile tile: tinted glyph over the network's name. A tap
/// copies the profile address (there is no browser hand-off in the app) and
/// says so in place, like the delivery code's copy pill (B1-19): the glyph
/// flips to a check and the name to "Copied" for a moment, then back. The
/// screen reader hears which address was copied.
class AboutSocialChip extends StatefulWidget {
  const AboutSocialChip({super.key, required this.social});

  final AboutSocial social;

  @override
  State<AboutSocialChip> createState() => _AboutSocialChipState();
}

class _AboutSocialChipState extends State<AboutSocialChip> {
  static const Duration _copiedHold = Duration(milliseconds: 1800);

  bool _copied = false;
  Timer? _reset;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.social.handle));
    if (!mounted) return;
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(_copiedHold, () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final social = widget.social;
    final name = social.labelKey.tr();
    return Semantics(
      button: true,
      liveRegion: true,
      label: _copied
          ? 'settings.social_copied'.tr(namedArgs: {'handle': social.handle})
          : name,
      excludeSemantics: true,
      child: PressScale(
        haptic: HapticKind.selection,
        onTap: _copy,
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
                    color: _copied ? AppColors.brandLightBg : social.fill,
                    shape: BoxShape.circle,
                  ),
                  child: RepaintBoundary(
                    child: FlipValue(
                      flipKey: _copied,
                      alignment: AlignmentDirectional.center,
                      child: Icon(
                        _copied ? Icons.check_rounded : social.icon,
                        size: AppSize.s22,
                        color: _copied ? AppColors.primaryDark : social.tint,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              RepaintBoundary(
                child: FlipValue(
                  flipKey: _copied,
                  alignment: AlignmentDirectional.center,
                  child: Text(
                    _copied ? 'settings.copied'.tr() : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.subheadingMedium.copyWith(
                      color: _copied
                          ? AppColors.primaryDark
                          : AppColors.primaryText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
