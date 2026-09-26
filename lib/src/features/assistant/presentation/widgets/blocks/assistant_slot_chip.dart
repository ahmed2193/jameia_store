import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/delivery_slot_entity.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';

/// One delivery window. The time reads left to right in both languages; a
/// full window says so and does nothing.
class AssistantSlotChip extends StatelessWidget {
  const AssistantSlotChip({super.key, required this.slot, this.onTap});

  final DeliverySlotEntity slot;

  /// `null` → not tappable (full, or the chat is busy).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bookable = slot.isBookable;
    final time = Formatters.isolate(slot.label);
    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      child: Material(
        color: bookable ? AppColors.white : AppColors.smallBackground,
        shape: StadiumBorder(
          side: BorderSide(
            color: bookable ? AppColors.brandTileBorder : AppColors.divider,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s14,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSize.s48),
              child: Center(
                widthFactor: 1,
                child: Text(
                  bookable ? time : '$time · ${'assistant.slot_full'.tr()}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: bookable
                        ? AppColors.primaryText
                        : AppColors.disabledText,
                    fontWeight: AppTextStyles.medium,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
