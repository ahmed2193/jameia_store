import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/motion.dart';
import 'pdp_photo.dart';
import 'pdp_scaffold_view.dart';

/// One photo of the full-screen viewer: pinch to zoom up to four times, or
/// double-tap to glide in on the tapped spot (and again to glide back out).
/// Reports [onZoomChanged] only when it leaves or comes back to its resting
/// scale, so the pager can hold still while a zoomed photo is panned.
/// Instant under reduced motion.
///
/// The photo is laid out at the product page's own photo size and scaled to
/// the viewer's, so the page, the flight between them and the viewer show
/// one download and one decode — the photo that lands is already there.
class PdpZoomablePhoto extends StatefulWidget {
  const PdpZoomablePhoto({
    super.key,
    required this.url,
    required this.index,
    required this.productSlug,
    required this.onZoomChanged,
  });

  final String url;

  /// Its place among the product's photos.
  final int index;

  /// The product the photo belongs to (scopes its flight).
  final String productSlug;
  final ValueChanged<bool> onZoomChanged;

  /// How far a double tap zooms in.
  static const double doubleTapScale = 2.5;

  @override
  State<PdpZoomablePhoto> createState() => _PdpZoomablePhotoState();
}

class _PdpZoomablePhotoState extends State<PdpZoomablePhoto>
    with SingleTickerProviderStateMixin {
  static const double _maxScale = 4;

  /// Past this scale the photo counts as zoomed in.
  static const double _zoomedPast = 1.01;

  final TransformationController _transform = TransformationController();

  /// Made on the first double tap: most photos are only swiped past.
  AnimationController? _glide;
  Animation<Matrix4>? _glideTo;
  Offset _doubleTapAt = Offset.zero;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_reportZoom);
  }

  @override
  void dispose() {
    _glide?.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _followGlide() {
    final to = _glideTo;
    if (to != null) _transform.value = to.value;
  }

  void _reportZoom() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > _zoomedPast;
    if (zoomed == _zoomed) return;
    _zoomed = zoomed;
    widget.onZoomChanged(zoomed);
  }

  /// In on the double-tapped spot, or back out.
  void _toggleZoom() {
    const scale = PdpZoomablePhoto.doubleTapScale;
    final spot = _doubleTapAt;
    // Scaling about the spot keeps it where the finger is.
    final target = _zoomed
        ? Matrix4.identity()
        : (Matrix4.diagonal3Values(scale, scale, 1)..setTranslationRaw(
            (1 - scale) * spot.dx,
            (1 - scale) * spot.dy,
            0,
          ));
    if (MotionGuard.reduced(context)) {
      _transform.value = target;
      return;
    }
    final glide = _glide ??= AnimationController(
      vsync: this,
      duration: AppMotion.page,
    )..addListener(_followGlide);
    _glideTo = Matrix4Tween(
      begin: _transform.value,
      end: target,
    ).chain(CurveTween(curve: AppMotion.signature)).animate(glide);
    glide.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapAt = details.localPosition,
      onDoubleTap: _toggleZoom,
      child: InteractiveViewer(
        transformationController: _transform,
        maxScale: _maxScale,
        // A pinch takes over from a glide.
        onInteractionStart: (_) => _glide?.stop(),
        // Edge to edge like the page's gallery; clear of the close button
        // and the dots above and below.
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: AppSpacing.s48,
          ),
          child: FittedBox(
            child: SizedBox.square(
              dimension: PdpScaffoldView.photoSide(context),
              child: PdpPhoto(
                url: widget.url,
                index: widget.index,
                productSlug: widget.productSlug,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
