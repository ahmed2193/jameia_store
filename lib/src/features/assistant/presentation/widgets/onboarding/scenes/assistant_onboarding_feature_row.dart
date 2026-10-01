import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_colors.dart';
import '../../../../../../config/theme/app_shadows.dart';
import '../../../../../../config/theme/app_spacing.dart';
import '../../../../../../config/theme/app_text_styles.dart';
import '../../../../../../core/responsive/app_size.dart';
import '../../../../../../core/widgets/hero_icon.dart';

/// One answer card in the "more" demo — a deal, an order on its way, a
/// delivery slot: its glyph on a tinted disc, a title, a line under it and
/// a detail at the end. Slides in from the start edge as [appear] goes to
/// `1`.
class AssistantOnboardingFeatureRow extends StatelessWidget {
  const AssistantOnboardingFeatureRow({
    super.key,
    required this.icon,
    required this.color,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.appear,
  });

  final IconData icon;
  final Color color;
  final Color tint;
  final String title;
  final String subtitle;
  final Widget trailing;
  final double appear;

  static const double _width = AppSize.s300;
  static const double _height = AppSize.s56;
  static const double _disc = AppSize.s36;
  static const double _slide = AppSize.s24;
  static const BoxDecoration _card = BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.r3)),
    boxShadow: AppShadows.low,
  );

  @override
  Widget build(BuildContext context) {
    final shown = appear.clamp(0.0, 1.0);
    final fromStart = Directionality.of(context) == TextDirection.ltr
        ? -_slide
        : _slide;
    return Opacity(
      opacity: shown,
      child: Transform.translate(
        offset: Offset(fromStart * (1 - shown), 0),
        child: SizedBox(
          width: _width,
          height: _height,
          child: DecoratedBox(
            decoration: _card,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s10,
              ),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: _disc,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: tint,
                        shape: BoxShape.circle,
                      ),
                      child: HeroIcon(icon, size: AppSize.s18, color: color),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.subheadingMedium.copyWith(
                            color: AppColors.primaryText,
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.captionLarge.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
