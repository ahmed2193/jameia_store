/// What the global connection banner shows.
enum ConnectivityBannerMode {
  /// Nothing (online, or not known yet).
  hidden,

  /// "You're offline — showing what you last saw". Tap = check now.
  offline,

  /// A check the customer asked for is running.
  reconnecting,

  /// The short confirmation after the connection came back.
  backOnline,
}
