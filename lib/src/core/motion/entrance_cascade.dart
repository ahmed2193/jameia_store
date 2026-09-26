import 'package:flutter/widgets.dart';

/// Opens for the FIRST FRAME only: the [EntranceCascadeItem]s that mount in
/// that frame (the first screenful + cache extent) cascade in; anything built
/// later — scrolling back, the next page, a refresh — appears as is. Wrap the
/// list once, where its first data arrives.
class EntranceCascade extends StatefulWidget {
  const EntranceCascade({
    super.key,
    required this.child,
    this.maxItems = defaultMaxItems,
  });

  static const int defaultMaxItems = 6;

  final Widget child;

  /// Items at this index or later never animate.
  final int maxItems;

  @override
  State<EntranceCascade> createState() => EntranceCascadeState();
}

/// Public so the items can find it (read once, when an item mounts).
class EntranceCascadeState extends State<EntranceCascade> {
  bool _open = true;

  /// Whether an item mounting now still belongs to the first frame.
  bool get isOpen => _open;
  int get maxItems => widget.maxItems;

  @override
  void initState() {
    super.initState();
    // Lazy lists build their first rows during this frame's layout.
    WidgetsBinding.instance.addPostFrameCallback((_) => _open = false);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
