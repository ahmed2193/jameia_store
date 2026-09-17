import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../domain/entities/order.dart';
import '../util/order_display.dart';
import '../../../../core/design/jameia_assets.dart';
import '../../../../core/design/jameia_icons.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/order_review_cubit.dart';

/// Like-tag suggestions surfaced under the comment field. Values are translation
/// keys (resolved via `.tr()` where the chip is rendered) and double as the
/// stable identity stored in the selected-tags set.
const List<String> kReviewLikeTags = [
  'orders.tag_great_taste',
  'orders.tag_fast_delivery',
  'orders.tag_good_value',
  'orders.tag_fresh',
  'orders.tag_well_packaged',
  'orders.tag_friendly_rider',
  'orders.tag_generous_portion',
  'orders.tag_will_reorder',
];

// ───────────────────────────────────────────────────────────────────────────
// Screen
// ───────────────────────────────────────────────────────────────────────────

/// Jameia "Write a review" screen (`mach_pro_sailor_c_order_review`).
///
/// Sections (top→bottom, matching Jameia): shop header • 5-star rating selector •
/// comment text field • quick like-tag chips (multi-select) • photo uploader •
/// per-product review chips. Sticky Submit posts the review and routes to success.
class OrderReviewPage extends StatelessWidget {
  const OrderReviewPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderReviewCubit>(
      create: (_) => sl<OrderReviewCubit>()..load(orderId),
      child: const _OrderReviewView(),
    );
  }
}

class _OrderReviewView extends StatefulWidget {
  const _OrderReviewView();

  @override
  State<_OrderReviewView> createState() => _OrderReviewViewState();
}

class _OrderReviewViewState extends State<_OrderReviewView> {
  final TextEditingController _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final cubit = context.read<OrderReviewCubit>();
    await cubit.submit();
    if (!mounted) return;
    await _showSuccess(context); // jumps to c_review_completed in Jameia
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  Future<void> _showSuccess(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: AppColors.overlayPrimary,
      builder: (_) => const _ReviewSuccessDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(JameiaIcons.back, size: 20, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'orders.write_review'.tr(),
          style: AppTextStyles.headingLarge.copyWith(
            fontWeight: AppTextStyles.bold,
          ),
        ),
      ),
      body: BlocBuilder<OrderReviewCubit, OrderReviewState>(
        builder: (context, state) {
          return switch (state.status) {
            OrderReviewStatus.initial ||
            OrderReviewStatus.loading => const AppLoader(),
            OrderReviewStatus.error => ErrorView(
              onRetry: () {},
              message: 'orders.could_not_load'.tr(),
            ),
            OrderReviewStatus.loaded => _ReviewBody(
              state: state,
              commentController: _comment,
            ),
          };
        },
      ),
      bottomNavigationBar: const _SubmitBar(),
    ).withSubmit(_onSubmit);
  }
}

/// Threads the screen's submit callback down to the sticky bar without rebuilding
/// the whole tree (the bar reads it via an inherited handle).
extension on Scaffold {
  Widget withSubmit(Future<void> Function() onSubmit) =>
      _SubmitScope(onSubmit: onSubmit, child: this);
}

class _SubmitScope extends InheritedWidget {
  const _SubmitScope({required this.onSubmit, required super.child});

  final Future<void> Function() onSubmit;

  static _SubmitScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SubmitScope>()!;

  @override
  bool updateShouldNotify(_SubmitScope oldWidget) =>
      oldWidget.onSubmit != onSubmit;
}

// ───────────────────────────────────────────────────────────────────────────
// Body
// ───────────────────────────────────────────────────────────────────────────

class _ReviewBody extends StatelessWidget {
  const _ReviewBody({required this.state, required this.commentController});

  final OrderReviewState state;
  final TextEditingController commentController;

