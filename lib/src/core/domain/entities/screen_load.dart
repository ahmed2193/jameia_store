import 'package:equatable/equatable.dart';

import '../../error/failures.dart';
import 'data_freshness.dart';
import 'data_snapshot.dart';

/// Where a screen's read stands.
enum LoadPhase { initial, loading, loaded, error }

/// Where the next page of a paged screen stands.
enum NextPageLoad { idle, loading, failed }

/// Which call a screen's [ScreenLoad.failure] came from: it decides how the
/// page tells it.
enum FailedCall {
  /// The screen's read (a first load, a refresh, a poll, one row re-read).
  read,

  /// The next page of a list: its footer tells (a retry, or "More will load
  /// when you're back").
  nextPage,

  /// Something the customer did (a submit, a cancel, "mark all read"):
  /// offline it says the action needs the internet.
  action,
}

/// The load half of every cached screen's state, written once (the offline
/// screen contract): where its read stands, how fresh the data on screen
/// is, where a next page stands, and the failure that goes with them. A
/// state holds one; its cubit moves it only with these transitions and maps
/// nothing but its own data.
class ScreenLoad extends Equatable {
  const ScreenLoad({
    this.phase = LoadPhase.initial,
    this.freshness = DataFreshness.none,
    this.nextPage = NextPageLoad.idle,
    this.failure,
    this.failedOn,
  });

  /// A new query (another sort, filter or scope): the skeleton, because the
  /// data on screen answers another question.
  static const ScreenLoad restarted = ScreenLoad(phase: LoadPhase.loading);

  final LoadPhase phase;

  /// How fresh the data on screen is (the device copy, a failed refresh …).
  final DataFreshness freshness;
  final NextPageLoad nextPage;

  /// With [LoadPhase.error], the reason for the full-screen state, kept while
  /// the phase stays `error`. Otherwise the failure of the last call:
  /// transient, dropped by the next change ([settled]), so the same failure
  /// twice is told twice.
  final Failure? failure;

  /// Set together with [failure].
  final FailedCall? failedOn;

  bool get isLoaded => phase == LoadPhase.loaded;
  bool get hasFailed => phase == LoadPhase.error;
  bool get isLoadingMore => nextPage == NextPageLoad.loading;
  bool get nextPageFailed => nextPage == NextPageLoad.failed;

  /// A customer route answered 401: the sign-in prompt, not an error.
  bool get isSignedOut => hasFailed && failure is UnauthorizedFailure;

  /// The thing asked for does not exist (any more): a "not found" state.
  bool get isNotFound => hasFailed && failure is NotFoundFailure;

  /// A failure the page tells over the data it keeps (a snack bar, or a
  /// banner nudge offline). `null` when there is none, when the whole screen
  /// shows it, or when a next page failed (its footer tells).
  Failure? get toldFailure =>
      hasFailed || failedOn == FailedCall.nextPage ? null : failure;

  /// The told failure came from something the customer did.
  bool get failedOnAction => failedOn == FailedCall.action;

  /// The data on screen is a saved copy or its read failed: a returning
  /// connection reads it again. Signed out waits for a sign-in instead, and
  /// what does not exist stays not found.
  bool get needsRefresh =>
      !isSignedOut && !isNotFound && (freshness.isStale || hasFailed);

  /// What the full-screen part of a page depends on changed: the phase, or
  /// the failure its error state shows.
  bool screenChangedFrom(ScreenLoad previous) =>
      phase != previous.phase || (hasFailed && failure != previous.failure);

  /// A read starts: the skeleton, unless data is on screen (it stays).
  ScreenLoad started() =>
      isLoaded ? settled() : const ScreenLoad(phase: LoadPhase.loading);

  /// The read answered: [snapshot]'s data is on screen now, and a next page
  /// starts over from it.
  ScreenLoad arrived(DataSnapshot<Object?> snapshot) => ScreenLoad(
    phase: LoadPhase.loaded,
    freshness: DataFreshness.of(snapshot),
  );

  /// The read failed. Data on screen stays (its freshness says the refresh
  /// failed; the failure is transient); with none it is the full-screen
  /// state.
  ScreenLoad failedWith(Failure failure) => ScreenLoad(
    phase: isLoaded ? LoadPhase.loaded : LoadPhase.error,
    freshness: freshness.failed(),
    nextPage: nextPage,
    failure: failure,
    failedOn: FailedCall.read,
  );

  /// A read nobody asked for (a background poll) failed: the data on screen
  /// stays, its freshness says the check failed, and nothing is told.
  ScreenLoad failedQuietly() => ScreenLoad(
    phase: phase,
    freshness: freshness.failed(),
    nextPage: nextPage,
  );

  /// A next page was asked for.
  ScreenLoad nextPageStarted() => _paging(NextPageLoad.loading);

  /// The next page was merged, or dropped because the list changed under it.
  ScreenLoad nextPageDone() => _paging(NextPageLoad.idle);

  /// The next page failed: the footer offers a retry (offline it waits for
  /// the connection).
  ScreenLoad nextPageFailedWith(Failure failure) => ScreenLoad(
    phase: phase,
    freshness: freshness,
    nextPage: NextPageLoad.failed,
    failure: failure,
    failedOn: FailedCall.nextPage,
  );

  /// A call beside the read failed ([on]: something the customer did, or a
  /// single row re-read): the phase, freshness and paging stay.
  ScreenLoad noted(Failure failure, {FailedCall on = FailedCall.action}) =>
      ScreenLoad(
        phase: phase,
        freshness: freshness,
        nextPage: nextPage,
        failure: failure,
        failedOn: on,
      );

  /// Any other change: a transient failure is dropped, the full-screen one
  /// stays.
  ScreenLoad settled() => failure == null || hasFailed
      ? this
      : ScreenLoad(phase: phase, freshness: freshness, nextPage: nextPage);

  ScreenLoad _paging(NextPageLoad next) {
    final kept = settled();
    return ScreenLoad(
      phase: kept.phase,
      freshness: kept.freshness,
      nextPage: next,
      failure: kept.failure,
      failedOn: kept.failedOn,
    );
  }

  @override
  List<Object?> get props => [phase, freshness, nextPage, failure, failedOn];
}
