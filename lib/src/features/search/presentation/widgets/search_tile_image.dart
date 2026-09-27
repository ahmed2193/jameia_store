import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/widgets/hero_image.dart';

/// The picture of a search tile, filling its box with 16 dp corners: the
/// photo, or — without one — the first letter on the muted fill. [outlined]
/// adds a hairline (brand logos are often white on white).
class SearchTileImage extends StatelessWidget {
  const SearchTileImage({
    super.key,
    required this.url,
    required this.initial,
    this.outlined = false,
  });

  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppRadius.media),
  );

  final String url;
  final String initial;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: _radius,
        border: outlined ? Border.all(color: AppColors.divider) : null,
      ),
      child: url.isEmpty
          ? DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.smallBackground,
                borderRadius: _radius,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: AppTextStyles.groupTitle.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            )
          : HeroImage(url: url, radius: AppRadius.media),
    );
  }
}
