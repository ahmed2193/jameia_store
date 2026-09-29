import 'package:flutter/widgets.dart';

import 'motion.dart';

/// THE list entrance (docs/motion §9.4 #5, decisions §17): the
/// [EntranceCascadeItem]s that mount in the frame the list's first data
/// arrives (the first screenful + cache extent) fade in while rising
/// [AppMotion.entranceRise], [AppMotion.staggerStep] apart, the first
/// [maxItems] only. It opens ONCE per scope life:
///
/// * anything built later — scrolling on, scrolling back to a row the lazy
///   list dropped, the next page, a refresh, a new filter or sort — appears
///   as is (the scope is spent, so a re-mounted row never replays);
/// * [ready] `false` holds it closed until the first frame it turns `true`
///   (a scope that stays mounted across loading → loaded plays on the first
///   arrival only);
/// * it never opens while its own route is still entering (the route is the
///   entrance — also the case for data read from the device copy at mount),
///   with a screen reader on, or when [play] is `false`.
///
/// Wrap the list once, above the loading ↔ loaded switch when the list can
/// load again (filters), or where its first data arrives.
class EntranceCascade extends StatefulWidget {
  const EntranceCascade({
    super.key,
    required this.child,
    this.ready = true,
    this.play = true,
    this.maxItems = AppMotion.staggerMaxItems,
  });

  final Widget child;

  /// The list's first data has arrived: the scope opens on the first frame
  /// this is `true`, and never again.
  final bool ready;

  /// `false`: the items mount at rest (a transcript reopened from history,
  /// a list the customer has already seen).
  final bool play;

  /// Items at this index or later never animate.
  final int maxItems;

  @override
  State<EntranceCascade> createState() => EntranceCascadeState();
}

/// Public so the items can find it (read once, when an item mounts).
class EntranceCascadeState extends State<EntranceCascade> {
  bool _open = false;
  bool _spent = false;

  /// Whether an item mounting now belongs to the cascading frame.
  bool get isOpen => _open;
  int get maxItems => widget.maxItems;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _openOnce();
  }

  @override
  void didUpdateWidget(EntranceCascade oldWidget) {
    super.didUpdateWidget(oldWidget);
    _openOnce();
  }

  /// Opens for the frame the list first arrives in; spent after that.
  void _openOnce() {
    if (_spent || !widget.ready) return;
    _spent = true;
    if (!widget.play || !_mayPlay()) return;
    _open = true;
    // Lazy lists build their first rows during this frame's layout.
    WidgetsBinding.instance.addPostFrameCallback((_) => _open = false);
  }

  bool _mayPlay() {
    if (MediaQuery.accessibleNavigationOf(context)) return false;
    final route = ModalRoute.of(context);
    if (route == null) return true;
    // A push lays its first frame out offstage (for heroes), with the
    // animation standing in as complete: that frame is the entrance too.
    final animation = route.animation;
    return !route.offstage && (animation == null || animation.isCompleted);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
