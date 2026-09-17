import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';

/// Cap on simultaneously selected like-tags (Jameia `MAX_SELECTED_LABEL_COUNT`).
const int kMaxSelectedLabels = 6;

enum OrderReviewStatus { initial, loading, loaded, error }

/// State for the write-a-review screen (`mach_pro_sailor_c_order_review`): star
/// rating, like-tags multi-select (capped at [kMaxSelectedLabels]), per-product
/// review chips, photo uploader, and the submit flag. [submittable] gates the
/// sticky CTA. The order is resolved through [OrdersRepository].
class OrderReviewState extends Equatable {
  const OrderReviewState({
    this.status = OrderReviewStatus.initial,
    this.order,
    this.stars = 0,
    this.likedTags = const {},
    this.likedProducts = const {},
    this.photoCount = 0,
    this.submitting = false,
    this.error,
  });

  final OrderReviewStatus status;
  final OrderEntity? order;
  final int stars; // 0..5
  final Set<String> likedTags;
  final Set<String> likedProducts; // item names selected for praise
  final int photoCount; // dummy uploaded photos
  final bool submitting;
  final String? error;

  /// Submit is enabled once loaded, a star rating is chosen, and not in flight.
  bool get submittable =>
      status == OrderReviewStatus.loaded && stars > 0 && !submitting;

  OrderReviewState copyWith({
    OrderReviewStatus? status,
    OrderEntity? order,
    int? stars,
    Set<String>? likedTags,
    Set<String>? likedProducts,
    int? photoCount,
    bool? submitting,
    String? error,
  }) => OrderReviewState(
    status: status ?? this.status,
    order: order ?? this.order,
    stars: stars ?? this.stars,
    likedTags: likedTags ?? this.likedTags,
    likedProducts: likedProducts ?? this.likedProducts,
    photoCount: photoCount ?? this.photoCount,
    submitting: submitting ?? this.submitting,
    error: error ?? this.error,
  );

  @override
  List<Object?> get props => [
    status,
    order,
    stars,
    likedTags,
    likedProducts,
    photoCount,
    submitting,
    error,
  ];
}

/// Page-scoped cubit — resolved via `sl<OrderReviewCubit>()` and loaded with
/// `..load(orderId)`.
class OrderReviewCubit extends Cubit<OrderReviewState>
    with SafeCubitMixin<OrderReviewState> {
  OrderReviewCubit(this._repository) : super(const OrderReviewState());

  final OrdersRepository _repository;

  static const int _maxPhotos = 6;

  Future<void> load(String orderId) async {
    safeEmit(state.copyWith(status: OrderReviewStatus.loading));
    final result = await _repository.getReviewOrder(orderId);
    result.fold(
      (failure) => safeEmit(
        state.copyWith(status: OrderReviewStatus.error, error: failure.message),
      ),
      (order) => safeEmit(
        state.copyWith(
          status: OrderReviewStatus.loaded,
          order: order,
          stars: 5,
          likedTags: const {},
          likedProducts: const {},
          photoCount: 0,
          submitting: false,
        ),
      ),
    );
  }

  void setStars(int value) {
    if (state.status != OrderReviewStatus.loaded) return;
    safeEmit(state.copyWith(stars: value));
  }

  void toggleTag(String tag) {
    if (state.status != OrderReviewStatus.loaded) return;
    final next = Set<String>.from(state.likedTags);
    if (next.contains(tag)) {
      next.remove(tag);
    } else {
      if (next.length >= kMaxSelectedLabels) return; // cap reached
      next.add(tag);
    }
    safeEmit(state.copyWith(likedTags: next));
  }

  void toggleProduct(String name) {
    if (state.status != OrderReviewStatus.loaded) return;
    final next = Set<String>.from(state.likedProducts);
    next.contains(name) ? next.remove(name) : next.add(name);
    safeEmit(state.copyWith(likedProducts: next));
  }

  void addPhoto() {
    if (state.status != OrderReviewStatus.loaded) return;
    if (state.photoCount >= _maxPhotos) return;
    safeEmit(state.copyWith(photoCount: state.photoCount + 1));
  }

  void removePhoto() {
    if (state.status != OrderReviewStatus.loaded) return;
    if (state.photoCount <= 0) return;
    safeEmit(state.copyWith(photoCount: state.photoCount - 1));
  }

  Future<void> submit() async {
    final order = state.order;
    if (order == null || !state.submittable) return;
    safeEmit(state.copyWith(submitting: true));
    final result = await _repository.submitReview(
      orderId: order.id,
      stars: state.stars,
      likedTags: state.likedTags,
      likedProducts: state.likedProducts,
      photoCount: state.photoCount,
    );
    result.fold(
      (failure) =>
          safeEmit(state.copyWith(submitting: false, error: failure.message)),
      (_) => safeEmit(state.copyWith(submitting: false)),
    );
  }
}
