import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../domain/entities/assistant_onboarding_step.dart';
import '../chat/assistant_entrance.dart';

/// The step's words under its demo: the title (the first one greets the
/// customer by name) and a line of explanation, rising in one after the
/// other each time the step becomes [active].
class AssistantOnboardingCaption extends StatelessWidget {
  const AssistantOnboardingCaption({
    super.key,
    required this.step,
    required this.active,
  });

  final AssistantOnboardingStep step;
  final bool active;

  static const Offset _rise = Offset(0, 0.3);
  static const Duration _bodyDelay = Duration(milliseconds: 70);

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
        AssistantEntrance(
          key: ValueKey<(String, bool)>((step.titleKey, active)),
          animate: active,
          beginOffset: _rise,
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
        AssistantEntrance(
          key: ValueKey<(String, bool)>((step.bodyKey, active)),
          animate: active,
          beginOffset: _rise,
          delay: _bodyDelay,
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
