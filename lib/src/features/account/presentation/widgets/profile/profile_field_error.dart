import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';

/// Inline validation line under a profile field. It opens (the height grows
/// while the text fades in) when [message] arrives and folds away when it is
/// cleared. Screen readers hear the refusal once, from the page listener
/// (`ProfileEditListener`), not from every field.
class ProfileFieldError extends StatelessWidget {
  const ProfileFieldError({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    final duration = MotionGuard.duration(context, AppMotion.fast);
    return AnimatedSize(
      duration: duration,
      curve: AppMotion.signature,
      alignment: AlignmentDirectional.topStart,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: AppMotion.signature,
        switchOutCurve: AppMotion.exit,
        child: text == null
            ? const SizedBox(width: double.infinity)
            : Padding(
                key: ValueKey<String>(text),
                padding: const EdgeInsetsDirectional.only(
                  top: AppSpacing.s6,
                  start: AppSpacing.s4,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsetsDirectional.only(top: AppSpacing.s1),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: AppSize.s14,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s4),
                    Expanded(
                      child: Text(
                        text,
                        style: AppTextStyles.captionLarge.copyWith(
                          color: AppColors.error,
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
