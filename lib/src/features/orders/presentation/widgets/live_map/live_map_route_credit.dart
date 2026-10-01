import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../domain/entities/courier_route_source.dart';

/// The credit line of whoever drew the road (OpenStreetMap roads need one;
/// Google's is the logo on the map), or that the road is an estimate.
/// Nothing when no line is owed.
class LiveMapRouteCredit extends StatelessWidget {
  const LiveMapRouteCredit({super.key, required this.source});

  final CourierRouteSource source;

  @override
  Widget build(BuildContext context) {
    final key = source.creditKey;
    if (key == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.s8),
      child: Text(
        key.tr(),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.captionSmall.copyWith(
          color: AppColors.secondaryText,
        ),
      ),
    );
  }
}
