import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import 'pdp_gallery.dart';
import 'pdp_gallery_depth.dart';
import 'pdp_sheet.dart';
import 'pdp_top_bar.dart';

/// Scroll frame of the product page: the full-bleed grey gallery with the
/// photos as big as the page's width allows, whole, from the very top of
/// the screen — they run under the see-through status bar, whose icons stay
/// dark over them — under the round back / cart buttons ([photoSide]), then
/// a white sheet whose rounded top reaches into the gallery's grey and holds
/// the flat [sections] from its very edge. As
/// the sheet rides up, the photos drift up behind it at a slower pace
/// ([PdpGalleryDepth]), and the white bar with the product's [title] fades
/// in as the gallery scrolls away ([solidAt]) — both driven by the page
/// list's own scroll notifications (never a rail's), without a rebuild. The
/// sheet is its own layer, so scrolling only moves it.
///
/// Shared by the loaded page and by the preview painted while the product
/// loads, so nothing jumps when the detail arrives.
class PdpScaffoldView extends StatefulWidget {
  const PdpScaffoldView({
    super.key,
    required this.productSlug,
    required this.title,
    required this.images,
    required this.sections,
    this.galleryKey,
  });

  /// The product shown (scopes the photos' flight to the viewer).
  final String productSlug;
  final String title;
  final List<String> images;

  /// Laid out at once, top to bottom, so each block's entrance plays once.
  final List<Widget> sections;

  /// On the gallery: where the buy bar's fly-to-cart takes off.
  final GlobalKey? galleryKey;

  /// The photos' square never takes more than this share of the screen's
  /// height, so the sheet still shows the product's name under it.
  static const double _maxPhotoShare = 0.5;
  static const double _dotsInset = AppSpacing.s12;

  /// Dark status bar icons straight over the photo: no scrim under them.
  static final SystemUiOverlayStyle _statusBar = SystemUiOverlayStyle.dark
      .copyWith(statusBarColor: AppColors.scrimTransparent);

  /// How much of the page's top the solid bar hides, status bar included.
  /// The bar floats over the list (it is not a pinned sliver), so a block
  /// scrolled to the viewport's top must land this far below it.
  static double coveredTop(BuildContext context) =>
      MediaQuery.paddingOf(context).top + PdpTopBar.barHeight;

  /// The side of the square the photos fill, whole (contained, never cut),
  /// from the screen's very top edge (under the status bar) down to the
  /// sheet's rounded top: the page's full width, capped at [_maxPhotoShare]
  /// of its height. The status bar, the round buttons and the dots pill
  /// float over it.
  static double photoSide(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return math.min(size.width, size.height * _maxPhotoShare);
  }

  /// The gallery's full grey height, from the screen's top edge down to the
  /// bottom of the sheet's rounded corners.
  static double galleryHeight(BuildContext context) =>
      photoSide(context) + PdpSheet.overlap;

  /// The scroll offset at which the sheet's top edge passes under the bar
  /// (status bar included), and the bar is solid (on a page long enough to
  /// get there).
  static double solidAt(BuildContext context) =>
      photoSide(context) - coveredTop(context);

  @override
  State<PdpScaffoldView> createState() => _PdpScaffoldViewState();
}

class _PdpScaffoldViewState extends State<PdpScaffoldView> {
  final ValueNotifier<double> _progress = ValueNotifier<double>(0);

  /// The page list's scroll offset while the gallery shows (from 0 to the
  /// pager's height: past it the sheet covers the photos), for their drift
  /// and the bar's fade.
  final ValueNotifier<double> _scroll = ValueNotifier<double>(0);

  double _solidAt = 0;
  double _pagerHeight = 0;

  /// How far the page can scroll at all.
  double _maxScroll = 0;

  @override
  void dispose() {
    _progress.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// The bar fades in over its own height, finishing as the gallery leaves
  /// — or at the end of a page too short to scroll the gallery away, so the
  /// name never stops half drawn.
  void _updateProgress() {
    final solidAt = _maxScroll > 0 && _maxScroll < _solidAt
        ? _maxScroll
        : _solidAt;
    final fade = solidAt < PdpTopBar.barHeight ? solidAt : PdpTopBar.barHeight;
    _progress.value = solidAt <= 0
        ? 0
        : ((_scroll.value - (solidAt - fade)) / fade).clamp(0.0, 1.0);
  }

  bool _follow(Notification notification) {
    final (metrics, depth) = switch (notification) {
      ScrollNotification(:final metrics) => (metrics, notification.depth),
      ScrollMetricsNotification(:final metrics) => (
        metrics,
        notification.depth,
      ),
      _ => (null, 0),
    };
    // Only the page's own list, not the gallery pager or a rail inside it.
    if (metrics == null || depth != 0 || metrics.axis != Axis.vertical) {
      return false;
    }
    _maxScroll = metrics.hasContentDimensions ? metrics.maxScrollExtent : 0;
    // Deeper down nothing follows it any more, so it stops notifying.
    _scroll.value = metrics.pixels.clamp(0.0, _pagerHeight);
    _updateProgress();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final galleryHeight = PdpScaffoldView.galleryHeight(context);
    // The pager's box stops where the sheet begins; the sheet carries the
    // grey on behind its corners.
    final pagerHeight = galleryHeight - PdpSheet.overlap;
    _pagerHeight = pagerHeight;
    _solidAt = PdpScaffoldView.solidAt(context);
    final images = widget.images;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: PdpScaffoldView._statusBar,
      child: NotificationListener<Notification>(
        onNotification: _follow,
        child: Stack(
          children: [
            // What a pull past the top uncovers (a bounce): the gallery's
            // own grey, never the page's white. The gallery keeps its own
            // grey as well, for a pull longer than the sheet's overlap.
            PositionedDirectional(
              top: 0,
              start: 0,
              end: 0,
              height: galleryHeight,
              child: const ColoredBox(color: AppColors.smallBackground),
            ),
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: pagerHeight,
                    child: PdpGalleryDepth(
                      scroll: _scroll,
                      child: KeyedSubtree(
                        key: widget.galleryKey,
                        child: PdpGallery(
                          key: ValueKey<String>(
                            images.isEmpty ? '' : images.first,
                          ),
                          images: images,
                          productSlug: widget.productSlug,
                          dotsInset: PdpScaffoldView._dotsInset,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: RepaintBoundary(
                    child: PdpSheet(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: widget.sections,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            PositionedDirectional(
              top: 0,
              start: 0,
              end: 0,
              child: PdpTopBar(
                progress: _progress,
                title: widget.title,
                topInset: topInset,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
