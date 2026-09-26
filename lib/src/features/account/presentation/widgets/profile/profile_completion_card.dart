import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/profile_completion.dart';
import '../../../domain/entities/profile_field.dart';
import '../../cubit/profile_cubit.dart';
import '../../cubit/profile_state.dart';
import 'profile_completion_ring.dart';

/// Brand-green hero at the top of the form (the Rewards / coupons hero in
/// the app's own colour): the completion ring and what it means — "Complete
/// your profile" while the account still has the sign-up placeholder name,
/// the share filled in and the next field to add, or "complete". Follows the
/// draft, so the ring moves as the customer fills the form in.
class ProfileCompletionCard extends StatelessWidget {
  const ProfileCompletionCard({super.key});

  static const List<Color> _gradient = [
    AppColors.primary,
    AppColors.primaryDark,
    AppColors.accent2Dark,
  ];
  static const double _shadowAlpha = 0.24;
  static const Offset _shadowOffset = Offset(0, AppSpacing.s8);
  static final List<BoxShadow> _shadow = [
    BoxShadow(
      color: AppColors.primaryDark.withValues(alpha: _shadowAlpha),
      offset: _shadowOffset,
      blurRadius: AppSize.s24,
      spreadRadius: -AppSpacing.s6,
    ),
  ];
  static const double _mutedAlpha = 0.9;
  static final Color _muted = AppColors.white.withValues(alpha: _mutedAlpha);
  static const double _ringAlpha = 0.12;
  static final Color _ring = AppColors.white.withValues(alpha: _ringAlpha);
  static const double _ringOverhang = -AppSpacing.s48;
  static const double _ringWidth = AppSpacing.s24;
  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppRadius.r2),
  );

  static String _title(ProfileCompletion completion, bool needsName) {
    if (needsName) return 'profile.complete_profile'.tr();
    if (completion.isComplete) return 'profile.completion_done'.tr();
    // The share is its own LTR run: "60%" in either language.
    return 'profile.completion_title'.tr(
      namedArgs: {'pct': Formatters.isolate('${completion.percent}%')},
    );
  }

  static String _hint(ProfileCompletion completion, bool needsName) {
    if (needsName) return 'profile.complete_profile_hint'.tr();
    return switch (completion.next) {
      null => 'profile.completion_done_hint'.tr(),
      ProfileField.name => 'profile.next_name'.tr(),
      ProfileField.dateOfBirth => 'profile.next_date_of_birth'.tr(),
      ProfileField.gender => 'profile.next_gender'.tr(),
      ProfileField.householdSize => 'profile.next_household_size'.tr(),
      ProfileField.email => 'profile.next_email'.tr(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProfileCubit, ProfileState, (ProfileCompletion, bool)>(
      selector: (state) => (state.completion, state.needsName),
      builder: (context, header) {
        final (completion, needsName) = header;
        final title = _title(completion, needsName);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: _radius,
            boxShadow: _shadow,
            gradient: const LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: _gradient,
            ),
          ),
          child: ClipRRect(
            borderRadius: _radius,
            child: Stack(
              children: [
                PositionedDirectional(
                  top: _ringOverhang,
                  end: _ringOverhang,
                  child: SizedBox.square(
                    dimension: AppSize.s160,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _ring, width: _ringWidth),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.s16,
                    AppSpacing.s20,
                    AppSpacing.s16,
                    AppSpacing.s20,
                  ),
                  child: Row(
                    children: [
                      ProfileCompletionRing(completion: completion),
                      const SizedBox(width: AppSpacing.s16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FlipValue(
                              flipKey: title,
                              child: Text(
                                title,
                                style: AppTextStyles.headingLarge.copyWith(
                                  fontWeight: AppTextStyles.bold,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s4),
                            Text(
                              _hint(completion, needsName),
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: AppTextStyles.medium,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
