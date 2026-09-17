import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion.dart';
import '../../cubit/login_cubit.dart';
import '../../cubit/login_state.dart';

/// Inline validation line under the phone field; slides/fades in as it
/// appears (reduced motion collapses it to an instant cut).
class LoginPhoneError extends StatelessWidget {
  const LoginPhoneError({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<LoginCubit, LoginState, bool>(
      selector: (state) => state.showPhoneError,
      builder: (context, showError) => AnimatedSwitcher(
        duration: MotionGuard.duration(context, AppMotion.fast),
        switchInCurve: MotionGuard.curve(context, AppMotion.signature),
        switchOutCurve: MotionGuard.curve(context, AppMotion.exit),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            alignment: AlignmentDirectional.topStart,
            child: child,
          ),
        ),
        child: showError
            ? Padding(
                key: const ValueKey('phone-error'),
                padding: const EdgeInsetsDirectional.only(top: AppSpacing.s6),
                child: Text(
                  'auth.phone_invalid'.tr(),
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.error,
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
