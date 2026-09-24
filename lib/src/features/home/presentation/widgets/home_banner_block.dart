import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/jameia_image.dart';
import '../../domain/entities/home_section_entity.dart';

/// One image banner of the home feed, with its caption on a bottom scrim.
class HomeBannerBlock extends StatelessWidget {
  const HomeBannerBlock({
    super.key,
    required this.section,
    required this.onTap,
  });

  final HomeBannerSection section;
  final VoidCallback onTap;

  static const double _height = AppSize.s160;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.pageMargin,
        0,
        AppSpacing.pageMargin,
        AppSpacing.s8,
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: SizedBox(
            height: _height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                JameiaImage(url: section.imageUrl),
                if (section.caption.isNotEmpty)
                  PositionedDirectional(
                    start: 0,
                    end: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        AppSpacing.s12,
                        AppSpacing.s16,
                        AppSpacing.s12,
                        AppSpacing.s8,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.bannerScrimTransparent,
                            AppColors.bannerScrim50,
                          ],
                        ),
                      ),
                      child: Text(
                        section.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.white,
                          fontWeight: AppTextStyles.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
