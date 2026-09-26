import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/responsive/app_size.dart';
import 'pdp_gallery.dart';
import 'pdp_sheet.dart';
import 'pdp_top_bar.dart';

/// Scroll frame of the product page: the full-bleed grey gallery from the
/// very top (behind the status bar, whose icons stay dark) under the round
/// back / cart buttons, then a white sheet whose rounded top reaches into
/// the gallery's grey and holds the flat [sections] from its very edge. The white bar with
/// the product's [title] fades in as the gallery scrolls away, driven by the
/// page list's own scroll notifications (never a rail's).
///
/// Shared by the loaded page and by the preview painted while the product
/// loads, so nothing jumps when the detail arrives.
class PdpScaffoldView extends StatefulWidget {
  const PdpScaffoldView({
    super.key,
    required this.title,
    required this.images,
    required this.sections,
    this.galleryKey,
  });

  final String title;
  final List<String> images;

  /// Laid out at once, top to bottom, so each block's entrance plays once.
  final List<Widget> sections;

  /// On the gallery: where the buy bar's fly-to-cart takes off.
  final GlobalKey? galleryKey;

  /// The gallery (under the status bar) is this share of the width tall.
  static const double _galleryShare = 0.8;
  static const double _minGallery = AppSize.s280;
  static const double _maxGallery = AppSize.s480;

  /// Room around a photo: the round buttons at the sides and the dots pill
  /// under it. The pager's box ends where the sheet's rounded top begins.
  static const double _photoSide = AppSpacing.s48;
  static const double _photoTop = AppSpacing.s16;
  static const double _photoBottom = AppSpacing.s32;
  static const double _dotsInset = AppSpacing.s12;

  /// How much of the page's top the solid bar hides, status bar included.
  /// The bar floats over the list (it is not a pinned sliver), so a block
  /// scrolled to the viewport's top must land this far below it.
  static double coveredTop(BuildContext context) =>
      MediaQuery.paddingOf(context).top + PdpTopBar.barHeight;

  /// The gallery's full grey height, status bar included, down to the
  /// bottom of the sheet's rounded corners.
  static double galleryHeight(BuildContext context) =>
      MediaQuery.paddingOf(context).top +
      (MediaQuery.sizeOf(context).width * _galleryShare).clamp(
        _minGallery,
        _maxGallery,
      );

  @override
  State<PdpScaffoldView> createState() => _PdpScaffoldViewState();
}

class _PdpScaffoldViewState extends State<PdpScaffoldView> {
  final ValueNotifier<double> _progress = ValueNotifier<double>(0);

  /// Scroll offset at which the sheet's top edge passes under the bar.
  double _solidAt = 0;
  double _pixels = 0;

  /// How far the page can scroll at all.
  double _maxScroll = 0;

  @override
  void dispose() {
    _progress.dispose();
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
        : ((_pixels - (solidAt - fade)) / fade).clamp(0.0, 1.0);
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
    _pixels = metrics.pixels;
    _maxScroll = metrics.hasContentDimensions ? metrics.maxScrollExtent : 0;
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
    _solidAt = pagerHeight - topInset - PdpTopBar.barHeight;
    final images = widget.images;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: NotificationListener<Notification>(
        onNotification: _follow,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: pagerHeight,
                    child: KeyedSubtree(
                      key: widget.galleryKey,
                      child: PdpGallery(
                        key: ValueKey<String>(
                          images.isEmpty ? '' : images.first,
                        ),
                        images: images,
                        photoPadding: EdgeInsetsDirectional.fromSTEB(
                          PdpScaffoldView._photoSide,
                          topInset + PdpScaffoldView._photoTop,
                          PdpScaffoldView._photoSide,
                          PdpScaffoldView._photoBottom,
                        ),
                        dotsInset: PdpScaffoldView._dotsInset,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: PdpSheet(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: widget.sections,
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
