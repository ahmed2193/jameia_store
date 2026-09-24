import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/delivery_slot_entity.dart';
import '../../cubit/checkout_cubit.dart';

/// Delivery windows grouped by day; a tap books the slot in the draft and
/// closes the sheet. Full windows are shown disabled.
class CheckoutSlotSheet extends StatelessWidget {
  const CheckoutSlotSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final days = context.select<CheckoutCubit, List<DeliverySlotDayEntity>>(
      (cubit) => cubit.state.slotDays,
    );
    final selected = context.select<CheckoutCubit, DeliverySlotEntity?>(
      (cubit) => cubit.state.draft.slot,
    );
    final languageCode = context.locale.languageCode;
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Text(
              'checkout.slot_sheet_title'.tr(),
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.primaryText,
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s16,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                return Column(
                  key: ValueKey<String>(day.date),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        top: AppSpacing.s8,
                        bottom: AppSpacing.s8,
                      ),
                      child: Text(
                        day.hasNamedLabel
                            ? day.label
                            : Formatters.date(languageCode, day.day),
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.primaryText,
                          fontWeight: AppTextStyles.medium,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        for (final slot in day.slots)
                          ChoiceChip(
                            key: ValueKey<String>(
                              '${slot.date}/${slot.templateId}',
                            ),
                            label: Text(
                              // The window reads left to right even in an
                              // Arabic sheet: unisolated, bidi swaps its
                              // ends and "10:00 - 12:00" comes out as
                              // "12:00 - 10:00".
                              slot.isBookable
                                  ? Formatters.isolate(slot.label)
                                  : '${Formatters.isolate(slot.label)} · '
                                        '${'checkout.slot_full'.tr()}',
                            ),
                            selected: slot == selected,
                            onSelected: slot.isSelectable
                                ? (_) {
                                    context.read<CheckoutCubit>().setSlot(slot);
                                    context.pop();
                                  }
                                : null,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s8),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
