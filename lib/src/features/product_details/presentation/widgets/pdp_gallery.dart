import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/motion/motion.dart';
import '../../../../config/routes/route_args/pdp_image_viewer_args.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/product_detail_cubit.dart';

/// The product-detail image carousel: a swipeable [PageView] over the product's
/// photos plus an optional trailing nutrition page, with a centered segmented
/// `Image i/n | Nutrition` pill that toggles between the two. Kept in sync with
/// [ProductDetailCubit] both ways: swiping reports the page, tapping the pill
/// animates the pager.
class PdpGallery extends StatefulWidget {
  const PdpGallery({super.key});

  @override
  State<PdpGallery> createState() => _PdpGalleryState();
}

class _PdpGalleryState extends State<PdpGallery> {
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Opens the full-screen zoom viewer at [index]; syncs the pager back to the
  /// page the user left the viewer on.
  Future<void> _openViewer(
    BuildContext context,
    ProductDetailCubit cubit,
    int index,
  ) async {
    final returned = await context.push<int>(
      Routes.pdpImageViewer,
      extra: PdpImageViewerArgs(
        images: cubit.gallery,
        kcal: cubit.hero.kcal,
        initialIndex: index,
      ),
    );
    if (returned != null && context.mounted) cubit.onPageChanged(returned);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProductDetailCubit>();
    final gallery = cubit.gallery;
    final total = gallery.length;

    return ColoredBox(
      color: AppColors.white,
      child: BlocConsumer<ProductDetailCubit, ProductDetailState>(
        listenWhen: (a, b) => a.imageIndex != b.imageIndex,
        listener: (context, state) {
          if (!_controller.hasClients) return;
          if (_controller.page?.round() == state.imageIndex) return;
          _controller.animateToPage(
            state.imageIndex,
            duration: MotionGuard.duration(context, AppMotion.medium),
            curve: MotionGuard.curve(context, AppMotion.signature),
          );
        },
        builder: (context, state) {
          return Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: cubit.pageCount,
                onPageChanged: cubit.onPageChanged,
                itemBuilder: (context, i) {
                  if (i < total) {
                    return GestureDetector(
                      onTap: () => _openViewer(context, cubit, i),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.s16),
                        child: JameiaImage(
                          url: gallery[i],
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  }
                  return GestureDetector(
                    onTap: () => _openViewer(context, cubit, total),
                    child: _NutritionPanel(kcal: cubit.hero.kcal),
                  );
                },
              ),
              PositionedDirectional(
                bottom: AppSpacing.s12,
                start: 0,
                end: 0,
                child: Center(
                  child: _IndicatorPill(
                    hasNutrition: cubit.hasNutrition,
                    showNutrition: state.showNutrition,
                    index: (state.imageIndex.clamp(0, total - 1)) + 1,
                    total: total,
                    onImages: cubit.showImages,
                    onNutrition: cubit.showNutritionPanel,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Bottom indicator: a segmented `Image i/n | Nutrition` pill when the product
/// has nutrition info, otherwise a plain `i/n` counter (hidden for single-image
/// products).
class _IndicatorPill extends StatelessWidget {
  const _IndicatorPill({
    required this.hasNutrition,
    required this.showNutrition,
    required this.index,
    required this.total,
    required this.onImages,
    required this.onNutrition,
  });

  final bool hasNutrition;
  final bool showNutrition;
  final int index;
  final int total;
  final VoidCallback onImages;
  final VoidCallback onNutrition;

  @override
  Widget build(BuildContext context) {
    final imageLabel = 'product.image_of'.tr(
      namedArgs: {'index': '$index', 'total': '$total'},
    );

    if (!hasNutrition) {
      if (total <= 1) return const SizedBox.shrink();
      return _PillShell(
        child: _Segment(label: imageLabel, active: true, onTap: null),
      );
    }

    return _PillShell(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(label: imageLabel, active: !showNutrition, onTap: onImages),
          _Segment(
            label: 'product.nutrition'.tr(),
            active: showNutrition,
            onTap: onNutrition,
          ),
        ],
      ),
    );
  }
}

class _PillShell extends StatelessWidget {
  const _PillShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.overlayPrimary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: child,
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.active, this.onTap});
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: MotionGuard.duration(context, AppMotion.fast),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s4,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: AppTextStyles.captionLarge.copyWith(
            color: active ? AppColors.primaryText : AppColors.white,
            fontWeight: AppTextStyles.bold,
          ),
        ),
      ),
    );
  }
}

/// Nutrition page — a large calorie readout plus an "Energy" row, derived from
/// the product's `kcal` (the only nutrition datum the catalogue carries).
class _NutritionPanel extends StatelessWidget {
  const _NutritionPanel({required this.kcal});
  final int kcal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'product.nutrition'.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.headingMedium.copyWith(
              fontWeight: AppTextStyles.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
          Center(
            child: Text(
              '$kcal',
              style: AppTextStyles.digits(
                40,
              ).copyWith(color: AppColors.martGreen),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'product.energy'.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
          const ThinDivider(),
          const SizedBox(height: AppSpacing.s12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'product.energy'.tr(),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primaryText,
                ),
              ),
              Text(
                'product.kcal'.tr(namedArgs: {'kcal': '$kcal'}),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: AppTextStyles.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
