import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_args/pdp_image_viewer_args.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/widgets/jameia_image.dart';
import '../../../../core/widgets/paging_dots.dart';
import '../cubit/product_detail_cubit.dart';

/// The product photos as a swipeable pager with an "Image 1/3" pill. A tap
/// opens the full-screen zoom viewer and comes back to the page it was left on.
class PdpGallery extends StatefulWidget {
  const PdpGallery({super.key, required this.images});

  final List<String> images;

  @override
  State<PdpGallery> createState() => _PdpGalleryState();
}

class _PdpGalleryState extends State<PdpGallery> {
  late final PageController _controller = PageController(
    initialPage: context.read<ProductDetailCubit>().state.imageIndex,
  );
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openViewer(int index) async {
    final cubit = context.read<ProductDetailCubit>();
    final returned = await context.push<int>(
      Routes.pdpImageViewer,
      extra: PdpImageViewerArgs(images: widget.images, initialIndex: index),
    );
    if (returned == null || !mounted) return;
    cubit.setImageIndex(returned);
    if (_controller.hasClients) _controller.jumpToPage(returned);
  }

  // The dots read the controller, so the page itself never rebuilds here.
  void _onPageChanged(int page) =>
      context.read<ProductDetailCubit>().setImageIndex(page);

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    return ColoredBox(
      color: AppColors.white,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: images.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () => _openViewer(index),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: JameiaImage(url: images[index], fit: BoxFit.contain),
              ),
            ),
          ),
          PositionedDirectional(
            bottom: AppSpacing.s16,
            start: 0,
            end: 0,
            child: Center(
              child: PagingDots(controller: _controller, count: images.length),
            ),
          ),
        ],
      ),
    );
  }
}
