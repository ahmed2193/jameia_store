import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/responsive/app_size.dart';

/// The head of the item card: the Hero store badge (the app icon, decoded
/// at the size shown), "Hero" and the branch that serves the order, and how
/// many items it holds.
class TrackingStoreRow extends StatelessWidget {
  const TrackingStoreRow({super.key, required this.order});

  final OrderEntity order;

  static const double _plate = AppSize.s40;

  @override
  Widget build(BuildContext context) {
    final branch = order.branch?.nameFor(context.locale.languageCode) ?? '';
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          vertical: AppSpacing.s12,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRadius.r5),
              ),
              child: Image.asset(
                HeroAssets.appLogo,
                width: _plate,
                height: _plate,
                fit: BoxFit.cover,
                // The source is 1024 px; decode only what the badge shows.
                cacheWidth: (_plate * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                excludeFromSemantics: true,
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'orders.store_name'.tr(),
                    style: AppTextStyles.itemTitleStrong,
                  ),
                  if (branch.isNotEmpty)
                    Text(
                      branch,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.meta,
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Text(
              'orders.item_count'.tr(
                namedArgs: {'count': '${order.itemCount}'},
              ),
              style: AppTextStyles.meta,
            ),
          ],
        ),
      ),
    );
  }
}
