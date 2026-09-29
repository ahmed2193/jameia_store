import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/widgets/round_outlined_button.dart';
import '../widgets/pdp_dots_pill.dart';
import '../widgets/pdp_thumbnail_strip.dart';
import '../widgets/pdp_viewer_dismiss_drag.dart';
import '../widgets/pdp_zoomable_photo.dart';

/// Full-screen viewer of a product's photos on light grey, Hero
/// style: a round close button at the reading start, the photos (pinch or
/// double-tap to zoom; the pager holds still while one is zoomed), the dots
/// pill and a strip of thumbnails that brings a photo up — its lone
/// thumbnail too when there is one photo. The photo flies in from the
/// product page's gallery and back to the page it was left on (close button
/// or system back), so the gallery follows. A drag down on a photo at rest
/// pulls the viewer away with the finger and closes it the same way
/// ([PdpViewerDismissDrag]).
class PdpImageViewerPage extends StatefulWidget {
  const PdpImageViewerPage({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.productSlug,
  });

  final List<String> images;
  final int initialIndex;

  /// The product the photos belong to (scopes their flight).
  final String productSlug;

  @override
  State<PdpImageViewerPage> createState() => _PdpImageViewerPageState();
}

class _PdpImageViewerPageState extends State<PdpImageViewerPage> {
  late final PageController _controller;
  late int _page;

  /// Drag down on a photo at rest to close the viewer.
  late final PdpViewerDismissDrag _dismiss = PdpViewerDismissDrag(
    onDismiss: _close,
  );

  /// The photo shown is zoomed in: the pager holds still.
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _page = widget.images.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.images.length - 1);
    _controller = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() => context.pop(_page);

  /// Brings photo [index] up from the strip; instant under reduced motion.
  void _show(int index) {
    if (index == _page || !_controller.hasClients) return;
    MotionGuard.pageTo(context, _controller, index);
  }

  void _onZoomChanged(bool zoomed) {
    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
  }

  /// A new photo comes up at rest.
  void _onPageChanged(int page) => setState(() {
    _page = page;
    _zoomed = false;
  });

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    return PopScope<int>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: AppColors.smallBackground,
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _controller,
                      physics: _zoomed
                          ? const NeverScrollableScrollPhysics()
                          : null,
                      itemCount: images.length,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, index) => Semantics(
                        image: true,
                        label: 'product.image_of'.tr(
                          namedArgs: {
                            'index': '${index + 1}',
                            'total': '${images.length}',
                          },
                        ),
                        child: PdpZoomablePhoto(
                          url: images[index],
                          index: index,
                          productSlug: widget.productSlug,
                          onZoomChanged: _onZoomChanged,
                          onPullDown: (dy) => _dismiss.update(context, dy),
                          onPullEnd: (velocity) =>
                              _dismiss.end(context, velocity),
                          onPullCancel: () => _dismiss.cancel(context),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: 0,
                      start: 0,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.s16),
                          child: RoundOutlinedButton(
                            icon: HeroIcons.close,
                            label: 'product.close'.tr(),
                            onTap: _close,
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      bottom: AppSpacing.s24,
                      start: 0,
                      end: 0,
                      // Nothing for one photo: it is not a pager.
                      child: Center(
                        child: PdpDotsPill(
                          controller: _controller,
                          count: images.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (images.isNotEmpty)
                PdpThumbnailStrip(
                  images: images,
                  current: _page,
                  onSelect: _show,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
