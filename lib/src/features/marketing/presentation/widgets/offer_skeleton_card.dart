import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/skeleton_bone.dart';
import 'offer_card_shell.dart';
import 'offer_reward_disc.dart';

/// An offer card while the offers load: the same shell with bones where the
/// disc, the title, the description and the reward chip land.
class OfferSkeletonCard extends StatelessWidget {
  const OfferSkeletonCard({super.key});

  static const double _titleWidth = AppSize.s160;
  static const double _lineWidth = AppSize.s220;
  static const double _chipWidth = AppSize.s90;

  @override
  Widget build(BuildContext context) {
    return const OfferCardShell(
      leading: SkeletonBone(
        width: OfferRewardDisc.size,
        height: OfferRewardDisc.size,
        radius: AppRadius.pill,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SkeletonBone(width: _titleWidth, height: AppSize.s16),
          SizedBox(height: AppSpacing.s8),
          SkeletonBone(width: _lineWidth, height: AppSize.s12),
          SizedBox(height: AppSpacing.s12),
          SkeletonBone(
            width: _chipWidth,
            height: AppSize.s28,
            radius: AppRadius.pill,
          ),
        ],
      ),
    );
  }
}
