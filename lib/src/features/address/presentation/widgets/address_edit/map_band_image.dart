import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../core/motion/motion.dart';
import 'map_strip.dart';

/// The band of a map [snapshot] that fills this box — the snapshot's
/// middle stays in the box's middle — fading in over what is under it once
/// cut. Only the band is kept ([cutMapStrip], cut off the UI thread at the
/// box's size in physical pixels); a new snapshot or size cuts a new one.
class MapBandImage extends StatefulWidget {
  const MapBandImage({super.key, required this.snapshot});

  /// The map's PNG bytes; `null`: nothing to show yet.
  final ValueListenable<Uint8List?> snapshot;

  @override
  State<MapBandImage> createState() => _MapBandImageState();
}

class _MapBandImageState extends State<MapBandImage> {
  ui.Image? _band;

  /// What the band was (or is being) cut from, and at which size.
  Uint8List? _cutFrom;
  Size? _cutSize;
  int _cuts = 0;

  @override
  void initState() {
    super.initState();
    widget.snapshot.addListener(_snapshotChanged);
  }

  @override
  void didUpdateWidget(MapBandImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot != widget.snapshot) {
      oldWidget.snapshot.removeListener(_snapshotChanged);
      widget.snapshot.addListener(_snapshotChanged);
    }
  }

  @override
  void dispose() {
    widget.snapshot.removeListener(_snapshotChanged);
    _band?.dispose();
    super.dispose();
  }

  void _snapshotChanged() => setState(() {});

  /// Cuts the band at [size] (physical pixels) unless it is already there
  /// or on its way.
  void _cut(Size size) {
    final png = widget.snapshot.value;
    if (!mounted || png == null) return;
    if (identical(png, _cutFrom) && size == _cutSize) return;
    _cutFrom = png;
    _cutSize = size;
    final ticket = ++_cuts;
    unawaited(
      cutMapStrip(
        png,
        width: size.width.round(),
        height: size.height.round(),
      ).then((band) {
        if (!mounted || ticket != _cuts) {
          band.dispose();
          return;
        }
        final old = _band;
        setState(() => _band = band);
        // The old band leaves the screen with this frame.
        if (old != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final band = _band;
    return LayoutBuilder(
      builder: (context, box) {
        if (widget.snapshot.value != null) {
          final ratio = MediaQuery.devicePixelRatioOf(context);
          final size = Size(box.maxWidth * ratio, box.maxHeight * ratio);
          // After this frame: no work inside a build.
          WidgetsBinding.instance.addPostFrameCallback((_) => _cut(size));
        }
        return AnimatedOpacity(
          opacity: band == null ? 0 : 1,
          duration: MotionGuard.duration(context, AppMotion.medium),
          curve: AppMotion.signature,
          child: RawImage(image: band, fit: BoxFit.cover),
        );
      },
    );
  }
}