  @override
  Widget build(BuildContext context) {
    final order = state.order!;
    // Each review block cascades in via the shared StaggerEntrance primitive
    // (reduced-motion → instant), matching the orders-list entrance grammar.
    final blocks = <Widget>[
      _ShopHeaderCard(order: order),
      const _RatingCard(),
      _CommentCard(controller: commentController),
      const _LikeTagsCard(),
      const _PhotoUploaderCard(),
      _ProductReviewCard(items: order.items),
    ];
    return ContentClamp(
      child: ListView.builder(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.s12,
          AppSpacing.s12,
          AppSpacing.s12,
          AppSpacing.s24,
        ),
        itemCount: blocks.length,
        itemBuilder: (_, i) => Padding(
          padding: EdgeInsetsDirectional.only(
            bottom: i == blocks.length - 1 ? 0 : AppSpacing.s12,
          ),
          child: StaggerEntrance(index: i, child: blocks[i]),
        ),
      ),
    );
  }
}

/// White rounded section wrapper used by every block.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.title, {this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.headingMedium.copyWith(
            fontWeight: AppTextStyles.bold,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.s2),
          Text(
            subtitle!,
            style: AppTextStyles.captionLarge.copyWith(
              color: AppColors.tertiaryText,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Shop header ──────────────────────────────────────────────────────────────

class _ShopHeaderCard extends StatelessWidget {
  const _ShopHeaderCard({required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Row(
        children: [
          JameiaImage.circle(url: order.shopLogo, size: 48),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.displayShopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingMedium.copyWith(
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  'orders.item_count_date'.tr(
                    namedArgs: {
                      'count': '${order.itemCount}',
                      'date': order.displayDate,
                    },
                  ),
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.tertiaryText,
                  ),
                ),
              ],
            ),
          ),
          Icon(JameiaIcons.shop, size: 18, color: AppColors.disabledText),
        ],
      ),
    );
  }
}

// ── Star rating selector ─────────────────────────────────────────────────────

class _RatingCard extends StatelessWidget {
  const _RatingCard();

