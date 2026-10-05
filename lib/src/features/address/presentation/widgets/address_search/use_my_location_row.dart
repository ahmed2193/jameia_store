import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import 'address_search_row.dart';
import 'suggestion_leading.dart';

/// "Use my current location" at the top of the address search: the map
/// goes to the device's position instead. It leads with the map's own
/// find-me arrow.
class UseMyLocationRow extends StatelessWidget {
  const UseMyLocationRow({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AddressSearchRow(
      onTap: onTap,
      leading: const SuggestionLeading(
        icon: HeroIcons.navigation,
        color: AppColors.brandWash,
      ),
      title: Text(
        'addr.search.use_location'.tr(),
        style: AppTextStyles.itemTitleStrong,
      ),
      subtitle: Text(
        'addr.search.use_location_hint'.tr(),
        style: AppTextStyles.meta,
      ),
    );
  }
}
