import 'home_cubit.dart';

/// Home's first read, started while the splash intro plays (B1-14) so the
/// cold start costs `max(intro, load)` instead of `intro + load`: the home
/// page adopts the cubit that is already reading — or has already painted
/// its data — and shows no skeleton when the feed came in during the intro.
///
/// One per app run (a lazy singleton): [start] works once, and the first
/// [adopt] takes the early cubit over (the page's `BlocProvider` closes it
/// from then on); every later home page builds a fresh cubit.
class HomeLaunchPrefetch {
  HomeLaunchPrefetch(this._create);

  final HomeCubit Function() _create;

  HomeCubit? _early;
  bool _handedOver = false;

  /// Starts home's read (the device copy first, then the server's). Nothing
  /// once the home page has already taken its cubit, or a read is running.
  void start() {
    if (_handedOver || _early != null) return;
    _early = _create()..load();
  }

  /// The cubit for the home page: the one [start] began, once; else a fresh
  /// one, loading.
  HomeCubit adopt() {
    final early = _early;
    _early = null;
    _handedOver = true;
    if (early != null && !early.isClosed) return early;
    return _create()..load();
  }
}
