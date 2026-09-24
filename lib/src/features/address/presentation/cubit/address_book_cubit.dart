import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/jameia_address_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/address_book.dart';
import '../../domain/entities/address_update.dart';
import '../../domain/usecases/clear_cached_addresses_usecase.dart';
import '../../domain/usecases/delete_address_usecase.dart';
import '../../domain/usecases/get_addresses_usecase.dart';
import '../../domain/usecases/get_cached_addresses_usecase.dart';
import '../../domain/usecases/save_cached_addresses_usecase.dart';
import '../../domain/usecases/update_address_usecase.dart';
import 'address_book_state.dart';

/// App-global address book (provided above `MaterialApp.router`). It is the
/// only owner of the customer's addresses, in memory and on the device:
///
///   * [start] when a session begins (OTP sign-in or a restored session) or
///     its customer becomes known: the device copy shows at once, then
///     `GET /v1/account/addresses` replaces it and is saved back. A customer
///     other than the book's owner starts the book over;
///   * [stop] when the session ends (sign-out, expiry, or a launch without a
///     session): the book is dropped from memory and from the device;
///   * [applySaved] after the edit page saved an address (POST / PATCH reply)
///     and [delete] from the list: both update memory and the device copy;
///   * [refresh] / [ensureSynced] from the list page.
///
/// The device copy is written only while a session is open and records its
/// owner, so a reply that lands after sign-out is never cached and one
/// customer's copy is never shown to another. A sync that was in flight while
/// an address was saved or deleted may be older than that change, so it
/// fetches again before it replaces the book.
class AddressBookCubit extends Cubit<AddressBookState>
    with SafeCubitMixin<AddressBookState> {
  AddressBookCubit({
    required this._getCached,
    required this._getAddresses,
    required this._updateAddress,
    required this._deleteAddress,
    required this._saveCache,
    required this._clearCache,
  }) : super(const AddressBookState());

  static const String _logName = 'AddressBookCubit';

  final GetCachedAddressesUseCase _getCached;
  final GetAddressesUseCase _getAddresses;
  final UpdateAddressUseCase _updateAddress;
  final DeleteAddressUseCase _deleteAddress;
  final SaveCachedAddressesUseCase _saveCache;
  final ClearCachedAddressesUseCase _clearCache;

  /// A customer session is open, so the book may be written to the device.
  bool _active = false;

  /// The customer the book belongs to, once known.
  String? _ownerId;

  /// What the device copy holds now (skips rewriting an identical book).
  AddressBook? _savedBook;
  String? _savedOwnerId;

  /// Bumped by [start] / [stop]: a reply from an older session is dropped.
  int _session = 0;

  /// Bumped by every change to the book that did not come from a sync.
  int _revision = 0;

  /// The sync in flight; concurrent callers join it.
  Future<void>? _syncing;

  /// Bumped by every [start] / [stop] call: a start that had to wait for the
  /// old copy to be cleared gives way to a newer call.
  int _calls = 0;

  /// Bumped by every [makeDefault]: only the latest choice is sent next and
  /// settles the book.
  int _defaultRequests = 0;

  /// [makeDefault] choices not settled yet (waiting or in flight).
  int _unsettledDefaults = 0;

  /// The default-address PATCH in flight. Choices go out one at a time, so
  /// the server applies them in the order they were made.
  Future<void>? _savingDefault;

  /// The server's default as far as the book knows: read from the book when
  /// a choice starts with none unsettled, moved by every confirmed choice.
  String? _serverDefaultId;

  Future<void> start({String? customerId}) async {
    final call = ++_calls;
    if (_active) {
      // Nothing new about the customer, or the same one: keep the session.
      if (customerId == null || customerId == _ownerId) return;
      // Another customer, or one the book was never tied to: start over.
      await _reset();
      if (call != _calls) return;
    }
    _active = true;
    _ownerId = customerId;
    if (state.isLoaded && state.isSynced) {
      // The list fetched the book before the session was known: keep it.
      _persist(state.book);
      return;
    }
    final session = _beginSession();
    safeEmit(const AddressBookState(status: AddressBookStatus.loading));
    final cached = await _getCached(const NoParams());
    if (session != _session) return;
    await cached.fold(
      (failure) async =>
          log('device copy unreadable', name: _logName, error: failure),
      (copy) async {
        if (!copy.belongsTo(customerId)) {
          // Saved for another customer: never shown, removed.
          await _clearDeviceCopy();
          return;
        }
        final book = copy.book;
        _ownerId ??= copy.ownerId;
        _savedBook = book;
        _savedOwnerId = copy.ownerId;
        if (book.isEmpty || session != _session) return;
        safeEmit(state.copyWith(status: AddressBookStatus.loaded, book: book));
      },
    );
    if (session != _session) return;
    await _sync();
  }

  Future<void> stop() async {
    _calls++;
    await _reset();
  }

  Future<void> _reset() async {
    _active = false;
    _ownerId = null;
    _savedBook = null;
    _savedOwnerId = null;
    _beginSession();
    if (state != const AddressBookState()) safeEmit(const AddressBookState());
    await _clearDeviceCopy();
  }

  /// Pull-to-refresh / retry.
  Future<void> refresh() => _sync();

  /// Syncs unless the server's copy already arrived in this session. The
  /// list page calls it when it opens (a launch offline, a guest).
  Future<void> ensureSynced() async {
    if (state.isSynced) return;
    await _sync();
  }

  /// The edit page saved [address]; the server already has it.
  void applySaved(JameiaAddressEntity address) {
    _revision++;
    _commit(
      state.copyWith(
        status: AddressBookStatus.loaded,
        book: state.book.upsert(address),
        clearLoadFailure: true,
      ),
    );
  }

  /// Makes [id] the default address (`PATCH … { isDefault: true }`), e.g. the
  /// address picked from the home delivery pill, which shows the default.
  ///
  /// Optimistic, because a default flag is cheap to put back: the book flips
  /// at once. Choices are sent one at a time, and a newer choice replaces one
  /// that is still waiting. When the latest choice is refused, the book goes
  /// back to the server's default. Returns that failure (the caller toasts
  /// it); `null` when saved, replaced by a newer choice, or nothing to do.
  Future<Failure?> makeDefault(String id) async {
    final target = state.book.byId(id);
    if (target == null || target.isDefault) return null;
    final session = _session;
    final request = ++_defaultRequests;
    if (_unsettledDefaults++ == 0) {
      _serverDefaultId = state.book.flaggedDefault?.id;
    }
    try {
      _revision++;
      _commit(state.copyWith(book: state.book.withDefault(id)));
      while (_savingDefault != null) {
        await _savingDefault;
        // Signed out, or a newer choice goes out instead of this one.
        if (session != _session || request != _defaultRequests) return null;
      }
      final saving = _updateAddress(
        UpdateAddressParams(
          id: id,
          update: const AddressUpdate(isDefault: true),
        ),
      );
      late final Future<void> tracked;
      tracked = saving.whenComplete(() {
        if (identical(_savingDefault, tracked)) _savingDefault = null;
      });
      _savingDefault = tracked;
      final result = await saving;
      if (session != _session) return null;
      _revision++;
      final saved = result.fold((_) => null, (address) => address);
      if (saved != null && saved.isDefault) _serverDefaultId = saved.id;
      // A newer choice is waiting: it goes out next and settles the book.
      if (request != _defaultRequests) return null;
      var book = state.book;
      // Not re-added when it was deleted meanwhile.
      if (saved != null && book.byId(saved.id) != null) {
        book = book.upsert(saved);
      }
      _commit(state.copyWith(book: book.withDefault(_serverDefaultId)));
      return result.fold((failure) => failure, (_) => null);
    } finally {
      if (session == _session) _unsettledDefaults--;
    }
  }

  /// Irreversible, so never optimistic: the row stays (disabled) until the
  /// server confirms, and stays untouched when it refuses.
  Future<void> delete(String id) async {
    if (state.isDeleting(id) || state.book.byId(id) == null) return;
    final session = _session;
    safeEmit(state.copyWith(deletingIds: {...state.deletingIds, id}));
    final result = await _deleteAddress(DeleteAddressParams(id: id));
    if (session != _session) return;
    final deletingIds = {...state.deletingIds}..remove(id);
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          deletingIds: deletingIds,
          failure: failure,
          failedAction: AddressBookAction.delete,
        ),
      ),
      (_) {
        _revision++;
        _commit(
          state.copyWith(
            deletingIds: deletingIds,
            book: state.book.remove(id),
            deleted: true,
          ),
        );
      },
    );
  }

  int _beginSession() {
    _revision++;
    _syncing = null;
    _savingDefault = null;
    _unsettledDefaults = 0;
    _serverDefaultId = null;
    return ++_session;
  }

  Future<void> _sync() {
    final running = _syncing;
    if (running != null) return running;
    late final Future<void> run;
    run = _syncOnce().whenComplete(() {
      if (identical(_syncing, run)) _syncing = null;
    });
    return _syncing = run;
  }

  Future<void> _syncOnce() async {
    final session = _session;
    var revision = _revision;
    safeEmit(
      state.copyWith(
        isSyncing: true,
        status: state.isLoaded
            ? AddressBookStatus.loaded
            : AddressBookStatus.loading,
      ),
    );
    var result = await _getAddresses(const NoParams());
    while (session == _session && revision != _revision) {
      revision = _revision;
      result = await _getAddresses(const NoParams());
    }
    if (session != _session) return;
    result.fold(
      (failure) => safeEmit(
        state.isLoaded
            // A book is on screen: keep it and report the failed refresh.
            ? state.copyWith(
                isSyncing: false,
                failure: failure,
                failedAction: AddressBookAction.sync,
              )
            : state.copyWith(
                isSyncing: false,
                status: failure is UnauthorizedFailure
                    ? AddressBookStatus.signedOut
                    : AddressBookStatus.error,
                loadFailure: failure,
                failure: failure,
                failedAction: AddressBookAction.sync,
              ),
      ),
      (book) => _commit(
        state.copyWith(
          status: AddressBookStatus.loaded,
          book: book,
          isSyncing: false,
          isSynced: true,
          clearLoadFailure: true,
        ),
      ),
    );
  }

  void _commit(AddressBookState next) {
    safeEmit(next);
    if (_active) _persist(next.book);
  }

  /// Writes [book] for the current owner unless the device already holds
  /// exactly that. The storage write starts synchronously, so a [stop] that
  /// follows always clears after it.
  void _persist(AddressBook book) {
    if (book == _savedBook && _ownerId == _savedOwnerId) return;
    _savedBook = book;
    _savedOwnerId = _ownerId;
    unawaited(_write(book, _ownerId));
  }

  Future<void> _write(AddressBook book, String? ownerId) async {
    final result = await _saveCache(
      SaveCachedAddressesParams(book: book, ownerId: ownerId),
    );
    result.fold((failure) {
      // Not on disk after all: the next change writes again.
      if (identical(_savedBook, book)) _savedBook = null;
      log('device copy not saved', name: _logName, error: failure);
    }, (_) {});
  }

  Future<void> _clearDeviceCopy() async {
    final result = await _clearCache(const NoParams());
    result.fold(
      (failure) =>
          log('device copy not cleared', name: _logName, error: failure),
      (_) {},
    );
  }
}
