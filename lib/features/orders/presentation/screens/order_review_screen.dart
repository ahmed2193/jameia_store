import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';

// ───────────────────────────────────────────────────────────────────────────
// Page cubit (constructed inline via BlocProvider — never in service locator).
// Mirrors KeeTa `mach_pro_sailor_c_order_review`: star rating, comment, like-tags
// multi-select (capped at MAX_SELECTED_LABEL_COUNT), photo uploader, and
// per-product review-chip multi-select. `submittable` gates the sticky CTA.
// ───────────────────────────────────────────────────────────────────────────

/// Cap on simultaneously selected like-tags (KeeTa `MAX_SELECTED_LABEL_COUNT`).
const int kMaxSelectedLabels = 6;

/// Like-tag suggestions surfaced under the comment field.
const List<String> kReviewLikeTags = [
  'Great taste',
  'Fast delivery',
  'Good value',
  'Fresh',
  'Well packaged',
  'Friendly rider',
  'Generous portion',
  'Will reorder',
];

sealed class OrderReviewState extends Equatable {
  const OrderReviewState();
  @override
  List<Object?> get props => [];
}

class OrderReviewLoading extends OrderReviewState {
  const OrderReviewLoading();
}

class OrderReviewError extends OrderReviewState {
  const OrderReviewError();
}

class OrderReviewLoaded extends OrderReviewState {
  const OrderReviewLoaded({
    required this.order,
    required this.stars,
    required this.likedTags,
    required this.likedProducts,
    required this.photoCount,
    required this.submitting,
  });

  final KeetaOrder order;
  final int stars; // 0..5
  final Set<String> likedTags;
  final Set<String> likedProducts; // item names selected for praise
  final int photoCount; // dummy uploaded photos
  final bool submitting;

  /// Submit is enabled once a star rating is chosen.
  bool get submittable => stars > 0 && !submitting;

  OrderReviewLoaded copyWith({
    int? stars,
    Set<String>? likedTags,
    Set<String>? likedProducts,
    int? photoCount,
    bool? submitting,
  }) =>
      OrderReviewLoaded(
        order: order,
        stars: stars ?? this.stars,
        likedTags: likedTags ?? this.likedTags,
        likedProducts: likedProducts ?? this.likedProducts,
        photoCount: photoCount ?? this.photoCount,
        submitting: submitting ?? this.submitting,
      );

  @override
  List<Object?> get props =>
      [order, stars, likedTags, likedProducts, photoCount, submitting];
}

class OrderReviewCubit extends Cubit<OrderReviewState> {
  OrderReviewCubit(this._repo) : super(const OrderReviewLoading());

  final KeetaRepository _repo;

  static const int _maxPhotos = 6;

  void load(String orderId) {
    try {
      final order = _repo.orderById(orderId);
      emit(OrderReviewLoaded(
        order: order,
        stars: 5,
        likedTags: const {},
        likedProducts: const {},
        photoCount: 0,
        submitting: false,
      ));
    } catch (_) {
      emit(const OrderReviewError());
    }
  }

  void setStars(int value) {
    final s = state;
    if (s is! OrderReviewLoaded) return;
    emit(s.copyWith(stars: value));
  }

  void toggleTag(String tag) {
    final s = state;
    if (s is! OrderReviewLoaded) return;
    final next = Set<String>.from(s.likedTags);
    if (next.contains(tag)) {
      next.remove(tag);
    } else {
      if (next.length >= kMaxSelectedLabels) return; // cap reached
      next.add(tag);
    }
    emit(s.copyWith(likedTags: next));
  }

  void toggleProduct(String name) {
    final s = state;
    if (s is! OrderReviewLoaded) return;
    final next = Set<String>.from(s.likedProducts);
    next.contains(name) ? next.remove(name) : next.add(name);
    emit(s.copyWith(likedProducts: next));
  }

  void addPhoto() {
    final s = state;
    if (s is! OrderReviewLoaded) return;
    if (s.photoCount >= _maxPhotos) return;
    emit(s.copyWith(photoCount: s.photoCount + 1));
  }

  void removePhoto() {
    final s = state;
    if (s is! OrderReviewLoaded) return;
    if (s.photoCount <= 0) return;
    emit(s.copyWith(photoCount: s.photoCount - 1));
  }

