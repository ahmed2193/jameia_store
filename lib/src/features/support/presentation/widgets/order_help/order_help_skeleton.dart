import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/skeleton_bone.dart';
import '../../../../../core/widgets/skeletonized.dart';

/// The help page while its options are on the way, shaped like the form:
/// the order card, the question, a group label and its choice cards — so
/// nothing jumps when they land. Shimmers (a still fill under reduced
/// motion); not read out.
class OrderHelpSkeleton extends StatelessWidget {
  const OrderHelpSkeleton({super.key});

  static const int _choices = 5;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Skeletonized(
        loading: true,
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.gutter,
            AppSpacing.s16,
            AppSpacing.gutter,
            0,
          ),
          children: [
            const SkeletonBone(height: AppSize.s80, radius: AppRadius.media),
            const SizedBox(height: AppSpacing.section),
            const SkeletonBone(width: AppSize.s160, height: AppSize.s20),
            const SizedBox(height: AppSpacing.s16),
            const SkeletonBone(width: AppSize.s96),
            for (var i = 0; i < _choices; i++) ...[
              const SizedBox(height: AppSpacing.s8),
              const SkeletonBone(height: AppSize.s52, radius: AppRadius.card),
            ],
          ],
        ),
      ),
    );
  }
}
