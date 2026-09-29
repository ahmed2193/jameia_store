import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/theme/app_colors.dart';
import '../design/hero_assets.dart';
import '../design/hero_icons.dart';
import '../responsive/app_size.dart';
import 'hero_snack_message.dart';

/// The tone glyph at the start of a snack bar: the Hero check (success),
/// the "i" (warning), the alert (error), the struck wifi (offline); plain
/// information has none. Tinted for the dark snack surface; decorative —
/// the words carry the meaning.
class HeroSnackGlyph extends StatelessWidget {
  const HeroSnackGlyph({super.key, required this.tone});

  static const double size = AppSize.s20;

  final HeroSnackTone tone;

  @override
  Widget build(BuildContext context) {
    final glyph = switch (tone) {
      HeroSnackTone.info => null,
      HeroSnackTone.success => SvgPicture.asset(
        HeroAssets.statusSuccess,
        width: size,
        height: size,
        colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
      ),
      HeroSnackTone.warning => const Icon(
        HeroIcons.info,
        size: size,
        color: AppColors.proAmber,
      ),
      HeroSnackTone.error => const Icon(
        HeroIcons.alert,
        size: size,
        color: AppColors.accent1,
      ),
      HeroSnackTone.offline => SvgPicture.asset(
        HeroAssets.statusOffline,
        width: size,
        height: size,
        colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
      ),
    };
    if (glyph == null) return const SizedBox.shrink();
    return ExcludeSemantics(child: glyph);
  }
}
