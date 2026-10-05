import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/hero_address_entity.dart';
import '../../../../../core/utils/address_display.dart';

/// Tag text, the address line (city, block, street, building, floor,
/// apartment — each part only when saved) and the courier phone.
class AddressRowDetails extends StatelessWidget {
  const AddressRowDetails({super.key, required this.address});

  final HeroAddressEntity address;

  /// Each part as every address line writes it ([addressLinePart]).
  String _line({required bool rtl}) {
    String part(AddressLinePart part, String value) =>
        addressLinePart(part, value, rtl: rtl);
    return [
      if (address.city.isNotEmpty) addressLineName(address.city, rtl: rtl),
      if (address.block.isNotEmpty) part(AddressLinePart.block, address.block),
      if (address.street.isNotEmpty)
        part(AddressLinePart.street, address.street),
      if (address.building.isNotEmpty)
        part(AddressLinePart.building, address.building),
      if (address.floor.isNotEmpty) part(AddressLinePart.floor, address.floor),
      if (address.apartment.isNotEmpty)
        part(AddressLinePart.apartment, address.apartment),
    ].join('addr.line.separator'.tr());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          address.tagText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.captionMedium.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          _line(rtl: Directionality.of(context) == TextDirection.rtl),
          style: AppTextStyles.headingSmall.copyWith(
            fontWeight: AppTextStyles.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          address.phone.isEmpty ? 'addr.no_contact'.tr() : address.phone,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          // A phone number reads left-to-right in Arabic too.
          textDirection: address.phone.isEmpty ? null : TextDirection.ltr,
          style: AppTextStyles.captionLarge.copyWith(
            color: AppColors.labelGrey,
          ),
        ),
      ],
    );
  }
}
