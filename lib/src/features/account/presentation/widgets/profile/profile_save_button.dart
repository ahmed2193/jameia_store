import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/motion/spring_curve.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/branded_loader.dart';
import '../../cubit/profile_cubit.dart';
import '../../cubit/profile_state.dart';

/// The form's primary CTA, pill-shaped and full width. Enabled once the
/// draft differs from the saved profile; its content fades through label →
/// loader while the PATCH runs → a popping check once it is saved (the page
/// leaves after a short hold). The width never changes, and a screen reader
/// hears each state as it arrives.
class ProfileSaveButton extends StatelessWidget {
  const ProfileSaveButton({super.key});

  static const double _height = AppSize.s52;
  static const double _loaderSize = AppSize.s22;
  static const double _checkSize = AppSize.s28;
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
        // Idle (enabled or not), saving, saved: the three faces the content
        // fades through. Enabling only recolours the idle face.
        final phase = switch (state.status) {
          ProfileStatus.saving || ProfileStatus.saved => state.status,
          _ => ProfileStatus.ready,
        };
        final busy = phase != ProfileStatus.ready;
        final label = switch (state.status) {
          ProfileStatus.saving => 'profile.saving'.tr(),
          ProfileStatus.saved => 'profile.saved'.tr(),
          _ => 'profile.save'.tr(),
        };
        final fill = active || busy ? AppColors.primary : AppColors.divider;
        return Semantics(
          button: true,
          enabled: active,
          liveRegion: true,
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
                        child: FadeThroughSwitcher(
                          stateKey: phase,
                          child: switch (phase) {
                            ProfileStatus.saving => const BrandedLoader.inline(
                              size: _loaderSize,
                              color: AppColors.brandForeground,
                            ),
                            ProfileStatus.saved => PopScale.onMount(
                              duration: AppSprings.snappy.duration,
                              curve: AppSprings.snappy,
                              child: const Icon(
                                Icons.check_rounded,
                                size: _checkSize,
                                color: AppColors.brandForeground,
                              ),
                            ),
                            _ => Padding(
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
                                    color: active
                                        ? AppColors.brandForeground
                                        : AppColors.tertiaryText,
                                  ),
                                  child: Text(label, maxLines: 1),
                                ),
                              ),
                            ),
                          },
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
