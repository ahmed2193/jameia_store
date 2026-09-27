import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../domain/entities/order_review_draft.dart';

class OrderReviewState extends Equatable
    implements ScreenLoadState<OrderReviewState> {
  const OrderReviewState({
    this.load = const ScreenLoad(),
    this.order,
    this.draft = const OrderReviewDraft(),
    this.isSubmitting = false,
    this.submitted = false,
  });

  /// The order's read and the failure that goes with it (a failed submit is
  /// told as the customer's action).
  @override
  final ScreenLoad load;
  final OrderEntity? order;
  final OrderReviewDraft draft;
  final bool isSubmitting;

  /// Every rated product was reviewed.
  final bool submitted;

  LoadPhase get status => load.phase;

  /// The reason for the full-screen state; `null` while the order shows.
  Failure? get loadFailure => load.hasFailed ? load.failure : null;
  bool get isSignedOut => load.isSignedOut;
  bool get canSubmit =>
      load.isLoaded && draft.canSubmit && !isSubmitting && !submitted;

  @override
  OrderReviewState withLoad(ScreenLoad load) => copyWith(load: load);

  OrderReviewState copyWith({
    ScreenLoad? load,
    OrderEntity? order,
    OrderReviewDraft? draft,
    bool? isSubmitting,
    bool? submitted,
  }) => OrderReviewState(
    load: load ?? this.load.settled(),
    order: order ?? this.order,
    draft: draft ?? this.draft,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    submitted: submitted ?? this.submitted,
  );

  @override
  List<Object?> get props => [load, order, draft, isSubmitting, submitted];
}
