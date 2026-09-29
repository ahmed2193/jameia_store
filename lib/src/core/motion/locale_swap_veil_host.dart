import 'package:flutter/widgets.dart';

import 'locale_swap_veil_scope.dart';

/// The layer [LocaleSwapVeil] draws its veil on: placed in
/// `MaterialApp.router(builder:)` ABOVE the connection banner, so the veil
/// covers the whole app — the routes and the banner alike (docs/motion
/// B3-04): with the banner open, its words never flip language in plain
/// sight while the rest of the screen is veiled. Without a host the veil
/// falls back to the root overlay (under the banner).
///
/// [child] keeps its place whether or not a veil is up, so the app below is
/// never re-created by it.
class LocaleSwapVeilHost extends StatefulWidget {
  const LocaleSwapVeilHost({super.key, required this.child});

  final Widget child;

  /// The host above [context], if the app has one.
  static LocaleSwapVeilHostState? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<LocaleSwapVeilScope>()?.host;

  @override
  State<LocaleSwapVeilHost> createState() => LocaleSwapVeilHostState();
}

/// Shows and removes the one veil (see [LocaleSwapVeilHost]).
class LocaleSwapVeilHostState extends State<LocaleSwapVeilHost> {
  Widget? _veil;

  /// Puts [veil] over the whole app (replacing one already up).
  void show(Widget veil) => setState(() => _veil = veil);

  /// Takes [veil] away, if it is the one up.
  void remove(Widget veil) {
    if (!mounted || !identical(_veil, veil)) return;
    setState(() => _veil = null);
  }

  @override
  Widget build(BuildContext context) {
    final veil = _veil;
    return LocaleSwapVeilScope(
      host: this,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          if (veil != null) Positioned.fill(child: veil),
        ],
      ),
    );
  }
}
