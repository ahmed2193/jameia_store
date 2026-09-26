import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/domain/entities/delivery_slot_entity.dart';
import '../../../../../core/widgets/jameia_sheet_header.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_slot_chip.dart';

/// Delivery windows grouped by day; a tap books the slot in the draft and
/// closes the sheet. Full windows are shown disabled. Never taller than
/// [_maxHeightFactor] of the screen.
class CheckoutSlotSheet extends StatelessWidget {
  const CheckoutSlotSheet({super.key});

  static const double _maxHeightFactor = 0.85;

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
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * _maxHeightFactor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            JameiaSheetHeader(title: 'checkout.slot_sheet_title'.tr()),
            Flexible(
              // shrinkWrap: the server offers a few days of windows (well
              // under 20 rows), and the sheet should hug them, not fill the
              // screen; the height cap above keeps it bounded.
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.gutter,
                  0,
                  AppSpacing.gutter,
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
                        padding: const EdgeInsetsDirectional.only(
                          top: AppSpacing.s16,
                          bottom: AppSpacing.s8,
                        ),
                        child: Text(
                          day.hasNamedLabel
                              ? day.label
                              : Formatters.date(languageCode, day.day),
                          style: AppTextStyles.itemTitleStrong,
                        ),
                      ),
                      Wrap(
                        spacing: AppSpacing.s8,
                        runSpacing: AppSpacing.s8,
                        children: [
                          for (final slot in day.slots)
                            CheckoutSlotChip(
                              key: ValueKey<String>(
                                '${slot.date}/${slot.templateId}',
                              ),
                              // The window reads left to right even in an
                              // Arabic sheet: unisolated, bidi swaps its
                              // ends and "10:00 - 12:00" comes out as
                              // "12:00 - 10:00".
                              label: slot.isBookable
                                  ? Formatters.isolate(slot.label)
                                  : '${Formatters.isolate(slot.label)} · '
                                        '${'checkout.slot_full'.tr()}',
                              selected: slot == selected,
                              enabled: slot.isSelectable,
                              onTap: () {
                                context.read<CheckoutCubit>().setSlot(slot);
                                context.pop();
                              },
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
