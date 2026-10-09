import 'package:easy_localization/easy_localization.dart';

import '../error/failures.dart';

/// What to show the user for a [Failure].
///
/// Backend failures already carry a message localized by `Accept-Language`;
/// transport / local failures carry English fallbacks, so they map to i18n
/// keys here — one place, reused by every feature's error UI.
extension FailureMessage on Failure {
  String get localizedMessage =>
      serverWords ??
      switch (this) {
        NetworkFailure() => 'core.no_internet'.tr(),
        TimeoutFailure() => 'core.request_timeout'.tr(),
        ValidationFailure() => 'core.invalid_input'.tr(),
        _ => 'core.something_went_wrong'.tr(),
      };

  /// The store's own words for this failure — its `error.message`, already
  /// in the customer's language — or `null` when it said nothing a customer
  /// can read: a transport or local failure, or a reply without the envelope
  /// (a proxy's error page arrives with an empty message).
  String? get serverWords => switch (this) {
    ServerFailure(:final message) ||
    UnauthorizedFailure(:final message) ||
    ForbiddenFailure(:final message) ||
    RateLimitedFailure(:final message) when message.isNotEmpty => message,
    _ => null,
  };
}
