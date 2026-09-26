import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../cubit/login_cubit.dart';
import '../../cubit/login_state.dart';

/// The single rounded outline the dial code and the number share. Only its
/// colours move (fill + a fixed-width border, [AppMotion.fast]): muted at
/// rest, brand green while focused, red once an invalid number was pointed
/// out ([errorRevealed]). [child] is passed through untouched, so a focus or
/// error change never rebuilds the text field.
class LoginPhoneOutline extends StatelessWidget {
  const LoginPhoneOutline({
    super.key,
    required this.focusNode,
    required this.errorRevealed,
    required this.child,
  });

  static const double height = AppSize.s56;
  static const double _border = AppSize.s1_5;

  final FocusNode focusNode;
  final ValueListenable<bool> errorRevealed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<LoginCubit, LoginState, bool>(
      selector: (state) => state.phone.isValid,
      builder: (context, valid) => ListenableBuilder(
        listenable: Listenable.merge([focusNode, errorRevealed]),
        child: child,
        builder: (context, child) {
          final focused = focusNode.hasFocus;
          final error = errorRevealed.value && !valid;
          final border = error
              ? AppColors.error
              : focused
              ? AppColors.primary
              : AppColors.divider;
          final fill = error
              ? AppColors.errorBg
              : focused
              ? AppColors.white
              : AppColors.mediumBackground;
          return AnimatedContainer(
            duration: MotionGuard.duration(context, AppMotion.fast),
            curve: AppMotion.signature,
            height: height,
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.s8,
              end: AppSpacing.s12,
            ),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(AppRadius.r3),
              border: Border.all(color: border, width: _border),
            ),
            child: child,
          );
        },
      ),
    );
  }
}
