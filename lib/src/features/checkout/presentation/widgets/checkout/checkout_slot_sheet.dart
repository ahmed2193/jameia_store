import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/delivery_slot_entity.dart';
import '../../../../../core/utils/formatters.dart';
import '../../cubit/checkout_cubit.dart';
import '../../cubit/checkout_state.dart';
import 'checkout_sheet_frame.dart';
import 'checkout_slot_chip.dart';

/// Delivery windows grouped by day, in the checkout sheet shell. A tap books
/// the window in the draft and closes the sheet with it; a dismissal books
/// nothing. Full windows are shown disabled. The booked window (or
/// [preselected], the one booked when the sheet was asked for) is marked.
/// Open it with `CheckoutSheetFrame.show(checkout:)`: it reads the page's
/// cubit.
class CheckoutSlotSheet extends StatelessWidget {
  const CheckoutSlotSheet({super.key, this.preselected});

  /// The window booked when the sheet opened (Schedule picked again).
  final DeliverySlotEntity? preselected;

  /// [day] as the customer reads it: the server's name for the near days
  /// ("Today", "Tomorrow"), a date in [languageCode] for the rest.
  static String dayText(String languageCode, DeliverySlotDayEntity day) =>
      day.hasNamedLabel ? day.label : Formatters.date(languageCode, day.day);

  /// The day [slot] falls on, written like the sheet's day headers.
  static String slotDayText(
    String languageCode,
    List<DeliverySlotDayEntity> days,
    DeliverySlotEntity slot,
  ) {
    for (final day in days) {
      if (day.date == slot.date) return dayText(languageCode, day);
    }
    return Formatters.date(
      languageCode,
      slot.startAt ?? DateTime.tryParse(slot.date),
    );
  }

  /// "Tomorrow · 10:00 – 12:00": the day, then the window kept left to
  /// right (unisolated, an Arabic line swaps its ends).
  static String slotText(
    String languageCode,
    List<DeliverySlotDayEntity> days,
    DeliverySlotEntity slot,
  ) =>
      '${slotDayText(languageCode, days, slot)}${Formatters.middot}'
      '${Formatters.isolate(slot.label)}';

  /// [slotText] of the window [checkout] booked, or `null` — what the
  /// "Expected" row and the timing sheet both select.
  static String? bookedSlotText(String languageCode, CheckoutState checkout) {
    final slot = checkout.draft.slot;
    return slot == null
        ? null
        : slotText(languageCode, checkout.slotDays, slot);
  }

  @override
  Widget build(BuildContext context) {
    final days = context.select<CheckoutCubit, List<DeliverySlotDayEntity>>(
      (cubit) => cubit.state.slotDays,
    );
    final booked = context.select<CheckoutCubit, DeliverySlotEntity?>(
      (cubit) => cubit.state.draft.slot,
    );
    final marked = booked ?? preselected;
    final languageCode = context.locale.languageCode;
    return CheckoutSheetFrame(
      title: 'checkout.slot_sheet_title'.tr(),
      // shrinkWrap: the server offers a few days of windows (well under 20
      // rows) and the sheet should hug them; the frame caps its height and
      // hands the list the space left (Flexible).
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.s12,
          0,
          AppSpacing.s12,
          AppSpacing.s16,
        ),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          return Column(
            key: ValueKey<String>(day.date),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.only(
                  top: index == 0 ? 0 : AppSpacing.s16,
                  bottom: AppSpacing.s4,
                ),
                child: Text(
                  dayText(languageCode, day),
                  style: AppTextStyles.label.copyWith(
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
              ),
              Wrap(
                spacing: AppSpacing.s8,
                children: [
                  for (final slot in day.slots)
                    CheckoutSlotChip(
                      key: ValueKey<String>('${slot.date}/${slot.templateId}'),
                      // The window reads left to right even in an Arabic
                      // sheet: unisolated, bidi swaps its ends and
                      // "10:00 - 12:00" comes out as "12:00 - 10:00".
                      label: slot.isBookable
                          ? Formatters.isolate(slot.label)
                          : '${Formatters.isolate(slot.label)}'
                                '${Formatters.middot}'
                                '${'checkout.slot_full'.tr()}',
                      selected: marked != null && slot.isSameWindow(marked),
                      enabled: slot.isSelectable,
                      onTap: () {
                        context.read<CheckoutCubit>().setSlot(slot);
                        context.pop(slot);
                      },
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
