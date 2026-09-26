/// Backend codes that arrive IN-BAND, inside a stream `error` frame or an
/// `error` block — not as an HTTP status, so they never become a typed
/// `Failure`. Branching on them is assistant business logic.
///
/// (`ApiStatus` holds the same strings but lives in `core/network`, which the
/// domain may not import — CLAUDE.md §12.)
abstract final class AssistantErrorCode {
  /// The conversation id is unknown or belongs to someone else (L9).
  static const String resourceNotFound = 'RESOURCE_NOT_FOUND';

  /// The reply failed server-side, e.g. "Document failed validation" (L7).
  static const String internalError = 'INTERNAL_ERROR';
}
