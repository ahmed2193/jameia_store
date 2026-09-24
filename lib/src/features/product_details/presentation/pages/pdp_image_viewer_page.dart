import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/widgets/jameia_image.dart';

/// Full-screen, pinch-to-zoom viewer of a product's photos. Pops with the page
/// it was left on, so the product page's gallery follows.
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

  @override
  Widget build(BuildContext context) {
    return PopScope<int>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.pop(_page);
      },
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'product.image_of'.tr(
              namedArgs: {
                'index': '${_page + 1}',
                'total': '${widget.images.length}',
              },
            ),
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.white),
          ),
        ),
        body: PageView.builder(
          controller: _controller,
          itemCount: widget.images.length,
          onPageChanged: (page) => setState(() => _page = page),
          itemBuilder: (context, index) => InteractiveViewer(
            maxScale: _maxZoom,
            child: JameiaImage(url: widget.images[index], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