  Future<void> submit() async {
    final s = state;
    if (s is! OrderReviewLoaded || !s.submittable) return;
    emit(s.copyWith(submitting: true));
    await Future<void>.delayed(AppMotion.medium); // simulate v1/ugc/reviews/submit
    emit(s.copyWith(submitting: false));
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Screen
// ───────────────────────────────────────────────────────────────────────────

/// KeeTa "Write a review" screen (`mach_pro_sailor_c_order_review`).
///
/// Sections (top→bottom, matching KeeTa): shop header • 5-star rating selector •
/// comment text field • quick like-tag chips (multi-select) • photo uploader •
/// per-product review chips. Sticky Submit posts the review and routes to success.
class OrderReviewScreen extends StatelessWidget {
  const OrderReviewScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderReviewCubit>(
      create: (_) => OrderReviewCubit(sl<KeetaRepository>())..load(orderId),
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
    await _showSuccess(context); // jumps to c_review_completed in KeeTa
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
          icon: Icon(KeetaIcons.back, size: 20, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Write a review',
          style:
              AppTextStyles.headingLarge.copyWith(fontWeight: AppTextStyles.bold),
        ),
      ),
      body: BlocBuilder<OrderReviewCubit, OrderReviewState>(
        builder: (context, state) {
          return switch (state) {
            OrderReviewLoading() => const AppLoader(),
            OrderReviewError() => ErrorView(
                onRetry: () {},
                message: 'Could not load this order',
              ),
            OrderReviewLoaded() => _ReviewBody(
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

  final OrderReviewLoaded state;
  final TextEditingController commentController;

  @override
  Widget build(BuildContext context) {
    return ContentClamp(
      child: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.s12,
          AppSpacing.s12,
          AppSpacing.s12,
          AppSpacing.s24,
        ),
        children: [
          _ShopHeaderCard(order: state.order),
          const SizedBox(height: AppSpacing.s12),
          const _RatingCard(),
          const SizedBox(height: AppSpacing.s12),
          _CommentCard(controller: commentController),
          const SizedBox(height: AppSpacing.s12),
          const _LikeTagsCard(),
          const SizedBox(height: AppSpacing.s12),
          const _PhotoUploaderCard(),
          if (state.order.items.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            _ProductReviewCard(items: state.order.items),
          ],
        ],
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
        Text(title,
            style: AppTextStyles.headingMedium
                .copyWith(fontWeight: AppTextStyles.bold)),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.s2),
          Text(subtitle!,
              style: AppTextStyles.captionLarge
                  .copyWith(color: AppColors.tertiaryText)),
        ],
      ],
    );
  }
}

// ── Shop header ──────────────────────────────────────────────────────────────

class _ShopHeaderCard extends StatelessWidget {
  const _ShopHeaderCard({required this.order});

  final KeetaOrder order;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Row(
        children: [
          KeetaImage.circle(url: order.shopLogo, size: 48),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingMedium
                      .copyWith(fontWeight: AppTextStyles.bold),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  '${order.itemCount} items · ${order.date}',
                  style: AppTextStyles.captionLarge
                      .copyWith(color: AppColors.tertiaryText),
                ),
              ],
            ),
          ),
          Icon(KeetaIcons.shop, size: 18, color: AppColors.disabledText),
        ],
      ),
    );
  }
}

// ── Star rating selector ─────────────────────────────────────────────────────

class _RatingCard extends StatelessWidget {
  const _RatingCard();

