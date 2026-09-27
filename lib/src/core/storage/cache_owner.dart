/// Whose private responses the on-device cache belongs to right now.
///
/// Kept in step with the session by the auth local datasource — the one
/// writer of the signed-in customer's device copy: it says [signedIn] when it
/// saves or reads that copy and [signedOut] when it clears it. Until either
/// happens (launch, before the session restore resolved) the identity is
/// unknown and nothing personal is read or written.
class CacheOwner {
  /// The identity of a signed-out app (guest cart, guest assistant).
  static const String guest = 'guest';

  static const String _customerPrefix = 'c:';

  String? _current;

  /// [guest], a customer identity, or `null` while unknown.
  String? get current => _current;

  /// The signed-in customer's identity, or `null` (guest / unknown).
  String? get customer {
    final current = _current;
    return current != null && current != guest ? current : null;
  }

  void signedIn(String customerId) => _current = '$_customerPrefix$customerId';

  void signedOut() => _current = guest;
}
