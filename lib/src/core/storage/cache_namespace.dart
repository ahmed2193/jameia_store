/// Whose data a cached response is.
enum CacheScope {
  /// The same for everyone (the catalogue): kept across sign-in / sign-out.
  public,

  /// Personalised for whoever is using the app — the signed-in customer, or
  /// the guest (`/v1/home`, `/v1/init` answer per Bearer / guest cart token).
  owner,

  /// A signed-in customer's own data (orders, notifications, wallet).
  /// Nothing is cached for a guest.
  customer,
}

/// One kind of cached response and its policy (API SPEC, "What gets cached").
class CacheNamespace {
  const CacheNamespace(
    this.name, {
    required this.scope,
    required this.freshFor,
    required this.maxAge,
    this.version = 1,
    this.maxEntries = defaultMaxEntries,
  });

  /// Two languages × (guest + a customer) for a single-screen namespace.
  static const int defaultMaxEntries = 4;

  /// `home.feed`, `catalog.products` … — also the entry's folder.
  final String name;
  final CacheScope scope;

  /// A copy younger than this is shown WITHOUT asking the network (a pull to
  /// refresh still does).
  final Duration freshFor;

  /// A copy older than this is never shown.
  final Duration maxAge;

  /// Bump when the DTO this namespace re-parses changes shape: every older
  /// entry becomes a miss.
  final int version;

  /// Most entries kept; the oldest go first.
  final int maxEntries;
}
