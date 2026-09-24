import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_shadows.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';
import '../../domain/entities/home_announcement_item.dart';
import 'home_announcement_dots.dart';
import 'home_announcement_line.dart';

/// The announcement strip of the home feed ("Free delivery over 5.000 KWD"):
/// a dark card under the header that rolls through the store's notices — the
/// line on screen leaves upwards while the next one rises into its place, and
/// the dots on the trailing edge say how many there are.
///
/// With reduced motion, a single notice, or while the tab is hidden it stays
/// still.
class HomeAnnouncementTicker extends StatefulWidget {
  const HomeAnnouncementTicker({super.key, required this.items});

  final List<HomeAnnouncementItem> items;

  @override
  State<HomeAnnouncementTicker> createState() => _HomeAnnouncementTickerState();
}

class _HomeAnnouncementTickerState extends State<HomeAnnouncementTicker> {
  Timer? _rotation;
  int _index = 0;

  static const double _height = AppSize.s44;

  /// How far a line travels, as a share of its own height.
  static const double _travel = 0.7;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rearm();
  }

  @override
  void didUpdateWidget(covariant HomeAnnouncementTicker old) {
    super.didUpdateWidget(old);
    if (_index >= widget.items.length) _index = 0;
    if (old.items.length != widget.items.length) _rearm();
  }

  @override
  void dispose() {
    _rotation?.cancel();
    super.dispose();
  }

  void _rearm() {
    _rotation?.cancel();
    if (widget.items.length < 2 || MotionGuard.reduced(context)) return;
    _rotation = Timer.periodic(AppMotion.carousel, (_) => _advance());
  }

  void _advance() {
    if (!mounted || !TickerMode.valuesOf(context).enabled) return;
    setState(() => _index = (_index + 1) % widget.items.length);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final item = widget.items[_index];
    final key = ValueKey<String>(item.id);
    return Padding(
      // Clears the seam the header ends on.
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.pageMargin,
        AppSpacing.s10,
        AppSpacing.pageMargin,
        0,
      ),
      child: Container(
        height: _height,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s10,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.low,
        ),
        child: Row(
          children: [
            Expanded(
              // The lines travel past the edges of the card, so they are cut
              // at them and never paint over its corners.
              child: ClipRect(
                child: AnimatedSwitcher(
                  duration: MotionGuard.duration(context, AppMotion.page),
                  switchInCurve: AppMotion.signature,
                  switchOutCurve: AppMotion.signature,
                  // The line arriving rises from below; the one being replaced
                  // is the other child here, and its animation runs backwards,
                  // so the same tween carries it up and out.
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(0, child.key == key ? _travel : -_travel),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: HomeAnnouncementLine(key: key, item: item),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s10),
            HomeAnnouncementDots(count: widget.items.length, index: _index),
          ],
        ),
      ),
    );
  }
}
