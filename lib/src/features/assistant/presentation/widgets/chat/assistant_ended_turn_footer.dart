import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/failure_message.dart';
import '../../../domain/entities/assistant_live_turn.dart';
import '../../cubit/assistant_chat_cubit.dart';
import '../../cubit/assistant_chat_state.dart';
import 'assistant_entrance.dart';
import 'assistant_handoff_dialog.dart';
import 'assistant_suggestion_chip.dart';

/// Under a reply that failed or was stopped: what happened (the server's
/// text as sent, or ours) and what can be done — Retry (last row only),
/// Talk to a person, or a new chat when the thread is gone (L9).
class AssistantEndedTurnFooter extends StatelessWidget {
  const AssistantEndedTurnFooter({
    super.key,
    required this.turn,
    required this.isLast,
  });

  final AssistantLiveTurn turn;
  final bool isLast;

  String _message() {
    if (turn.isStopped) return 'assistant.stopped'.tr();
    if (turn.lostConversation) return 'assistant.conversation_unavailable'.tr();
    return turn.displayErrorMessage ??
        turn.failure?.localizedMessage ??
        'assistant.turn_failed'.tr();
  }

  @override
  Widget build(BuildContext context) {
    final orphanProposal = turn.hasOrphanProposal;
    final cubit = context.read<AssistantChatCubit>();
    return AssistantEntrance(
      animate: isLast,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: AppSpacing.s32,
          top: AppSpacing.s8,
        ),
        child:
            BlocSelector<AssistantChatCubit, AssistantChatState, (bool, bool)>(
              selector: (state) => (state.canSend, state.canHandOff),
              builder: (context, flags) {
                final (canSend, canHandOff) = flags;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (orphanProposal)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          bottom: AppSpacing.s6,
                        ),
                        child: Text(
                          'assistant.action_manual_hint'.tr(),
                          style: AppTextStyles.captionLarge.copyWith(
                            color: AppColors.labelGrey,
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Icon(
                          turn.isStopped
                              ? Icons.stop_circle_outlined
                              : Icons.error_outline_rounded,
                          size: AppSize.s16,
                          color: turn.isStopped
                              ? AppColors.labelGrey
                              : AppColors.error,
                        ),
                        const SizedBox(width: AppSpacing.s6),
                        Expanded(
                          child: Text(
                            _message(),
                            style: AppTextStyles.captionLarge.copyWith(
                              color: turn.isStopped
                                  ? AppColors.labelGrey
                                  : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        if (isLast && canSend && !turn.lostConversation)
                          AssistantSuggestionChip(
                            label: 'assistant.retry'.tr(),
                            icon: Icons.refresh_rounded,
                            onTap: () => cubit.retryTurn(turn.key),
                          ),
                        if (turn.lostConversation)
                          AssistantSuggestionChip(
                            label: 'assistant.start_new_chat'.tr(),
                            icon: Icons.add_comment_outlined,
                            onTap: cubit.startNewChat,
                          ),
                        if (turn.isFailed && canHandOff)
                          AssistantSuggestionChip(
                            label: 'assistant.talk_to_person'.tr(),
                            icon: Icons.support_agent_rounded,
                            onTap: () =>
                                AssistantHandoffDialog.confirm(context),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
      ),
    );
  }
}
