import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../../../core/utils/performance/snapshot_loader_mixin.dart';
import '../../domain/entities/order_review_draft.dart';
import '../../domain/usecases/submit_product_review_usecase.dart';
import '../../domain/usecases/watch_order_usecase.dart';
import 'order_review_state.dart';

/// Stars per product of a delivered order plus one comment; submit sends
/// one `POST /v1/reviews` per rated product, in order, and stops at the
/// first failure (the rated products before it are kept as sent). The order
/// saved on the device shows at once (offline too); a failed submit never
/// loses the stars or the comment.
class OrderReviewCubit extends Cubit<OrderReviewState>
    with
        SafeCubitMixin<OrderReviewState>,
        SnapshotLoaderMixin<OrderReviewState>,
        ScreenLoaderMixin<OrderReviewState> {
  OrderReviewCubit({required this._watchOrder, required this._submitReview})
    : super(const OrderReviewState());

  final WatchOrderUseCase _watchOrder;
  final SubmitProductReviewUseCase _submitReview;
  String _orderId = '';

  /// Stars chosen on the order page, applied once to every product when the
  /// order first arrives; 0 = none.
  int _initialRating = 0;

  /// First load or retry: the loader only while there is no order yet.
  /// [initialRating] (1–5): the stars the customer already tapped on the
  /// order page — every product starts there, each can still be changed.
  Future<void> load(String orderId, {int initialRating = 0}) {
    _orderId = orderId;
    _initialRating = initialRating;
    showLoading();
    return _read(forceRefresh: false);
  }

  /// The server's order (the reconnect refresh of a saved or failed one).
  @override
  Future<void> refresh() =>
      _orderId.isEmpty ? Future<void>.value() : _read(forceRefresh: true);

  Future<void> _read({required bool forceRefresh}) => readScreen<OrderEntity>(
    _watchOrder(WatchOrderParams(_orderId, forceRefresh: forceRefresh)),
    show: (state, snapshot) => state.copyWith(
      order: snapshot.data,
      draft: _prefilled(state.draft, snapshot.data),
    ),
  );

  /// The draft with the order page's stars on every product, the first time
  /// an order arrives; later reads keep the customer's own changes.
  OrderReviewDraft _prefilled(OrderReviewDraft draft, OrderEntity order) {
    final rating = _initialRating;
    if (rating == 0) return draft;
    _initialRating = 0;
    return draft.rateUnrated([
      for (final line in order.lines) line.productId,
    ], rating);
  }

  void rate(String productId, int stars) =>
      safeEmit(state.copyWith(draft: state.draft.rate(productId, stars)));

  void setComment(String comment) =>
      safeEmit(state.copyWith(draft: state.draft.withComment(comment)));

  Future<bool> submit() async {
    final order = state.order;
    if (order == null || !state.canSubmit) return false;
    safeEmit(state.copyWith(isSubmitting: true));
    Failure? failure;
    for (final request in state.draft.toRequests(order.id)) {
      final result = await _submitReview(SubmitProductReviewParams(request));
      final sent = result.fold((error) {
        failure = error;
        return false;
      }, (_) => true);
      if (!sent) break;
      // Marked on the live draft: a product rated while the loop ran keeps
      // its stars, and the ones already accepted keep theirs.
      safeEmit(state.copyWith(draft: state.draft.markSent(request.productId)));
    }
    final failed = failure;
    if (failed != null) {
      safeEmit(
        state.copyWith(isSubmitting: false, load: state.load.noted(failed)),
      );
      return false;
    }
    safeEmit(state.copyWith(isSubmitting: false, submitted: true));
    return true;
  }
}
