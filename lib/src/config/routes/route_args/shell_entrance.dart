/// How the main shell was reached, passed as the `extra` of
/// `context.go(Routes.shell, …)` when it changes the entrance motion.
enum ShellEntrance {
  /// From the brand splash: the app fades in over the splash (Hero-style)
  /// instead of sliding up like a pushed page.
  splash,
}
