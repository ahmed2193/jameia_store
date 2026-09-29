import 'shell_tabs.dart';

/// `extra` of every `context.go(Routes.shell, …)`: a NEW instance per
/// arrival. The shell route always builds the same page type under the same
/// key, so a `go` back to a shell already in the stack keeps it — its tabs
/// keep their scroll and state — instead of building a new one; the fresh
/// arrival tells it which [tab] to show (Home, as a new shell would).
class ShellArrival {
  ShellArrival({this.tab = ShellTab.home});

  final ShellTab tab;
}
