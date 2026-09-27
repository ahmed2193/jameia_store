import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';

/// Hero's public social profiles on About. The icon font has no brand
/// glyphs, so each gets a distinct Material glyph and tint.
enum AboutSocial {
  facebook(
    labelKey: 'settings.social_facebook',
    handle: 'facebook.com/Jameia',
    icon: Icons.facebook_rounded,
    tint: AppColors.link,
    fill: AppColors.accentSkyLight,
  ),
  instagram(
    labelKey: 'settings.social_instagram',
    handle: 'instagram.com/jameia.official',
    icon: Icons.camera_alt_outlined,
    tint: AppColors.proFuchsia,
    fill: AppColors.accentVioletLight,
  ),
  x(
    labelKey: 'settings.social_x',
    handle: 'x.com/Jameia',
    icon: Icons.alternate_email_rounded,
    tint: AppColors.primaryText,
    fill: AppColors.smallBackground,
  );

  const AboutSocial({
    required this.labelKey,
    required this.handle,
    required this.icon,
    required this.tint,
    required this.fill,
  });

  final String labelKey;

  /// The public profile address (copied on tap).
  final String handle;
  final IconData icon;
  final Color tint;
  final Color fill;
}
