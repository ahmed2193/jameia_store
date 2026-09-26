import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/delivery_slot_entity.dart';
import 'assistant_card_frame.dart';
import 'assistant_slot_day_row.dart';

/// `delivery_slots`: the open windows per day. A window is not booked here
/// (checkout books it); tapping one asks the assistant for it.
class AssistantDeliverySlotsCard extends StatelessWidget {
  const AssistantDeliverySlotsCard({super.key, required this.days});

  final List<DeliverySlotDayEntity> days;

  @override
  Widget build(BuildContext context) {
    return AssistantCardFrame(
      title: 'assistant.slots_title'.tr(),
      icon: Icons.schedule_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final day in days)
            AssistantSlotDayRow(key: ValueKey(day.date), day: day),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'assistant.slots_footnote'.tr(),
            style: AppTextStyles.captionMedium.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
