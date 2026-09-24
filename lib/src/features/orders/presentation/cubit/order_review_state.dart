import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/order_review_draft.dart';

enum OrderReviewStatus { initial, loading, loaded, error }

enum OrderReviewAction { none, load, submit }

class OrderReviewState extends Equatable {
  const OrderReviewState({
    this.status = OrderReviewStatus.initial,
    this.order,
    this.draft = const OrderReviewDraft(),
    this.isSubmitting = false,
    this.submitted = false,
    this.failure,
    this.failedAction = OrderReviewAction.none,
  });

  final OrderReviewStatus status;
  final OrderEntity? order;
  final OrderReviewDraft draft;
  final bool isSubmitting;

  /// Every rated product was reviewed.
  final bool submitted;
  final Failure? failure;
  final OrderReviewAction failedAction;

  Failure? get loadFailure =>
      status == OrderReviewStatus.error &&
          failedAction == OrderReviewAction.load
      ? failure
      : null;
  bool get isSignedOut => failure is UnauthorizedFailure;
  bool get canSubmit =>
      status == OrderReviewStatus.loaded &&
      draft.canSubmit &&
      !isSubmitting &&
      !submitted;

  OrderReviewState copyWith({
    OrderReviewStatus? status,
    OrderEntity? order,
    OrderReviewDraft? draft,
    bool? isSubmitting,
    bool? submitted,
    Failure? failure,
    OrderReviewAction? failedAction,
  }) => OrderReviewState(
    status: status ?? this.status,
    order: order ?? this.order,
    draft: draft ?? this.draft,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    submitted: submitted ?? this.submitted,
    failure: failure,
    failedAction: failedAction ?? OrderReviewAction.none,
  );

  @override
  List<Object?> get props => [
    status,
    order,
    draft,
    isSubmitting,
    submitted,
    failure,
    failedAction,
  ];
}
