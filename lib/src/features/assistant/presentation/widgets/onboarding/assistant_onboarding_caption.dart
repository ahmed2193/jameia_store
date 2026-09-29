import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/entrance_cascade_item.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../domain/entities/assistant_onboarding_step.dart';

/// The step's words under its demo: the title (the first one greets the
/// customer by name) and a line of explanation, rising in one after the
/// other when the step first comes in front ([active]) — mounted when
/// ready, and at rest on a step already [played].
class AssistantOnboardingCaption extends StatelessWidget {
  const AssistantOnboardingCaption({
    super.key,
    required this.step,
    required this.active,
    this.played = false,
  });

  final AssistantOnboardingStep step;
  final bool active;
  final bool played;

  @override
  Widget build(BuildContext context) {
    final name = context.select<AuthSessionCubit, String>(
      (session) => session.state.customer?.givenName.trim() ?? '',
    );
    final title = step
        .titleKeyFor(withName: name.isNotEmpty)
        .tr(namedArgs: {'name': name});
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EntranceCascadeItem.single(
          key: ValueKey<(String, bool)>((step.titleKey, active)),
          play: active && !played,
          child: Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.groupTitle.copyWith(
                color: AppColors.primaryText,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        EntranceCascadeItem.single(
          key: ValueKey<(String, bool)>((step.bodyKey, active)),
          play: active && !played,
          index: 1,
          child: Text(
            step.bodyKey.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ),
      ],
    );
  }
}
