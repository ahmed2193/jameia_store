import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// The render box of `SizeReporter`: lays its child out as it is, and once
/// its size changes, reports it after the frame.
class RenderSizeReporter extends RenderProxyBox {
  RenderSizeReporter(this.onSize);

  ValueChanged<Size> onSize;
  Size? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final measured = size;
    if (measured == _reported) return;
    _reported = measured;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (attached) onSize(measured);
    });
  }
}
