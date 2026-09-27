import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/data_freshness.dart';
import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../domain/entities/orders_feed.dart';

class OrdersState extends Equatable implements ScreenLoadState<OrdersState> {
  OrdersState({
    this.load = const ScreenLoad(),
    OrdersFeed? feed,
    this.isRefreshing = false,
    this.cancellingId,
  }) : feed = feed ?? OrdersFeed.empty;

  /// The first page's read, its freshness, the next page and the failure
  /// that goes with them (a failed cancel is told as the customer's action).
  @override
  final ScreenLoad load;
  final OrdersFeed feed;
  final bool isRefreshing;

  /// The order whose cancel call is in flight (one at a time).
  final String? cancellingId;

  LoadPhase get status => load.phase;
  DataFreshness get freshness => load.freshness;
  bool get isLoaded => load.isLoaded;
  bool get isLoadingMore => load.isLoadingMore;

  /// The last next page failed: paging on scroll waits for the "Load more"
  /// tap — or the connection coming back.
  bool get loadMoreFailed => load.nextPageFailed;

  /// The reason for the full-screen state; `null` while the list shows.
  Failure? get loadFailure => load.hasFailed ? load.failure : null;
  bool get isSignedOut => load.isSignedOut;
  bool get isEmpty => isLoaded && feed.isEmpty;
  bool isCancelling(String orderId) => cancellingId == orderId;

  @override
  OrdersState withLoad(ScreenLoad load) => copyWith(load: load);

  OrdersState copyWith({
    ScreenLoad? load,
    OrdersFeed? feed,
    bool? isRefreshing,
    String? cancellingId,
    bool clearCancelling = false,
  }) => OrdersState(
    load: load ?? this.load.settled(),
    feed: feed ?? this.feed,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    cancellingId: clearCancelling ? null : cancellingId ?? this.cancellingId,
  );

  @override
  List<Object?> get props => [load, feed, isRefreshing, cancellingId];
}
