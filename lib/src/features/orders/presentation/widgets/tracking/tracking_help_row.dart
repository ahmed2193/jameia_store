import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/widgets/hero_list_row.dart';
import '../../../../../core/widgets/hero_surface_card.dart';

/// "Need help with this order?" — the way to report a missing or wrong
/// item, a late delivery or a payment question about THIS order, on its own
/// card near the foot of the page (the title bar's "Help" opens the same).
class TrackingHelpRow extends StatelessWidget {
  const TrackingHelpRow({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.gutter,
        AppSpacing.section,
        AppSpacing.gutter,
        0,
      ),
      child: HeroSurfaceCard(
        padding: EdgeInsets.zero,
        child: HeroListRow(
          title: 'orders.help_title'.tr(),
          subtitle: 'orders.help_subtitle'.tr(),
          icon: HeroIcons.customerService,
          onTap: onPressed,
        ),
      ),
    );
  }
}
