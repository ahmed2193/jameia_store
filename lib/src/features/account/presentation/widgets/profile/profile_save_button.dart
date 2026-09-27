import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../cubit/profile_cubit.dart';
import '../../cubit/profile_state.dart';

/// The form's primary CTA, pill-shaped and full width. Enabled once the
/// draft differs from the saved profile. While the PATCH runs and the check
/// shows, the page's busy overlay holds the screen; the pill stays green
/// with its label under it (never a grey flash), and takes no tap.
class ProfileSaveButton extends StatelessWidget {
  const ProfileSaveButton({super.key});

  static const double _height = AppSize.s52;
  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppRadius.pill),
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      buildWhen: (previous, current) =>
          previous.canSave != current.canSave ||
          previous.status != current.status,
      builder: (context, state) {
        final active = state.canSave;
        final busy =
            state.status == ProfileStatus.saving ||
            state.status == ProfileStatus.saved;
        final green = active || busy;
        final label = 'profile.save'.tr();
        final fill = green ? AppColors.primary : AppColors.divider;
        return Semantics(
          button: true,
          enabled: active,
          label: label,
          child: ExcludeSemantics(
            child: PressScale(
              enabled: active,
              child: ClipRRect(
                borderRadius: _radius,
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: fill),
                  duration: MotionGuard.duration(context, AppMotion.fast),
                  curve: AppMotion.signature,
                  builder: (context, color, content) =>
                      ColoredBox(color: color ?? fill, child: content),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: active
                          ? () {
                              Haptics.tap();
                              context.read<ProfileCubit>().save();
                            }
                          : null,
                      child: SizedBox(
                        height: _height,
                        width: double.infinity,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpacing.s16,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: AnimatedDefaultTextStyle(
                                duration: MotionGuard.duration(
                                  context,
                                  AppMotion.fast,
                                ),
                                curve: AppMotion.signature,
                                style: AppTextStyles.headingMedium.copyWith(
                                  fontWeight: AppTextStyles.bold,
                                  color: green
                                      ? AppColors.brandForeground
                                      : AppColors.tertiaryText,
                                ),
                                child: Text(label, maxLines: 1),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
