import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/motion.dart';
import 'pdp_thumbnail.dart';

/// The white strip of photo thumbnails along the bottom of the full-screen
/// viewer, under a hairline, 16 dp of air around them. The photo shown
/// ([current]) is outlined, and the strip keeps it in view by moving its own
/// scroll position only; a tap on a thumbnail reports [onSelect].
class PdpThumbnailStrip extends StatefulWidget {
  const PdpThumbnailStrip({
    super.key,
    required this.images,
    required this.current,
    required this.onSelect,
  });

  final List<String> images;
  final int current;
  final ValueChanged<int> onSelect;

  static const double _gap = AppSpacing.s16;
  static const double _side = AppSpacing.s16;
  static const double _height = PdpThumbnail.size + _side * 2;

  @override
  State<PdpThumbnailStrip> createState() => _PdpThumbnailStripState();
}

class _PdpThumbnailStripState extends State<PdpThumbnailStrip> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reveal(widget.current, animate: false);
    });
  }

  @override
  void didUpdateWidget(PdpThumbnailStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current) _reveal(widget.current);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Scrolls the strip just enough for thumbnail [index] to show whole.
  void _reveal(int index, {bool animate = true}) {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    const pitch = PdpThumbnail.size + PdpThumbnailStrip._gap;
    final start = index * pitch;
    final end = start + PdpThumbnail.size + PdpThumbnailStrip._side * 2;
    final double to;
    if (start < position.pixels) {
      to = start;
    } else if (end > position.pixels + position.viewportDimension) {
      to = end - position.viewportDimension;
    } else {
      return;
    }
    final target = to.clamp(position.minScrollExtent, position.maxScrollExtent);
    final duration = MotionGuard.duration(context, AppMotion.page);
    if (!animate || duration == Duration.zero) {
      position.jumpTo(target);
      return;
    }
    position.animateTo(target, duration: duration, curve: AppMotion.signature);
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: PdpThumbnailStrip._height,
          child: ListView.separated(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.all(PdpThumbnailStrip._side),
            itemCount: images.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: PdpThumbnailStrip._gap),
            itemBuilder: (context, index) => PdpThumbnail(
              key: ValueKey<int>(index),
              url: images[index],
              label: 'product.image_of'.tr(
                namedArgs: {
                  'index': '${index + 1}',
                  'total': '${images.length}',
                },
              ),
              selected: index == widget.current,
              onTap: () => widget.onSelect(index),
            ),
          ),
        ),
      ),
    );
  }
}
