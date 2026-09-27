import 'package:flutter/widgets.dart';

/// A product photo in flight between the page's gallery and the viewer
/// (`PdpPhoto`): the photo it leaves, laid out at the size it had there and
/// scaled to the flight's box — so the flight reuses the decode already on
/// screen instead of decoding again at every size it passes through.
class PdpPhotoFlight extends StatelessWidget {
  const PdpPhotoFlight({super.key, required this.side, this.photo});

  /// The photo leaving the `Hero` of [heroContext], at its size there.
  factory PdpPhotoFlight.leaving(BuildContext heroContext) {
    final widget = heroContext.widget;
    final box = heroContext.findRenderObject();
    return PdpPhotoFlight(
      side: box is RenderBox && box.hasSize ? box.size.shortestSide : 0,
      photo: widget is Hero ? widget.child : null,
    );
  }

  /// The square the photo had where it took off.
  final double side;
  final Widget? photo;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: SizedBox.square(dimension: side, child: photo),
    );
  }
}
