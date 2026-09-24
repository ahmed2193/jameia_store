import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/jameia_address_entity.dart';
import '../../../../../core/utils/address_display.dart';

/// Tag text, the address line (city, block, street, building, floor,
/// apartment — each part only when saved) and the courier phone.
class AddressRowDetails extends StatelessWidget {
  const AddressRowDetails({super.key, required this.address});

  final JameiaAddressEntity address;

  /// "Block 7" for a number; a named part ("Fahad Al-Salem Street") as is.
  static final RegExp _startsWithDigit = RegExp(r'^\d');

  String get _line {
    String part(String key, String value) => _startsWithDigit.hasMatch(value)
        ? key.tr(namedArgs: {'value': value})
        : value;
    return [
      if (address.city.isNotEmpty) address.city,
      if (address.block.isNotEmpty) part('addr.line.block', address.block),
      if (address.street.isNotEmpty) part('addr.line.street', address.street),
      if (address.building.isNotEmpty)
        part('addr.line.building', address.building),
      if (address.floor.isNotEmpty) part('addr.line.floor', address.floor),
      if (address.apartment.isNotEmpty)
        part('addr.line.apartment', address.apartment),
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
          _line,
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