  static const List<String> _labels = [
    'Tap to rate',
    'Terrible',
    'Bad',
    'Okay',
    'Good',
    'Excellent',
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        children: [
          const _CardTitle('How was your order?'),
          const SizedBox(height: AppSpacing.s16),
          BlocBuilder<OrderReviewCubit, OrderReviewState>(
            buildWhen: (a, b) =>
                a is OrderReviewLoaded &&
                b is OrderReviewLoaded &&
                a.stars != b.stars,
            builder: (context, state) {
              final stars = state is OrderReviewLoaded ? state.stars : 0;
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
                    _labels[stars.clamp(0, 5)],
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
        padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.s6),
        child: AnimatedScale(
          scale: filled ? 1.0 : 0.92,
          duration: AppMotion.fast,
          child: Icon(
            KeetaIcons.star,
            size: 36,
            color: filled ? AppColors.warn : AppColors.divider,
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
          const _CardTitle('Add a comment',
              subtitle: 'Share more about your experience (optional)'),
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
                counterStyle: AppTextStyles.captionSmall
                    .copyWith(color: AppColors.tertiaryText),
                hintText: 'What did you like or dislike?',
                hintStyle: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.tertiaryText),
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
          const _CardTitle('What did you like?',
              subtitle: 'Pick up to $kMaxSelectedLabels'),
          const SizedBox(height: AppSpacing.s12),
          BlocBuilder<OrderReviewCubit, OrderReviewState>(
            buildWhen: (a, b) =>
                a is OrderReviewLoaded &&
                b is OrderReviewLoaded &&
                a.likedTags != b.likedTags,
            builder: (context, state) {
              final selected =
                  state is OrderReviewLoaded ? state.likedTags : const <String>{};
              final cubit = context.read<OrderReviewCubit>();
              return Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: [
                  for (final tag in kReviewLikeTags)
                    _SelectableChip(
                      label: tag,
                      selected: selected.contains(tag),
                      icon: KeetaIcons.like,
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
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.brandForeground : AppColors.secondaryText;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
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
            if (icon != null) ...[
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: AppSpacing.s4),
            ],
            Text(
              label,
              style: AppTextStyles.captionLarge.copyWith(
                color: fg,
                fontWeight: selected ? AppTextStyles.bold : AppTextStyles.medium,
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
          const _CardTitle('Add photos', subtitle: 'Up to 6 photos'),
          const SizedBox(height: AppSpacing.s12),
          BlocBuilder<OrderReviewCubit, OrderReviewState>(
            buildWhen: (a, b) =>
                a is OrderReviewLoaded &&
                b is OrderReviewLoaded &&
                a.photoCount != b.photoCount,
            builder: (context, state) {
              final count = state is OrderReviewLoaded ? state.photoCount : 0;
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.smallBackground,
              borderRadius: BorderRadius.circular(AppRadius.r4),
            ),
            child: Icon(KeetaIcons.image,
                size: 28, color: AppColors.disabledText),
          ),
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
                child: Icon(KeetaIcons.close,
                    size: 12, color: AppColors.white),
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
            Icon(KeetaIcons.camera, size: 22, color: AppColors.tertiaryText),
            const SizedBox(height: AppSpacing.s4),
            Text('Add',
                style: AppTextStyles.captionSmall
                    .copyWith(color: AppColors.tertiaryText)),
          ],
        ),
      ),
    );
  }
}

// ── Per-product review chips ─────────────────────────────────────────────────

class _ProductReviewCard extends StatelessWidget {
  const _ProductReviewCard({required this.items});

  final List<OrderItem> items;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('Rate the items',
              subtitle: 'Tap the items you loved'),
          const SizedBox(height: AppSpacing.s12),
          BlocBuilder<OrderReviewCubit, OrderReviewState>(
            buildWhen: (a, b) =>
                a is OrderReviewLoaded &&
                b is OrderReviewLoaded &&
                a.likedProducts != b.likedProducts,
            builder: (context, state) {
              final selected = state is OrderReviewLoaded
                  ? state.likedProducts
                  : const <String>{};
              final cubit = context.read<OrderReviewCubit>();
              return Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: [
                  for (final item in items)
                    _SelectableChip(
                      label: item.name,
                      selected: selected.contains(item.name),
                      icon: KeetaIcons.favorite,
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
      buildWhen: (a, b) {
        if (a is OrderReviewLoaded && b is OrderReviewLoaded) {
          return a.submittable != b.submittable ||
              a.submitting != b.submitting;
        }
        return a.runtimeType != b.runtimeType;
      },
      builder: (context, state) {
        final loaded = state is OrderReviewLoaded ? state : null;
        final enabled = loaded?.submittable ?? false;
        final loading = loaded?.submitting ?? false;
        final onSubmit = _SubmitScope.of(context).onSubmit;
        return SafeArea(
          minimum: const EdgeInsets.all(AppSpacing.s12),
          child: AppButton(
            label: 'Submit review',
            loading: loading,
            enabled: enabled,
            onPressed: enabled ? onSubmit : null,
          ),
        );
      },
    );
  }
}

// ── Success dialog (KeeTa c_review_completed) ────────────────────────────────

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
              child: Icon(KeetaIcons.confirm,
                  size: 40, color: AppColors.success),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text('Thanks for your review!',
                textAlign: TextAlign.center,
                style: AppTextStyles.headingLarge
                    .copyWith(fontWeight: AppTextStyles.bold)),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Your feedback helps the shop and other customers.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge
                  .copyWith(color: AppColors.secondaryText),
            ),
            const SizedBox(height: AppSpacing.s24),
            AppButton(
              label: 'Done',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
