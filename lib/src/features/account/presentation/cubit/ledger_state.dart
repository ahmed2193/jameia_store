import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/ledger.dart';
import '../../domain/entities/ledger_entry.dart';

enum LedgerStatus { initial, loading, loaded, error }

/// Which call produced [LedgerState.failure].
enum LedgerAction { load, refresh, loadMore }

/// A wallet / points history screen: the loaded [ledger] and its paging.
class LedgerState<T extends LedgerEntry> extends Equatable {
  LedgerState({
    this.status = LedgerStatus.initial,
    Ledger<T>? ledger,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.failure,
    this.failedAction,
  }) : ledger = ledger ?? Ledger<T>.empty();

  final LedgerStatus status;
  final Ledger<T> ledger;
  final bool isLoadingMore;

  /// The last next-page request failed (the footer offers a retry).
  final bool loadMoreFailed;

  /// Transient — cleared on every [copyWith]; the page localizes it.
  final Failure? failure;

  /// Transient, set together with [failure].
  final LedgerAction? failedAction;

  bool get isLoaded => status == LedgerStatus.loaded;

  /// The customer route answered 401: the sign-in prompt, not an error.
  bool get isSignedOut =>
      status == LedgerStatus.error && failure is UnauthorizedFailure;

  LedgerState<T> copyWith({
    LedgerStatus? status,
    Ledger<T>? ledger,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    Failure? failure,
    LedgerAction? failedAction,
  }) => LedgerState<T>(
    status: status ?? this.status,
    ledger: ledger ?? this.ledger,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    failure: failure,
    failedAction: failedAction,
  );

  @override
  List<Object?> get props => [
    status,
    ledger,
    isLoadingMore,
    loadMoreFailed,
    failure,
    failedAction,
  ];
}
