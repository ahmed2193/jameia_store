import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// "Running a little late · expected around 8:45 PM" once the estimate has
/// passed and the order is still moving — said plainly, on a soft amber
/// plate (the amber is the icon's; the text stays ink for contrast).
class TrackingLateNote extends StatelessWidget {
  const TrackingLateNote({
    super.key,
    required this.expectedAt,
    this.pickup = false,
  });

  final DateTime expectedAt;
  final bool pickup;

  @override
  Widget build(BuildContext context) {
    final time = Formatters.isolate(
      Formatters.clock(context.locale.languageCode, expectedAt),
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.warnBg,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.r5)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8,
        ),
        child: Row(
          children: [
            const HeroIcon(
              HeroIcons.clock,
              size: AppSize.s18,
              color: AppColors.warn,
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Text(
                (pickup ? 'orders.eta_late_pickup' : 'orders.eta_late').tr(
                  namedArgs: {'time': time},
                ),
                style: AppTextStyles.label,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
