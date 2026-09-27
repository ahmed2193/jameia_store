/// What a live connection check tells a screen whose load failed in
/// transport while the app did not read as offline.
enum ConnectionRecheck {
  /// No connection: the screen says so and loads when it returns.
  offline,

  /// The connection is there: load again now. Loads that failed together
  /// (a page and its reviews, the tabs of the shell) all go again.
  retry,

  /// The connection is there, but this load already went again by itself
  /// lately and failed: the store did not answer. The screen shows its
  /// error with a retry instead of looping.
  reachable,
}
