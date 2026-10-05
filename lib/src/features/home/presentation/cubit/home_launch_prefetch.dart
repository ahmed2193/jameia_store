import 'dart:async';

import 'home_cubit.dart';

/// Home's first read, started while the splash intro plays (B1-14) so the
/// cold start costs `max(intro, load)` instead of `intro + load`: the home
/// page adopts the cubit that is already reading — or has already painted
/// its data — and shows no skeleton when the feed came in during the intro.
///
/// The catalogue answers in the request's language, and the device copy
/// that paints home at once (offline too) is kept per identity — the guest
/// or the customer — so the read waits for the splash's launch frame
/// ([start]), the customer's saved language ([localeReady]) and the session
/// restore knowing whose app this is ([identityReady]): whichever comes last
/// starts it. Read earlier, it would miss that copy (and never save the
/// reply), and a failed request would leave home on an error; so a page
/// adopted before the identity is known reads again once it is, unless it
/// has data on screen by then. A read made
/// in another language than the one [adopt] finds ([language]) is dropped,
/// never handed over; so is one the session's end made stale ([discard]) or
/// one older than [maxHold].
///
/// One per app run (a lazy singleton): the first [adopt] takes the early
/// cubit over (the page's `BlocProvider` closes it from then on); every
/// later home page builds a fresh cubit.
class HomeLaunchPrefetch {
  HomeLaunchPrefetch(
    this._create, {
    required this._language,
    this._now = DateTime.now,
  });

  /// Longest a launch read waits for its page: past it (a launch that never
  /// reached home) the page reads afresh.
  static const Duration maxHold = Duration(minutes: 1);

  final HomeCubit Function() _create;

  /// The language a request goes out in right now (`Accept-Language`).
  final String Function() _language;
  final DateTime Function() _now;

  HomeCubit? _early;
  String? _earlyLanguage;
  DateTime? _earlyAt;
  bool _requested = false;
  bool _localeReady = false;
  bool _identityReady = false;
  bool _handedOver = false;

  /// A page cubit [adopt] built before the identity was known (a splash
  /// shorter than the restore): it read without the identity's copy.
  HomeCubit? _readBlind;

  /// The splash's launch frame is on screen: read once the language and
  /// the identity are known. Nothing once the home page has taken its cubit.
  void start() {
    _requested = true;
    _maybeRead();
  }

  /// The customer's saved language is restored (the app root, once).
  void localeReady() {
    _localeReady = true;
    _maybeRead();
  }

  /// The session restore knows whose app this is — a guest, or the customer
  /// it restored (the app root, once). A page that read before it and has
  /// nothing on screen yet reads again: the identity's copy first.
  void identityReady() {
    _identityReady = true;
    final blind = _readBlind;
    _readBlind = null;
    if (blind != null && !blind.isClosed && !blind.state.load.isLoaded) {
      unawaited(blind.load());
    }
    _maybeRead();
  }

  /// The launch will not reach home with this read (the session expired
  /// under the splash): it is closed, and the page reads afresh.
  void discard() {
    _handedOver = true;
    _drop();
  }

  void _maybeRead() {
    if (!_requested || !_localeReady || !_identityReady) return;
    if (_handedOver || _early != null) return;
    _earlyLanguage = _language();
    _earlyAt = _now();
    _early = _create()..load();
  }

  /// The cubit for the home page: the one [start] began, once, when it
  /// still fits (same language, not older than [maxHold]); else a fresh
  /// one, loading.
  HomeCubit adopt() {
    final early = _early;
    final fits =
        early != null &&
        !early.isClosed &&
        _earlyLanguage == _language() &&
        _now().difference(_earlyAt ?? _now()) <= maxHold;
    _handedOver = true;
    if (fits) {
      _early = null;
      return early;
    }
    _drop();
    final fresh = _create()..load();
    if (!_identityReady) _readBlind = fresh;
    return fresh;
  }

  void _drop() {
    final early = _early;
    _early = null;
    if (early != null && !early.isClosed) unawaited(early.close());
  }
}
