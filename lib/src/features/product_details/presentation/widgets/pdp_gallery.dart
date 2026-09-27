import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_args/pdp_image_viewer_args.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../cubit/product_detail_cubit.dart';
import 'pdp_dots_pill.dart';
import 'pdp_photo.dart';

/// The product photos, full bleed on light grey: a swipeable pager of whole
/// (contained) photos edge to edge, from its very top, and the dots pill
/// [dotsInset] above the bottom edge when there are several. A tap flies
/// the photo into the full-screen viewer ([PdpPhoto]) and back to the page
/// it was left on.
class PdpGallery extends StatefulWidget {
  const PdpGallery({
    super.key,
    required this.images,
    required this.productSlug,
    required this.dotsInset,
  });

  final List<String> images;

  /// The product the photos belong to (scopes their flight to the viewer).
  final String productSlug;
  final double dotsInset;

  @override
  State<PdpGallery> createState() => _PdpGalleryState();
}

class _PdpGalleryState extends State<PdpGallery> {
  // Created up front, never lazily: a photo-less gallery never reads it, and
  // a first read in dispose() would look the cubit up on a dead context.
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      initialPage: context.read<ProductDetailCubit>().state.imageIndex,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openViewer(int index) async {
    final cubit = context.read<ProductDetailCubit>();
    final returned = await context.push<int>(
      Routes.pdpImageViewer,
      extra: PdpImageViewerArgs(
        images: widget.images,
        initialIndex: index,
        productSlug: widget.productSlug,
      ),
    );
    if (returned == null || !mounted) return;
    cubit.setImageIndex(returned);
    if (_controller.hasClients) _controller.jumpToPage(returned);
  }

  // The dots paint from the controller, so the page never rebuilds here.
  void _onPageChanged(int page) =>
      context.read<ProductDetailCubit>().setImageIndex(page);

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    return ColoredBox(
      color: AppColors.smallBackground,
      child: images.isEmpty
          ? const SizedBox.expand()
          : Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: images.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) => Semantics(
                    button: true,
                    image: true,
                    label: 'product.image_of'.tr(
                      namedArgs: {
                        'index': '${index + 1}',
                        'total': '${images.length}',
                      },
                    ),
                    child: GestureDetector(
                      onTap: () => _openViewer(index),
                      behavior: HitTestBehavior.opaque,
                      child: PdpPhoto(
                        url: images[index],
                        index: index,
                        productSlug: widget.productSlug,
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  bottom: widget.dotsInset,
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
    );
  }
}
