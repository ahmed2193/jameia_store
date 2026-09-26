import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/failure_message.dart';
import '../../cubit/otp_cubit.dart';
import '../../cubit/otp_state.dart';

/// Why the code was refused (the backend's own, localized words), under the
/// digits until the code is edited or a new one is sent. Grows + fades in and
/// is announced to screen readers; reduced motion → an instant cut.
class OtpCodeError extends StatelessWidget {
  const OtpCodeError({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<OtpCubit, OtpState, Failure?>(
      selector: (state) => state.codeFailure,
      builder: (context, failure) => AnimatedSwitcher(
        duration: MotionGuard.duration(context, AppMotion.fast),
        switchInCurve: MotionGuard.curve(context, AppMotion.signature),
        switchOutCurve: MotionGuard.curve(context, AppMotion.exit),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SizeTransition(sizeFactor: animation, child: child),
        ),
        child: failure == null
            ? const SizedBox(width: double.infinity)
            : Padding(
                key: ValueKey<Failure>(failure),
                padding: const EdgeInsetsDirectional.only(top: AppSpacing.s12),
                child: Semantics(
                  liveRegion: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: AppSize.s16,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: AppSpacing.s6),
                      Flexible(
                        child: Text(
                          failure.localizedMessage,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.subheadingMedium.copyWith(
                            color: AppColors.error,
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
