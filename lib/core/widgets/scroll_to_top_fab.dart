import 'package:flutter/material.dart';

import '../design/keeta_icons.dart';
import '../motion/motion.dart';
import '../theme/app_colors.dart';

/// A "scroll to top" FAB that manages its own visibility off [controller]: it
/// scales in once the list is scrolled past [threshold] and animates back to the
/// top on tap.
///
/// Extracted from the identical per-screen `_ToTopFab` widget + scroll-listener
/// plumbing (`_showToTop` / `_onScroll` / `_scrollToTop`) that was duplicated
/// across the discovery screens. Pass the same [ScrollController] the list uses.
class ScrollToTopFab extends StatefulWidget {
  const ScrollToTopFab({
    super.key,
    required this.controller,
    this.threshold = 320,
  });

  final ScrollController controller;

  /// Scroll offset (px) past which the FAB appears.
  final double threshold;

  @override
  State<ScrollToTopFab> createState() => _ScrollToTopFabState();
}

class _ScrollToTopFabState extends State<ScrollToTopFab> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!widget.controller.hasClients) return;
    final show = widget.controller.offset > widget.threshold;
    if (show != _visible) setState(() => _visible = show);
  }

  void _scrollToTop() {
    widget.controller.animateTo(
      0,
      duration: MotionGuard.duration(context, AppMotion.page),
      curve: MotionGuard.curve(context, AppMotion.signature),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _visible ? 1 : 0,
      duration: MotionGuard.duration(context, AppMotion.fast),
      curve: AppMotion.signature,
      child: FloatingActionButton.small(
        onPressed: _scrollToTop,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primaryText,
        elevation: 3,
        shape: const CircleBorder(),
        child: const Icon(KeetaIcons.arrowUp, size: 20),
      ),
    );
  }
}
