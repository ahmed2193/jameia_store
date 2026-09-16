import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../motion/motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Shimmer SKELETON wrapper. Feed a static stand-in layout that mirrors the real
/// content; while [loading] is true it renders bones with KeeTa's shimmer sweep
/// ([AppMotion.shimmer], ~1.1s). Reduced-motion → a solid (non-sweeping) bone so
/// the screen still reads as "loading" without movement.
class Skeletonized extends StatelessWidget {
  const Skeletonized({super.key, required this.loading, required this.child});

  final bool loading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = MotionGuard.reduced(context);
    return Skeletonizer(
      enabled: loading,
      effect: reduced
          ? SolidColorEffect(color: AppColors.divider)
          : ShimmerEffect(
              baseColor: AppColors.divider,
              highlightColor: AppColors.smallBackground,
              duration: AppMotion.shimmer,
            ),
      child: child,
    );
  }
}

/// A single grey bone block — building unit for the skeleton layouts below.
class SkeletonBone extends StatelessWidget {
  const SkeletonBone({
    super.key,
    this.width,
    this.height = 14,
    this.radius = AppRadius.r6,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Shop-menu / product row skeleton (thumbnail + two text lines + price). Matches
/// `ProductRow` so the swap to real content is seamless.
class ProductRowSkeleton extends StatelessWidget {
  const ProductRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBone(width: 92, height: 92, radius: AppRadius.r4),
          SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBone(width: 160, height: 16),
                SizedBox(height: AppSpacing.s8),
                SkeletonBone(width: 220, height: 12),
                SizedBox(height: AppSpacing.s6),
                SkeletonBone(width: 90, height: 12),
                SizedBox(height: AppSpacing.s12),
                SkeletonBone(width: 70, height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic list skeleton — N [ProductRowSkeleton]s. Used for shop menu, coupons,
/// orders, search results.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List<Widget>.generate(count, (_) => const ProductRowSkeleton()),
    );
  }
}

/// Home-feed skeleton: a hero banner bone + a row of king-kong circles + a couple
/// of shop-card bones.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pageMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBone(height: 120, radius: AppRadius.r3),
          const SizedBox(height: AppSpacing.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List<Widget>.generate(
              5,
              (_) => const Column(
                children: [
                  SkeletonBone(width: 48, height: 48, radius: 24),
                  SizedBox(height: AppSpacing.s6),
                  SkeletonBone(width: 40, height: 10),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
          const SkeletonBone(height: 150, radius: AppRadius.r4),
          const SizedBox(height: AppSpacing.s8),
          const SkeletonBone(width: 180, height: 16),
          const SizedBox(height: AppSpacing.s6),
          const SkeletonBone(width: 120, height: 12),
        ],
      ),
    );
  }
}

/// Shop-menu skeleton — header bone + a list of product rows.
class ShopMenuSkeleton extends StatelessWidget {
  const ShopMenuSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBone(height: 180, radius: 0),
        SizedBox(height: AppSpacing.s12),
        ListSkeleton(count: 5),
      ],
    );
  }
}

/// Orders-list skeleton.
class OrdersSkeleton extends StatelessWidget {
  const OrdersSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const ListSkeleton(count: 4);
}

/// Coupons-list skeleton — ticket-shaped bones.
// (text styles intentionally unused here — skeletons render bones, not type.)
class CouponsSkeleton extends StatelessWidget {
  const CouponsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pageMargin),
      child: Column(
        children: List<Widget>.generate(
          4,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.s12),
            child: SkeletonBone(height: 96, radius: AppRadius.r3),
          ),
        ),
      ),
    );
  }
}
