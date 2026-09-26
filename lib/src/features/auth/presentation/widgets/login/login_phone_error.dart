import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../cubit/login_cubit.dart';
import '../../cubit/login_state.dart';

/// Validation line under the phone unit. It waits until the problem was
/// pointed out ([revealed]: the field lost focus with a partial number, or
/// the disabled Continue was tapped) instead of scolding every keystroke,
/// then follows the number live and leaves once it is valid. Grows + fades
/// in; announced to screen readers. Reduced motion → an instant cut.
class LoginPhoneError extends StatelessWidget {
  const LoginPhoneError({super.key, required this.revealed});

  final ValueListenable<bool> revealed;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<LoginCubit, LoginState, bool>(
      selector: (state) => state.phone.isValid,
      builder: (context, valid) => ValueListenableBuilder<bool>(
        valueListenable: revealed,
        builder: (context, shown, _) => AnimatedSwitcher(
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
          child: shown && !valid
              ? Padding(
                  key: const ValueKey('phone-error'),
                  padding: const EdgeInsetsDirectional.only(
                    top: AppSpacing.s8,
                    start: AppSpacing.s4,
                  ),
                  child: Semantics(
                    liveRegion: true,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: AppSize.s16,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: AppSpacing.s6),
                        Expanded(
                          child: Text(
                            'auth.phone_invalid'.tr(),
                            style: AppTextStyles.captionLarge.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ),
    );
  }
}
