import 'package:flutter/widgets.dart';

import 'size_reporter_render.dart';

/// Tells [onSize] how big its child is, after every layout that changed it
/// — for a screen that must leave room for a panel it does not size itself
/// (a map's padding under a bottom card). Called after the frame, so the
/// listener may set state.
class SizeReporter extends SingleChildRenderObjectWidget {
  const SizeReporter({super.key, required this.onSize, super.child});

  final ValueChanged<Size> onSize;

  @override
  RenderSizeReporter createRenderObject(BuildContext context) =>
      RenderSizeReporter(onSize);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSizeReporter renderObject,
  ) => renderObject.onSize = onSize;
}
