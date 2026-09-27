import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../cubit/connectivity_banner_mode.dart';
import 'connectivity_bar.dart';

/// Lays the banner out ABOVE the app, pushing it down instead of covering
/// it. While the bar is on screen it also paints under the status bar, so the
/// app below loses its top inset (page `SafeArea`s must not pad twice).
///
/// The inset moves only twice per appearance, never per animation frame: it
/// is taken when the bar starts to open — the bar's status-bar strip takes
/// exactly its place, so nothing moves — and given back once the bar has
/// fully closed. Between those two moments only the bar's own height
/// animates, pushing the app down and letting it back up.
class ConnectivityBannerFrame extends StatefulWidget {
  const ConnectivityBannerFrame({
    super.key,
    required this.mode,
    required this.nudges,
    required this.child,
  });

  final ConnectivityBannerMode mode;

  /// Counts the nudges; each new value shakes the bar once.
  final ValueListenable<int> nudges;
  final Widget child;

  @override
  State<ConnectivityBannerFrame> createState() =>
      _ConnectivityBannerFrameState();
}

class _ConnectivityBannerFrameState extends State<ConnectivityBannerFrame> {
  /// The bar holds the status-bar inset (from opening until fully closed).
  late bool _open = _visible;

  /// What the bar shows: the last visible mode, kept while it closes.
  late ConnectivityBannerMode _shown = widget.mode;

  bool get _visible => widget.mode != ConnectivityBannerMode.hidden;

  @override
  void didUpdateWidget(ConnectivityBannerFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_visible) return;
    _open = true;
    _shown = widget.mode;
  }

  void _onClosed() {
    if (mounted && !_visible) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).top;
    return Column(
      children: [
        ConnectivityBar(
          mode: _shown,
          visible: _visible,
          topInset: _open ? inset : 0,
          nudges: widget.nudges,
          onClosed: _onClosed,
        ),
        Expanded(
          // Every route's modal barrier blocks the semantics of what was
          // painted before it in the same container — the bar included. Its
          // own container keeps that blocking inside the navigator, so screen
          // readers still reach the banner (dialogs still hide the page).
          child: Semantics(
            container: true,
            child: MediaQuery.removePadding(
              context: context,
              removeTop: _open,
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}
