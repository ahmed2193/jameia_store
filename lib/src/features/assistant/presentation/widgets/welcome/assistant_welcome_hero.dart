import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../domain/entities/assistant_day_part.dart';
import '../chat/assistant_avatar.dart';

/// The welcome's head: the avatar pops in on a brand-tinted disc, then a
/// greeting for the time of day — by name when the customer has one — the
/// question and what the assistant can do.
class AssistantWelcomeHero extends StatelessWidget {
  const AssistantWelcomeHero({super.key});

  @override
  Widget build(BuildContext context) {
    final name = context.select<AuthSessionCubit, String>(
      (session) => session.state.customer?.givenName.trim() ?? '',
    );
    final dayPart = AssistantDayPart.of(DateTime.now());
    final greeting = name.isEmpty
        ? dayPart.greetingKey(withName: false).tr()
        : dayPart.greetingKey(withName: true).tr(namedArgs: {'name': name});
    return Column(
      children: [
        const SizedBox.square(
          dimension: AppSize.s96,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.brandLightBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: PopScale.onMount(
                child: AssistantAvatar(size: AppSize.s72, alive: true),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        Semantics(
          header: true,
          child: Text(
            greeting,
            textAlign: TextAlign.center,
            style: AppTextStyles.headingLarge,
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          'assistant.welcome_title'.tr(),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.primaryText,
            fontWeight: AppTextStyles.medium,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'assistant.welcome_body'.tr(),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.secondaryText,
            height: AppSize.lh1_5,
          ),
        ),
      ],
    );
  }
}
