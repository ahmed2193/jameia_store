import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../language/presentation/cubit/localization_cubit.dart';
import '../../../language/presentation/cubit/localization_state.dart';
import '../cubit/setting_cubit.dart';
import '../cubit/setting_state.dart';

/// One-tap language toggle — models khayool's `LanguageIconButton`.
///
/// Reads two cubits: [SettingCubit] (`isChangingLanguage` → spinner + disable)
/// and [LocalizationCubit] (`locale` → which label/target to show). The pill
/// shows the OTHER language ('ع' while English, 'EN' while Arabic); tapping it
/// fires a light haptic and routes through `SettingCubit.changeLanguage`, which
/// drives the whole-app reactive switch. Drop it into an `AppBar.actions`.
class LanguageIconButton extends StatelessWidget {
  const LanguageIconButton({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingCubit, SettingState>(
      buildWhen: (p, c) => p.isChangingLanguage != c.isChangingLanguage,
      builder: (context, settingState) {
        return BlocBuilder<LocalizationCubit, LocalizationState>(
          builder: (context, locState) {
            final isEnglish = locState.isEnglish;
            final label = isEnglish ? 'ع' : 'EN';
            final targetLang = isEnglish ? 'ar' : 'en';
            final isChanging = settingState.isChangingLanguage;

            return Semantics(
              button: true,
              label: (isEnglish
                      ? 'settings.switch_to_arabic'
                      : 'settings.switch_to_english')
                  .tr(),
              child: PressScale(
                haptic: null, // fired explicitly below to match the switch call
                onTap: isChanging
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        context
                            .read<SettingCubit>()
                            .changeLanguage(context, targetLang);
                      },
                child: AnimatedContainer(
                  duration: MotionGuard.duration(context, AppMotion.fast),
                  curve: MotionGuard.curve(context, AppMotion.signature),
                  width: size,
                  height: size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: isChanging
                      ? SizedBox(
                          width: size * 0.42,
                          height: size * 0.42,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryText),
                          ),
                        )
                      : AnimatedSwitcher(
                          duration: MotionGuard.duration(context, AppMotion.flip),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.6, end: 1.0)
                                  .animate(anim),
                              child: child,
                            ),
                          ),
                          child: Text(
                            label,
                            key: ValueKey<String>(label),
                            style: AppTextStyles.captionLarge.copyWith(
                              color: AppColors.primaryText,
                              fontWeight: AppTextStyles.bold,
                            ),
                          ),
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
