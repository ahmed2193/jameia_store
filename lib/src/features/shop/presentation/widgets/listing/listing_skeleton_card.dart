import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/skeleton_bone.dart';

/// The bones of one product card while a listing loads: the square picture,
/// two lines of name and the price, laid out like the real card.
class ListingSkeletonCard extends StatelessWidget {
  const ListingSkeletonCard({super.key, required this.width});

  final double width;

  static const double _nameShare = 0.85;
  static const double _shortNameShare = 0.55;
  static const double _priceShare = 0.4;
  static const double _line = AppSize.s12;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SkeletonBone(width: width, height: width, radius: AppRadius.card),
          const SizedBox(height: AppSpacing.s8),
          SkeletonBone(width: width * _nameShare, height: _line),
          const SizedBox(height: AppSpacing.s6),
          SkeletonBone(width: width * _shortNameShare, height: _line),
          const SizedBox(height: AppSpacing.s8),
          SkeletonBone(width: width * _priceShare, height: AppSize.s14),
        ],
      ),
    );
  }
}
