import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/address_book.dart';

/// [initial]: no session work yet (guest, or before the session is known).
/// [loading]: first sync with nothing cached. [loaded]: a book is on screen
/// (cached or synced). [error]: the first sync failed with nothing cached.
/// [signedOut]: the server refused the customer route (sign-in prompt).
enum AddressBookStatus { initial, loading, loaded, error, signedOut }

/// Which call produced [AddressBookState.failure].
enum AddressBookAction { sync, delete }

/// App-global address book state (see `AddressBookCubit`).
class AddressBookState extends Equatable {
  const AddressBookState({
    this.status = AddressBookStatus.initial,
    this.book = AddressBook.empty,
    this.isSyncing = false,
    this.isSynced = false,
    this.deletingIds = const {},
    this.loadFailure,
    this.failure,
    this.failedAction,
    this.deleted = false,
  });

  final AddressBookStatus status;
  final AddressBook book;

  /// `GET /v1/account/addresses` is in flight.
  final bool isSyncing;

  /// The book matched the server at least once in this session. A book
  /// restored from the device alone is not synced.
  final bool isSynced;

  /// Addresses whose DELETE is in flight (their row is disabled).
  final Set<String> deletingIds;

  /// Why the screen shows [AddressBookStatus.error] / `signedOut`; kept until
  /// the next successful sync.
  final Failure? loadFailure;

  /// Transient — cleared on every [copyWith]; the page toasts it.
  final Failure? failure;

  /// Transient, set together with [failure].
  final AddressBookAction? failedAction;

  /// Transient one-shot: a delete just succeeded.
  final bool deleted;

  bool get isLoaded => status == AddressBookStatus.loaded;

  bool isDeleting(String id) => deletingIds.contains(id);

  AddressBookState copyWith({
    AddressBookStatus? status,
    AddressBook? book,
    bool? isSyncing,
    bool? isSynced,
    Set<String>? deletingIds,
    Failure? loadFailure,
    bool clearLoadFailure = false,
    Failure? failure,
    AddressBookAction? failedAction,
    bool deleted = false,
  }) => AddressBookState(
    status: status ?? this.status,
    book: book ?? this.book,
    isSyncing: isSyncing ?? this.isSyncing,
    isSynced: isSynced ?? this.isSynced,
    deletingIds: deletingIds ?? this.deletingIds,
    loadFailure: clearLoadFailure ? null : (loadFailure ?? this.loadFailure),
    failure: failure,
    failedAction: failedAction,
    deleted: deleted,
  );

  @override
  List<Object?> get props => [
    status,
    book,
    isSyncing,
    isSynced,
    deletingIds,
    loadFailure,
    failure,
    failedAction,
    deleted,
  ];
}
