import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/widgets/hero_tag.dart';
import 'tracking_person_avatar.dart';

/// One person handling the order: their disc, their name and what they do
/// for the customer ("Your picker", "Your driver"), and a "Now" tag while it
/// is their turn. Read out as one node.
class TrackingPersonRow extends StatelessWidget {
  const TrackingPersonRow({
    super.key,
    required this.name,
    required this.roleKey,
    required this.roleIcon,
    this.active = false,
  });

  final String name;

  /// i18n key of the role line.
  final String roleKey;
  final IconData roleIcon;

  /// It is this person's turn (picking now, on the way now).
  final bool active;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        children: [
          TrackingPersonAvatar(name: name, role: roleIcon),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.itemTitleStrong,
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(roleKey.tr(), style: AppTextStyles.meta),
              ],
            ),
          ),
          if (active) ...[
            const SizedBox(width: AppSpacing.s8),
            HeroTag(label: 'orders.person_now'.tr(), pill: true),
          ],
        ],
      ),
    );
  }
}
