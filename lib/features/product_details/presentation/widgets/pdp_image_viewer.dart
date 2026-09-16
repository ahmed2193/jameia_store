import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/keeta_icons.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';

/// Full-screen image zoom viewer (lightbox) — matches KeeMart's gallery viewer:
/// black backdrop, an X close + "i/n" counter at the top, a pinch-to-zoom,
/// swipeable image pager, and a bottom thumbnail filmstrip whose active tile
/// carries a green border. Tapping a thumbnail changes the main image.
///
/// Pages = the product [images] plus a trailing nutrition page when [kcal] > 0
/// (the calorie panel is part of the swipeable gallery, as in the reference).
/// Pops with the final page index so the PDP pager can sync.
class PdpImageViewer extends StatefulWidget {
  const PdpImageViewer({
    super.key,
    required this.images,
    required this.kcal,
    required this.initialIndex,
  });

  final List<String> images;
  final int kcal;
  final int initialIndex;

  @override
  State<PdpImageViewer> createState() => _PdpImageViewerState();
}

class _PdpImageViewerState extends State<PdpImageViewer> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  bool get _hasNutrition => widget.kcal > 0;
  int get _count => widget.images.length + (_hasNutrition ? 1 : 0);
  bool _isNutrition(int i) => _hasNutrition && i >= widget.images.length;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    _controller.animateToPage(
      i,
      duration: MotionGuard.duration(context, AppMotion.medium),
      curve: MotionGuard.curve(context, AppMotion.signature),
    );
  }

  void _close() => Navigator.of(context).pop(_index);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: Stack(
          children: [
            // Zoomable, swipeable pager.
            PageView.builder(
              controller: _controller,
              itemCount: _count,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                if (_isNutrition(i)) {
                  return _NutritionFull(kcal: widget.kcal);
                }
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: SizedBox.expand(
                      child: KeetaImage(
                        url: widget.images[i],
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Top bar: X close + "i/n" counter.
            PositionedDirectional(
              top: 0,
              start: 0,
              end: 0,
              child: SafeArea(
                child: SizedBox(
                  height: kToolbarHeight,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Text(
                          '${_index + 1}/$_count',
                          style: AppTextStyles.headingMedium.copyWith(
                            color: AppColors.white,
                            fontWeight: AppTextStyles.bold,
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        start: AppSpacing.s8,
                        child: IconButton(
                          onPressed: _close,
                          icon: const Icon(KeetaIcons.close,
                              size: 24, color: AppColors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom thumbnail filmstrip.
            PositionedDirectional(
              bottom: 0,
              start: 0,
              end: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
                  child: SizedBox(
                    height: 64,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpacing.s16),
                      itemCount: _count,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.s8),
                      itemBuilder: (context, i) => _Thumb(
                        active: i == _index,
                        onTap: () => _goTo(i),
                        child: _isNutrition(i)
                            ? const _NutritionThumb()
                            : KeetaImage(
                                url: widget.images[i],
                                width: 60,
                                height: 60,
                                radius: AppRadius.r6,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One filmstrip tile — white rounded card; active tile gets a green ring.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.child, required this.active, required this.onTap});
  final Widget child;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 64,
        height: 64,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.chip + 2),
          border: Border.all(
            color: active ? AppColors.martGreen : Colors.transparent,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.r6),
          child: child,
        ),
      ),
    );
  }
}

/// Nutrition thumbnail tile (no nutrition image ships, so a labelled tile).
class _NutritionThumb extends StatelessWidget {
  const _NutritionThumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.martGreenLight,
      alignment: Alignment.center,
      child: Text(
        'product.nutrition'.tr(),
        maxLines: 2,
        textAlign: TextAlign.center,
        style: AppTextStyles.captionSmall.copyWith(
          color: AppColors.martGreen,
          fontWeight: AppTextStyles.bold,
        ),
      ),
    );
  }
}

/// Full-page nutrition panel on the black backdrop (calorie readout).
class _NutritionFull extends StatelessWidget {
  const _NutritionFull({required this.kcal});
  final int kcal;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.s24),
        padding: const EdgeInsets.all(AppSpacing.s24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'product.nutrition'.tr(),
              style: AppTextStyles.headingMedium
                  .copyWith(fontWeight: AppTextStyles.bold),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              '$kcal',
              style: AppTextStyles.digits(44).copyWith(color: AppColors.martGreen),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'product.energy'.tr(),
              style:
                  AppTextStyles.bodyLarge.copyWith(color: AppColors.secondaryText),
            ),
            const SizedBox(height: AppSpacing.s16),
            const ThinDivider(),
            const SizedBox(height: AppSpacing.s12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('product.energy'.tr(),
                    style: AppTextStyles.bodyLarge
                        .copyWith(color: AppColors.primaryText)),
                const SizedBox(width: AppSpacing.s24),
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
      ),
    );
  }
}