  // Rating labels indexed by star count (0..5). Values are translation keys
  // resolved via `.tr()` where the label is rendered.
  static const List<String> _labels = [
    'orders.rating_tap',
    'orders.rating_terrible',
    'orders.rating_bad',
    'orders.rating_okay',
    'orders.rating_good',
    'orders.rating_excellent',
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        children: [
          _CardTitle('orders.how_was_order'.tr()),
          const SizedBox(height: AppSpacing.s16),
          BlocBuilder<OrderReviewCubit, OrderReviewState>(
            buildWhen: (a, b) => a.stars != b.stars,
            builder: (context, state) {
              final stars = state.stars;
              final cubit = context.read<OrderReviewCubit>();
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 1; i <= 5; i++)
                        _StarButton(
                          filled: i <= stars,
                          onTap: () => cubit.setStars(i),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    _labels[stars.clamp(0, 5)].tr(),
                    style: AppTextStyles.headingSmall.copyWith(
                      color: stars > 0
                          ? AppColors.warn
                          : AppColors.tertiaryText,
                      fontWeight: AppTextStyles.bold,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StarButton extends StatelessWidget {
  const _StarButton({required this.filled, required this.onTap});

  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s6,
        ),
        child: AnimatedScale(
          scale: filled ? 1.0 : 0.92,
          duration: MotionGuard.duration(context, AppMotion.fast),
          curve: AppMotion.standard,
          child: filled
              ? Image.asset(
                  JameiaAssets.reviewStarNormal,
                  width: 36,
                  height: 36,
                )
              : Opacity(
                  opacity: 0.25,
                  child: Image.asset(
                    JameiaAssets.reviewStarNormal,
                    width: 36,
                    height: 36,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Comment field ────────────────────────────────────────────────────────────

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            'orders.add_comment'.tr(),
            subtitle: 'orders.add_comment_sub'.tr(),
          ),
          const SizedBox(height: AppSpacing.s12),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s12),
            decoration: BoxDecoration(
              color: AppColors.mediumBackground,
              borderRadius: BorderRadius.circular(AppRadius.r4),
            ),
            child: TextField(
              controller: controller,
              maxLines: 4,
              maxLength: 200,
              style: AppTextStyles.bodyLarge,
              cursorColor: AppColors.primaryText,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                counterStyle: AppTextStyles.captionSmall.copyWith(
                  color: AppColors.tertiaryText,
                ),
                hintText: 'orders.comment_hint'.tr(),
                hintStyle: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.tertiaryText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Like-tag chips (multi-select) ────────────────────────────────────────────

class _LikeTagsCard extends StatelessWidget {
  const _LikeTagsCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row: label on start, selection-count badge on end.
          BlocBuilder<OrderReviewCubit, OrderReviewState>(
            buildWhen: (a, b) => a.likedTags.length != b.likedTags.length,
            builder: (context, state) {
              final count = state.likedTags.length;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _CardTitle(
                      'orders.what_did_you_like'.tr(),
                      subtitle: 'orders.pick_up_to'.tr(
                        namedArgs: {'max': '$kMaxSelectedLabels'},
                      ),
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: AppSpacing.s8),
                    AnimatedContainer(
                      duration: MotionGuard.duration(context, AppMotion.fast),
                      curve: AppMotion.standard,
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.s8,
                        vertical: AppSpacing.s4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandLightBg,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '$count / $kMaxSelectedLabels',
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.brandForeground,
                          fontWeight: AppTextStyles.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.s12),
          BlocBuilder<OrderReviewCubit, OrderReviewState>(
            buildWhen: (a, b) => a.likedTags != b.likedTags,
            builder: (context, state) {
              final selected = state.likedTags;
              final cubit = context.read<OrderReviewCubit>();
              return Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: [
                  for (final tag in kReviewLikeTags)
                    _SelectableChip(
                      label: tag.tr(),
                      selected: selected.contains(tag),
                      // Real Jameia two-state like PNGs: light when selected,
                      // grey when unselected (icon_review_like_light/grey).
                      leadingAsset: selected.contains(tag)
                          ? JameiaAssets.reviewLikeLight
                          : JameiaAssets.reviewLikeGrey,
                      onTap: () => cubit.toggleTag(tag),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.leadingAsset,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  /// Optional leading PNG badge (real Jameia two-state asset). Takes precedence
  /// over [icon] when supplied.
  final String? leadingAsset;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.brandForeground : AppColors.secondaryText;
    return PressScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: MotionGuard.duration(context, AppMotion.fast),
        curve: AppMotion.standard,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.mediumBackground,
          borderRadius: BorderRadius.circular(AppRadius.r1),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingAsset != null) ...[
              Image.asset(leadingAsset!, width: 16, height: 16),
              const SizedBox(width: AppSpacing.s4),
            ] else if (icon != null) ...[
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: AppSpacing.s4),
            ],
            Text(
              label,
              style: AppTextStyles.captionLarge.copyWith(
                color: fg,
                fontWeight: selected
                    ? AppTextStyles.bold
                    : AppTextStyles.medium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Photo uploader (dummy tiles) ─────────────────────────────────────────────

class _PhotoUploaderCard extends StatelessWidget {
  const _PhotoUploaderCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            'orders.add_photos'.tr(),
            subtitle: 'orders.up_to_6_photos'.tr(),
          ),
          const SizedBox(height: AppSpacing.s12),
          BlocBuilder<OrderReviewCubit, OrderReviewState>(
            buildWhen: (a, b) => a.photoCount != b.photoCount,
            builder: (context, state) {
              final count = state.photoCount;
              final cubit = context.read<OrderReviewCubit>();
              return Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: [
                  for (int i = 0; i < count; i++)
                    _PhotoTile(onRemove: cubit.removePhoto),
                  if (count < 6) _AddPhotoTile(onTap: cubit.addPhoto),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.onRemove});

  final VoidCallback onRemove;

  void _openZoom(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: AppColors.overlayPrimary,
      builder: (_) => const _PhotoZoomDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Tappable photo thumbnail — opens full-screen zoom.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openZoom(context),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.smallBackground,
                borderRadius: BorderRadius.circular(AppRadius.r4),
              ),
              child: Icon(
                JameiaIcons.image,
                size: 28,
                color: AppColors.disabledText,
              ),
            ),
          ),
          // Remove badge (top-end corner).
          PositionedDirectional(
            top: -6,
            end: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.black,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  JameiaIcons.close,
                  size: 12,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen photo viewer launched when a photo tile is tapped.
///
/// Uses [InteractiveViewer] for pinch-zoom + pan. Tap the backdrop or the
/// close button to dismiss. Shows a dummy placeholder image icon (the real
/// implementation would pass an image provider once file-picking is wired).
class _PhotoZoomDialog extends StatelessWidget {
  const _PhotoZoomDialog();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog.fullscreen(
      backgroundColor: AppColors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Dismiss on tap outside the image.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
          ),
          // Pinch-zoom image area.
          Center(
            child: RepaintBoundary(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                clipBehavior: Clip.none,
                child: Container(
                  width: size.width,
                  height: size.width, // square crop placeholder
                  color: AppColors.smallBackground,
                  child: Icon(
                    JameiaIcons.image,
                    size: 64,
                    color: AppColors.disabledText,
                  ),
                ),
              ),
            ),
          ),
          // Close button — top-end safe area.
          SafeArea(
            child: Align(
              alignment: AlignmentDirectional.topEnd,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  top: AppSpacing.s8,
                  end: AppSpacing.s12,
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.s8),
                    decoration: const BoxDecoration(
                      color: AppColors.overlayPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      JameiaIcons.close,
                      size: 18,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.mediumBackground,
          borderRadius: BorderRadius.circular(AppRadius.r4),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(JameiaIcons.camera, size: 22, color: AppColors.tertiaryText),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'orders.add'.tr(),
              style: AppTextStyles.captionSmall.copyWith(
                color: AppColors.tertiaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Per-product review chips ─────────────────────────────────────────────────

class _ProductReviewCard extends StatelessWidget {
  const _ProductReviewCard({required this.items});

  final List<OrderItemEntity> items;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            'orders.rate_items'.tr(),
            subtitle: 'orders.rate_items_sub'.tr(),
          ),
          const SizedBox(height: AppSpacing.s12),
          if (items.isEmpty)
            // Real Jameia empty-list graphic (empty_list_1gqvy22.png) when there
            // are no order items to rate.
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
                child: Column(
                  children: [
                    Image.asset(JameiaAssets.homeEmptyList, height: 96),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      'orders.no_items_to_rate'.tr(),
                      style: AppTextStyles.captionLarge.copyWith(
                        color: AppColors.tertiaryText,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            BlocBuilder<OrderReviewCubit, OrderReviewState>(
              buildWhen: (a, b) => a.likedProducts != b.likedProducts,
              builder: (context, state) {
                final selected = state.likedProducts;
                final cubit = context.read<OrderReviewCubit>();
                return Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s8,
                  children: [
                    for (final item in items)
                      _SelectableChip(
                        // Show "{qty}x {name}" for context, matching Jameia's
                        // order-item conventions; selection still keys on name.
                        label: item.qty > 1
                            ? '${item.qty}x ${item.displayName}'
                            : item.displayName,
                        selected: selected.contains(item.name),
                        icon: JameiaIcons.favorite,
                        onTap: () => cubit.toggleProduct(item.name),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

// ── Sticky submit bar ────────────────────────────────────────────────────────

class _SubmitBar extends StatelessWidget {
  const _SubmitBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderReviewCubit, OrderReviewState>(
      buildWhen: (a, b) =>
          a.submittable != b.submittable ||
          a.submitting != b.submitting ||
          a.status != b.status,
      builder: (context, state) {
        final enabled = state.submittable;
        final loading = state.submitting;
        final onSubmit = _SubmitScope.of(context).onSubmit;
        return SafeArea(
          minimum: const EdgeInsets.all(AppSpacing.s12),
          child: AppButton(
            label: 'orders.submit_review'.tr(),
            loading: loading,
            enabled: enabled,
            onPressed: enabled ? onSubmit : null,
          ),
        );
      },
    );
  }
}

// ── Success dialog (Jameia c_review_completed) ────────────────────────────────

class _ReviewSuccessDialog extends StatelessWidget {
  const _ReviewSuccessDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sheet),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: const BoxDecoration(
                color: AppColors.brandLightBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                JameiaIcons.confirm,
                size: 40,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              'orders.thanks_review'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.headingLarge.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'orders.review_success_body'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            AppButton(
              label: 'orders.done'.tr(),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
