import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../cubit/assistant_chat_cubit.dart';

/// Under the app bar once the chat is with support: "A person will reply
/// here · Ticket T-123".
class AssistantHandoffBanner extends StatelessWidget {
  const AssistantHandoffBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final ticket = context.select<AssistantChatCubit, String?>(
      (cubit) => cubit.state.thread.ticketNumber,
    );
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: AppColors.brandLightBg,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s10,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.support_agent_rounded,
              size: AppSize.s20,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Text(
                ticket == null || ticket.isEmpty
                    ? 'assistant.handed_off_banner_no_ticket'.tr()
                    : 'assistant.handed_off_banner'.tr(
                        namedArgs: {'number': Formatters.isolate(ticket)},
                      ),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: AppTextStyles.medium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
