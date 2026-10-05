import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/widgets/hero_state_view.dart';
import 'use_my_location_row.dart';

/// The address search found nothing: "Use my current location" stays on
/// top, over "No places found" and what to try instead.
class AddressSearchEmpty extends StatelessWidget {
  const AddressSearchEmpty({super.key, required this.onMyLocation});

  final VoidCallback onMyLocation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        UseMyLocationRow(onTap: onMyLocation),
        Expanded(
          child: HeroStateView(
            art: HeroAssets.stateSearchEmpty,
            title: 'addr.search.empty_title'.tr(),
            message: 'addr.search.empty_body'.tr(),
          ),
        ),
      ],
    );
  }
}
