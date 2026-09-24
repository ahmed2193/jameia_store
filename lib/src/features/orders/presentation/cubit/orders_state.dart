import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/orders_feed.dart';

enum OrdersStatus { initial, loading, loaded, error }

/// Which call a transient [OrdersState.failure] belongs to.
enum OrdersAction { none, load, refresh, loadMore, cancel, refreshOrder }

class OrdersState extends Equatable {
  OrdersState({
    this.status = OrdersStatus.initial,
    OrdersFeed? feed,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.cancellingId,
    this.failure,
    this.failedAction = OrdersAction.none,
  }) : feed = feed ?? OrdersFeed.empty;

  final OrdersStatus status;
  final OrdersFeed feed;
  final bool isRefreshing;
  final bool isLoadingMore;

  /// The order whose cancel call is in flight (one at a time).
  final String? cancellingId;

  /// Transient: set on the state that reports a failed call, cleared by the
  /// next [copyWith]; the load failure stays readable through [loadFailure].
  final Failure? failure;
  final OrdersAction failedAction;

  Failure? get loadFailure =>
      status == OrdersStatus.error &&
          (failedAction == OrdersAction.load ||
              failedAction == OrdersAction.refresh)
      ? failure
      : null;
  bool get isSignedOut => failure is UnauthorizedFailure;
  bool get isEmpty => status == OrdersStatus.loaded && feed.isEmpty;
  bool isCancelling(String orderId) => cancellingId == orderId;

  OrdersState copyWith({
    OrdersStatus? status,
    OrdersFeed? feed,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? cancellingId,
    bool clearCancelling = false,
    Failure? failure,
    OrdersAction? failedAction,
  }) => OrdersState(
    status: status ?? this.status,
    feed: feed ?? this.feed,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    cancellingId: clearCancelling ? null : cancellingId ?? this.cancellingId,
    failure: failure,
    failedAction: failedAction ?? OrdersAction.none,
  );

  @override
  List<Object?> get props => [
    status,
    feed,
    isRefreshing,
    isLoadingMore,
    cancellingId,
    failure,
    failedAction,
  ];
}
