import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_colors.dart';
import '../../../../../../config/theme/app_shadows.dart';
import '../../../../../../config/theme/app_spacing.dart';
import '../../../../../../config/theme/app_text_styles.dart';
import '../../../../../../core/responsive/app_size.dart';
import '../../../../../../core/widgets/hero_icon.dart';
import 'assistant_onboarding_skill.dart';

/// One thing the assistant does, as a small white pill: its glyph on a
/// tinted disc and a short name that shrinks rather than wraps.
class AssistantOnboardingSkillChip extends StatelessWidget {
  const AssistantOnboardingSkillChip({
    super.key,
    required this.skill,
    required this.maxWidth,
  });

  final AssistantOnboardingSkill skill;
  final double maxWidth;

  static const double _disc = AppSize.s24;
  static const BoxDecoration _pill = BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
    boxShadow: AppShadows.low,
  );

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: _pill,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.s4,
            AppSpacing.s4,
            AppSpacing.s10,
            AppSpacing.s4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: _disc,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: skill.tint,
                    shape: BoxShape.circle,
                  ),
                  child: HeroIcon(
                    skill.icon,
                    size: AppSize.s14,
                    color: skill.color,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    skill.labelKey.tr(),
                    maxLines: 1,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primaryText,
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
