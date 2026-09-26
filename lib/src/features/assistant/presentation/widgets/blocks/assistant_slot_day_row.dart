import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/delivery_slot_entity.dart';
import '../../../../../core/utils/formatters.dart';
import '../../cubit/assistant_chat_cubit.dart';
import 'assistant_slot_chip.dart';

/// One day: its name ("Today", or the date written in the customer's
/// language) and its windows. A tap sends "I would like delivery on …" while
/// the chat can take a message.
class AssistantSlotDayRow extends StatelessWidget {
  const AssistantSlotDayRow({super.key, required this.day});

  final DeliverySlotDayEntity day;

  @override
  Widget build(BuildContext context) {
    final canSend = context.select<AssistantChatCubit, bool>(
      (cubit) => cubit.state.canSend,
    );
    final dayName = day.hasNamedLabel
        ? day.label
        : Formatters.date(context.locale.languageCode, day.day);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayName,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryText,
              fontWeight: AppTextStyles.medium,
            ),
          ),
          const SizedBox(height: AppSpacing.s6),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (final slot in day.slots)
                AssistantSlotChip(
                  key: ValueKey(
                    '${slot.date}/${slot.templateId}/${slot.start}',
                  ),
                  slot: slot,
                  onTap: canSend && slot.isBookable
                      ? () => context.read<AssistantChatCubit>().send(
                          'assistant.slot_prompt'.tr(
                            namedArgs: {'day': dayName, 'time': slot.label},
                          ),
                        )
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
