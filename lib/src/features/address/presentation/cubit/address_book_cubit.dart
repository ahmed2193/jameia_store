import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/hero_address_entity.dart';
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
///     and [delete] from the list (optimistic, with an Undo window —
///     [undoDelete]): both update memory and the device copy;
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

  /// Addresses out of the book whose delete is in its Undo window or in
  /// flight ([delete]).
  final Map<String, _PendingDelete> _pendingDeletes =
      <String, _PendingDelete>{};

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

  /// The connection came back: a signed-in book the server has not
  /// answered for in this session syncs now (what the list shows stays).
  Future<void> onReconnected() async {
    if (!_active || state.isSynced) return;
    await _sync();
  }

  /// The edit page saved [address]; the server already has it.
  void applySaved(HeroAddressEntity address) {
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
      final Failure? failure = result.fold((failure) => failure, (_) => null);
      return failure;
    } finally {
      if (session == _session) _unsettledDefaults--;
    }
  }

  /// Optimistic (B1-17, like the cart): the address leaves the book at once
  /// ([AddressBookState.deletedId] — the page offers Undo), and the DELETE
  /// goes out when the Undo window ends: after [undoWindow], or — with
  /// [holdForUndo] — when [releaseDelete] says the Undo is gone (the page
  /// ties it to its snack's lifetime). [undoDelete] puts it back in place
  /// until then, with no request at all (a re-created address would get a
  /// new id). A refused delete puts the row back where it was and reports
  /// the failure. A second call for the same address (a double tap) does
  /// nothing. While it waits, a sync never brings the row back. The device
  /// copy changes only once the server confirmed (it keeps the row until
  /// then). Completes when the server answered, the delete was undone, or
  /// the session ended (a delete still in its window is then never sent).
  Future<void> delete(
    String id, {
    Duration undoWindow = Duration.zero,
    bool holdForUndo = false,
  }) async {
    final address = state.book.byId(id);
    if (address == null || _pendingDeletes.containsKey(id)) return;
    final session = _session;
    final pending = _PendingDelete(
      address,
      state.book.addresses.indexOf(address),
    );
    _pendingDeletes[id] = pending;
    _revision++;
    safeEmit(
      state.copyWith(
        book: state.book.remove(id),
        deletingIds: {...state.deletingIds, id},
        deletedId: id,
      ),
    );
    if (holdForUndo || undoWindow > Duration.zero) {
      if (!holdForUndo) {
        pending.timer = Timer(undoWindow, () => pending.decide(send: true));
      }
      final send = await pending.decision.future;
      if (!send || session != _session) return;
    }
    pending.sent = true;
    final result = await _deleteAddress(DeleteAddressParams(id: id));
    if (session != _session) return;
    _pendingDeletes.remove(id);
    _revision++;
    final deletingIds = {...state.deletingIds}..remove(id);
    result.fold(
      (failure) => _commit(
        state.copyWith(
          book: state.book.restore(pending.address, pending.index),
          deletingIds: deletingIds,
          failure: failure,
          failedAction: AddressBookAction.delete,
        ),
      ),
      (_) => _commit(state.copyWith(deletingIds: deletingIds)),
    );
  }

  /// The Undo for [id] is gone (its snack closed without the action): the
  /// DELETE held by `holdForUndo` goes out now. Nothing when it was undone
  /// or already sent.
  void releaseDelete(String id) {
    _pendingDeletes[id]?.decide(send: true);
  }

  /// Puts [id] back where it was while its delete waits in the Undo window.
  /// `false` when there is nothing to undo (unknown, or already sent).
  bool undoDelete(String id) {
    final pending = _pendingDeletes[id];
    if (pending == null || pending.sent) return false;
    _pendingDeletes.remove(id);
    pending.decide(send: false);
    _revision++;
    safeEmit(
      state.copyWith(
        book: state.book.restore(pending.address, pending.index),
        deletingIds: {...state.deletingIds}..remove(id),
      ),
    );
    return true;
  }

  /// [book] with the addresses whose delete the server has not confirmed
  /// back in place: what the device keeps, so an app killed in the Undo
  /// window (or mid-request) still has the row at the next launch.
  AddressBook _withPendingDeletes(AddressBook book) {
    final waiting = _pendingDeletes.values.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    var kept = book;
    for (final pending in waiting) {
      if (kept.byId(pending.address.id) == null) {
        kept = kept.restore(pending.address, pending.index);
      }
    }
    return kept;
  }

  /// [book] without the addresses whose delete is waiting or in flight: a
  /// sync that still lists them must not bring their rows back.
  AddressBook _withoutPendingDeletes(AddressBook book) {
    var shown = book;
    for (final id in _pendingDeletes.keys) {
      shown = shown.remove(id);
    }
    return shown;
  }

  @override
  Future<void> close() {
    _dropPendingDeletes();
    return super.close();
  }

  /// A session ends: deletes still in their window are never sent.
  void _dropPendingDeletes() {
    for (final pending in _pendingDeletes.values) {
      pending.decide(send: false);
    }
    _pendingDeletes.clear();
  }

  int _beginSession() {
    _dropPendingDeletes();
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
          book: _withoutPendingDeletes(book),
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
  void _persist(AddressBook shown) {
    final book = _withPendingDeletes(shown);
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

/// One address out of the book while its delete waits (see
/// [AddressBookCubit.delete]): where it was, to put it back in place.
class _PendingDelete {
  _PendingDelete(this.address, this.index);

  final HeroAddressEntity address;
  final int index;

  /// Ends the Undo window: `true` sends the DELETE.
  final Completer<bool> decision = Completer<bool>();
  Timer? timer;

  /// The DELETE went out: too late to undo.
  bool sent = false;

  void decide({required bool send}) {
    timer?.cancel();
    if (!decision.isCompleted) decision.complete(send);
  }
}
