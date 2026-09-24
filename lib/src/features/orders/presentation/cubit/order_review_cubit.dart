import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/usecases/get_order_usecase.dart';
import '../../domain/usecases/submit_product_review_usecase.dart';
import 'order_review_state.dart';

/// Stars per product of a delivered order plus one comment; submit sends
/// one `POST /v1/reviews` per rated product, in order, and stops at the
/// first failure (the rated products before it are kept as sent).
class OrderReviewCubit extends Cubit<OrderReviewState>
    with SafeCubitMixin<OrderReviewState> {
  OrderReviewCubit({required this._getOrder, required this._submitReview})
    : super(const OrderReviewState());

  final GetOrderUseCase _getOrder;
  final SubmitProductReviewUseCase _submitReview;

  Future<void> load(String orderId) async {
    safeEmit(state.copyWith(status: OrderReviewStatus.loading));
    final result = await _getOrder(GetOrderParams(orderId));
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: OrderReviewStatus.error,
          failure: failure,
          failedAction: OrderReviewAction.load,
        ),
      ),
      (order) => safeEmit(
        state.copyWith(status: OrderReviewStatus.loaded, order: order),
      ),
    );
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
    if (failure != null) {
      safeEmit(
        state.copyWith(
          isSubmitting: false,
          failure: failure,
          failedAction: OrderReviewAction.submit,
        ),
      );
      return false;
    }
    safeEmit(state.copyWith(isSubmitting: false, submitted: true));
    return true;
  }
}
