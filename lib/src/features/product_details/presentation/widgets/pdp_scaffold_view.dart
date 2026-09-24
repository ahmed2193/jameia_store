import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/responsive/app_size.dart';
import 'pdp_back_button.dart';
import 'pdp_cart_action.dart';
import 'pdp_gallery.dart';

/// Scroll frame of the product page: the photo sheet under floating disc
/// chrome, collapsing into a plain bar, then [sections] on the page colour.
/// Shared by the loaded page and by the preview painted while the product
/// loads, so nothing jumps when the detail arrives.
class PdpScaffoldView extends StatelessWidget {
  const PdpScaffoldView({
    super.key,
    required this.images,
    required this.sections,
  });

  final List<String> images;
  final List<Widget> sections;

  static const double _minGallery = AppSize.s320;
  static const double _maxGallery = AppSize.s439;

  /// The photo sheet ends in a curve, the way every card on the storefront
  /// does, so the content reads as rising out of it.
  static const double _sheetRadius = AppSize.r18;

  @override
  Widget build(BuildContext context) {
    final galleryHeight = MediaQuery.sizeOf(context).width
        .clamp(_minGallery, _maxGallery);
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.mediumBackground,
          surfaceTintColor: AppColors.mediumBackground,
          foregroundColor: AppColors.primaryText,
          elevation: 0,
          expandedHeight: galleryHeight,
          leading: const Padding(
            padding: EdgeInsetsDirectional.only(start: AppSpacing.s8),
            child: Center(child: PdpBackButton()),
          ),
          actions: const [PdpCartAction()],
          flexibleSpace: FlexibleSpaceBar(
            background: ClipRRect(
              borderRadius: const BorderRadiusDirectional.only(
                bottomStart: Radius.circular(_sheetRadius),
                bottomEnd: Radius.circular(_sheetRadius),
              ),
              child: ColoredBox(
                color: AppColors.white,
                child: images.isEmpty
                    ? const SizedBox.expand()
                    : SafeArea(
                        bottom: false,
                        child: PdpGallery(
                          key: ValueKey<String>(images.first),
                          images: images,
                        ),
                      ),
              ),
            ),
          ),
        ),
        SliverList.list(children: sections),
      ],
    );
  }
}
