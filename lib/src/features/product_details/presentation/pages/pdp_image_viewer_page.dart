import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/widgets/jameia_image.dart';
import '../../../../core/widgets/round_outlined_button.dart';
import '../widgets/pdp_dots_pill.dart';
import '../widgets/pdp_thumbnail_strip.dart';

/// Full-screen, pinch-to-zoom viewer of a product's photos on light grey:
/// a round close button at the reading start, the photos, the dots pill and
/// a strip of thumbnails that jumps to a photo. Pops with the page it was
/// left on (close button or system back), so the product page's gallery
/// follows. One photo: no dots, no strip.
class PdpImageViewerPage extends StatefulWidget {
  const PdpImageViewerPage({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  final List<String> images;
  final int initialIndex;

  @override
  State<PdpImageViewerPage> createState() => _PdpImageViewerPageState();
}

class _PdpImageViewerPageState extends State<PdpImageViewerPage> {
  static const double _maxZoom = 4;

  late final PageController _controller;
  late int _page;

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
    final duration = MotionGuard.duration(context, AppMotion.page);
    if (duration == Duration.zero) {
      _controller.jumpToPage(index);
      return;
    }
    _controller.animateToPage(
      index,
      duration: duration,
      curve: AppMotion.signature,
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final paged = images.length > 1;
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
                      itemCount: images.length,
                      onPageChanged: (page) => setState(() => _page = page),
                      itemBuilder: (context, index) => Semantics(
                        image: true,
                        label: 'product.image_of'.tr(
                          namedArgs: {
                            'index': '${index + 1}',
                            'total': '${images.length}',
                          },
                        ),
                        child: InteractiveViewer(
                          maxScale: _maxZoom,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpacing.s24,
                              vertical: AppSpacing.s48,
                            ),
                            child: JameiaImage(
                              url: images[index],
                              fit: BoxFit.contain,
                            ),
                          ),
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
                            icon: Icons.close_rounded,
                            label: 'product.close'.tr(),
                            onTap: _close,
                          ),
                        ),
                      ),
                    ),
                    if (paged)
                      PositionedDirectional(
                        bottom: AppSpacing.s24,
                        start: 0,
                        end: 0,
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
              if (paged)
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
