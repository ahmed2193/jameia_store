import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../domain/entities/assistant_block.dart';
import '../../cubit/assistant_chat_cubit.dart';
import 'assistant_cart_action_done.dart';

/// What a proposal offers now: the confirm button while pending (loading
/// while the confirm is in flight, disabled while the reply still streams),
/// the confirm reply once added, a muted line once spent.
class AssistantCartActionFooter extends StatelessWidget {
  const AssistantCartActionFooter({
    super.key,
    required this.block,
    this.live = false,
  });

  final AssistantCartActionBlock block;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final id = block.actionId;
    final (confirming, message) = context
        .select<AssistantChatCubit, (bool, String?)>(
          (cubit) => (
            cubit.state.confirmingActionIds.contains(id),
            cubit.state.actionMessages[id],
          ),
        );
    final muted = AppTextStyles.captionLarge.copyWith(
      color: AppColors.secondaryText,
    );
    return switch (block.status) {
      AssistantActionStatus.pending => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            (live ? 'assistant.action_waiting' : 'assistant.action_not_added')
                .tr(),
            style: muted,
          ),
          const SizedBox(height: AppSpacing.s8),
          AppButton(
            label: 'assistant.action_confirm'.plural(block.unitCount),
            loading: confirming,
            enabled: !live,
            onPressed: () =>
                context.read<AssistantChatCubit>().confirmAction(id),
          ),
        ],
      ),
      AssistantActionStatus.confirmed => AssistantCartActionDone(
        message: message,
      ),
      AssistantActionStatus.cancelled => Text(
        'assistant.action_cancelled'.tr(),
        style: muted,
      ),
      AssistantActionStatus.expired || AssistantActionStatus.other => Text(
        'assistant.action_expired'.tr(),
        style: muted,
      ),
    };
  }
}
