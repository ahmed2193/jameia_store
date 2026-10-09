import '../design/hero_assets.dart';
import '../error/failures.dart';

/// What went wrong on a screen that could not load, as the customer sees it.
/// It picks the screen's illustration ([art], a `StateArt` plate whose parts
/// act the issue out), its title and its own words
/// (`HeroStateView.failure`).
enum StateIssue {
  /// No connection, and the app knows it is offline.
  offline(
    HeroAssets.stateOffline,
    'connectivity.offline_state_title',
    'connectivity.offline_state_message',
  ),

  /// Online, but the store did not answer: the bag's plug is out.
  unreachable(
    HeroAssets.stateUnreachable,
    'issue.unreachable_title',
    'issue.unreachable_message',
  ),

  /// The answer took too long.
  timeout(
    HeroAssets.stateTimeout,
    'issue.timeout_title',
    'core.request_timeout',
  ),

  /// The store's server failed (5xx). Its own words are for its logs, not for
  /// customers, so the screen says ours.
  server(HeroAssets.stateServer, 'issue.server_title', 'issue.server_message'),

  /// The store is down for maintenance (503).
  maintenance(
    HeroAssets.stateMaintenance,
    'issue.maintenance_title',
    'issue.maintenance_message',
  ),

  /// Too many tries in a short time (429), after the automatic back-off.
  rateLimited(
    HeroAssets.stateRateLimited,
    'issue.rate_limited_title',
    'issue.rate_limited_message',
    showsServerWords: true,
  ),

  /// The route needs a signed-in customer (401): sign in.
  signedOut(
    HeroAssets.stateSignedOut,
    'issue.signed_out_title',
    'issue.signed_out_message',
    showsServerWords: true,
  ),

  /// Signed in, but not allowed here (403).
  forbidden(
    HeroAssets.stateForbidden,
    'issue.forbidden_title',
    'issue.forbidden_message',
    showsServerWords: true,
  ),

  /// The thing is gone (404).
  notFound(
    HeroAssets.stateNotFound,
    'issue.not_found_title',
    'core.not_found_message',
    showsServerWords: true,
  ),

  /// The answer came back but could not be read.
  badData(
    HeroAssets.stateBadData,
    'issue.bad_data_title',
    'issue.bad_data_message',
  ),

  /// Anything else: a request the store refused, a local read that failed.
  unexpected(
    HeroAssets.stateError,
    'core.something_went_wrong',
    'issue.unexpected_message',
    showsServerWords: true,
  );

  const StateIssue(
    this.art,
    this.titleKey,
    this.messageKey, {
    this.showsServerWords = false,
  });

  /// The `HeroAssets` state plate.
  final String art;

  /// i18n key of the title.
  final String titleKey;

  /// i18n key of the words said when the store's own are not shown.
  final String messageKey;

  /// Whether the screen says the store's own words for the failure
  /// (`Failure.serverWords`) when it sent some. Never for a transport
  /// failure (there are none) or a 5xx.
  final bool showsServerWords;

  /// `SERVICE_UNAVAILABLE`: the store is down on purpose.
  static const int serviceUnavailableStatus = 503;

  /// The first status of the server-error range.
  static const int serverErrorStatus = 500;

  /// The issue [failure] stands for. A lost connection reads as [offline]:
  /// only the live connection check (`FailureVerdictBuilder`, inside
  /// `FailureView`) can tell that the store, not the phone, is out of reach
  /// ([unreachable]).
  static StateIssue of(Failure? failure) => switch (failure) {
    NetworkFailure() => offline,
    TimeoutFailure() => timeout,
    UnauthorizedFailure() => signedOut,
    ForbiddenFailure() => forbidden,
    RateLimitedFailure() => rateLimited,
    NotFoundFailure() => notFound,
    ServerFailure(:final statusCode?)
        when statusCode == serviceUnavailableStatus =>
      maintenance,
    ServerFailure(:final statusCode?) when statusCode >= serverErrorStatus =>
      server,
    ParsingFailure() => badData,
    _ => unexpected,
  };
}
